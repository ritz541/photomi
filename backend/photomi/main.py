from fastapi import FastAPI, File, UploadFile, Depends, HTTPException
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from typing import List
import os
from datetime import datetime
from dotenv import load_dotenv

from database import engine, get_db
from models import Base, Photo
from storage import R2Storage
from image_processing import process_image

# Load environment variables from .env file
load_dotenv()

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Photomi - Personal Photo Manager")

# Initialize R2 storage
try:
    r2_storage = R2Storage()
except ValueError as e:
    print(f"Warning: {e}")
    r2_storage = None


@app.post("/upload/")
async def upload_photo(file: UploadFile = File(...), db: Session = Depends(get_db)):
    """
    Upload a photo, generate thumbnail, and store metadata in database
    """
    if not r2_storage:
        raise HTTPException(
            status_code=500, detail="R2 storage not configured")

    # Read the file
    contents = await file.read()

    # Process image to create thumbnail and extract EXIF data
    try:
        thumbnail_data, exif_date = process_image(contents)
    except Exception as e:
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
        raise HTTPException(
            status_code=500, detail="Failed to upload original image")

    # Upload thumbnail to R2
    thumbnail_buffer = BytesIO(thumbnail_data)
    if not r2_storage.upload_file(thumbnail_buffer, thumbnail_stored_name):
        raise HTTPException(
            status_code=500, detail="Failed to upload thumbnail")

    # Save metadata to database
    db_photo = Photo(
        filename=original_stored_name,
        thumbnail_filename=thumbnail_stored_name,
        created_at=created_at
    )

    db.add(db_photo)
    db.commit()
    db.refresh(db_photo)

    return {"filename": original_stored_name, "message": "Photo uploaded successfully"}


@app.get("/photos/", response_model=List[dict])
async def list_photos(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """
    Retrieve a list of photos sorted by date (newest first)
    """
    if not r2_storage:
        raise HTTPException(
            status_code=500, detail="R2 storage not configured")

    photos = db.query(Photo).order_by(
        Photo.created_at.desc()).offset(skip).limit(limit).all()

    result = []
    for photo in photos:
        # Generate presigned URLs for both original and thumbnail
        original_url = r2_storage.get_presigned_url(photo.filename)
        thumbnail_url = r2_storage.get_presigned_url(photo.thumbnail_filename)

        result.append({
            "id": photo.id,
            "filename": photo.filename,
            "thumbnail_url": thumbnail_url,
            "original_url": original_url,
            "created_at": photo.created_at.isoformat()
        })

    return result


@app.get("/")
async def root():
    return {"message": "Photomi API is running!"}
