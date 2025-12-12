from fastapi import FastAPI, File, UploadFile, Depends, HTTPException
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from typing import List
import os
import logging
from datetime import datetime
from dotenv import load_dotenv

from database import engine, get_db
from models import Base, Photo
from storage import R2Storage
from image_processing import process_image

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment variables from .env file
load_dotenv()

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Photomi - Personal Photo Manager")

# Initialize R2 storage
try:
    r2_storage = R2Storage()
except ValueError as e:
    logger.warning(f"R2 storage initialization failed: {e}")
    r2_storage = None


@app.post("/upload/")
async def upload_photo(file: UploadFile = File(...), db: Session = Depends(get_db)):
    """
    Upload a photo, generate thumbnail, and store metadata in database
    """
    if not r2_storage:
        logger.error("R2 storage not configured")
        raise HTTPException(
            status_code=500, detail="R2 storage not configured")

    # Validate file type
    if not file.content_type or not file.content_type.startswith('image/'):
        logger.warning(f"Invalid file type uploaded: {file.content_type}")
        raise HTTPException(
            status_code=400, detail="Only image files are allowed")

    # Read the file
    try:
        contents = await file.read()
        logger.info(f"Reading file: {file.filename}")
    except Exception as e:
        logger.error(f"Error reading file: {e}")
        raise HTTPException(
            status_code=500, detail=f"Error reading file: {str(e)}")

    # Process image to create thumbnail and extract EXIF data
    try:
        thumbnail_data, exif_date = process_image(contents)
        logger.info(f"Processed image: {file.filename}")
    except Exception as e:
        logger.error(f"Error processing image: {str(e)}")
        raise HTTPException(
            status_code=400, detail=f"Error processing image: {str(e)}")

    # Use EXIF date if available, otherwise use current time
    created_at = exif_date if exif_date else datetime.utcnow()

    # Generate filenames
    original_filename = file.filename
    name, ext = os.path.splitext(original_filename)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    unique_name = f"{name}_{timestamp}"

    original_stored_name = f"{unique_name}{ext}"
    thumbnail_stored_name = f"{unique_name}_thumb{ext}"

    # Upload original image to R2
    from io import BytesIO
    original_buffer = BytesIO(contents)
    if not r2_storage.upload_file(original_buffer, original_stored_name):
        logger.error(
            f"Failed to upload original image: {original_stored_name}")
        raise HTTPException(
            status_code=500, detail="Failed to upload original image")

    # Upload thumbnail to R2
    thumbnail_buffer = BytesIO(thumbnail_data)
    if not r2_storage.upload_file(thumbnail_buffer, thumbnail_stored_name):
        logger.error(f"Failed to upload thumbnail: {thumbnail_stored_name}")
        raise HTTPException(
            status_code=500, detail="Failed to upload thumbnail")

    # Save metadata to database
    try:
        db_photo = Photo(
            filename=original_stored_name,
            thumbnail_filename=thumbnail_stored_name,
            created_at=created_at
        )

        db.add(db_photo)
        db.commit()
        db.refresh(db_photo)
        logger.info(
            f"Saved photo metadata to database: {original_stored_name}")
    except Exception as e:
        logger.error(f"Error saving photo metadata to database: {e}")
        db.rollback()
        raise HTTPException(
            status_code=500, detail=f"Error saving photo metadata: {str(e)}")

    return {"filename": original_stored_name, "message": "Photo uploaded successfully"}


@app.get("/photos/", response_model=List[dict])
async def list_photos(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """
    Retrieve a list of photos sorted by date (newest first)
    """
    if not r2_storage:
        logger.error("R2 storage not configured")
        raise HTTPException(
            status_code=500, detail="R2 storage not configured")

    try:
        photos = db.query(Photo).order_by(
            Photo.created_at.desc()).offset(skip).limit(limit).all()
        logger.info(f"Retrieved {len(photos)} photos from database")
    except Exception as e:
        logger.error(f"Error querying photos from database: {e}")
        raise HTTPException(
            status_code=500, detail=f"Error retrieving photos: {str(e)}")

    result = []
    for photo in photos:
        try:
            # Generate presigned URLs for both original and thumbnail
            original_url = r2_storage.get_presigned_url(photo.filename)
            thumbnail_url = r2_storage.get_presigned_url(
                photo.thumbnail_filename)

            result.append({
                "id": photo.id,
                "filename": photo.filename,
                "thumbnail_url": thumbnail_url,
                "original_url": original_url,
                "created_at": photo.created_at.isoformat()
            })
        except Exception as e:
            logger.error(
                f"Error generating URLs for photo {photo.filename}: {e}")
            # Continue with other photos even if one fails

    return result


@app.delete("/photos/{photo_id}")
async def delete_photo(photo_id: int, db: Session = Depends(get_db)):
    """
    Delete a photo
    """
    if not r2_storage:
        logger.error("R2 storage not configured")
        raise HTTPException(
            status_code=500, detail="R2 storage not configured")

    photo = db.query(Photo).filter(Photo.id == photo_id).first()
    if not photo:
        logger.warning(f"Photo not found with id: {photo_id}")
        raise HTTPException(status_code=404, detail="Photo not found")

    # Delete files from R2 storage
    try:
        r2_storage.s3_client.delete_object(
            Bucket=r2_storage.bucket_name, Key=photo.filename)
        r2_storage.s3_client.delete_object(
            Bucket=r2_storage.bucket_name, Key=photo.thumbnail_filename)
        logger.info(
            f"Deleted files from R2 storage for photo: {photo.filename}")
    except Exception as e:
        # Log the error but continue with database deletion
        logger.error(f"Error deleting files from R2: {e}")

    # Delete from database
    try:
        db.delete(photo)
        db.commit()
        logger.info(f"Deleted photo from database with id: {photo_id}")
    except Exception as e:
        logger.error(f"Error deleting photo from database: {e}")
        db.rollback()
        raise HTTPException(
            status_code=500, detail=f"Error deleting photo from database: {str(e)}")

    return {"message": "Photo deleted successfully"}


@app.get("/")
async def root():
    return {"message": "Photomi API is running!"}
