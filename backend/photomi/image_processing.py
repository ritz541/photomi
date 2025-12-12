from PIL import Image, ExifTags
from io import BytesIO
import os
from datetime import datetime
from typing import Tuple, Optional


def extract_exif_date(image: Image.Image) -> Optional[datetime]:
    """
    Extract the date taken from EXIF data if available

    Args:
        image: PIL Image object

    Returns:
        datetime: Date taken from EXIF or None if not available
    """
    try:
        exif = image._getexif()
        if exif is not None:
            for tag, value in exif.items():
                tag_name = ExifTags.TAGS.get(tag, tag)
                if tag_name == "DateTimeOriginal" or tag_name == "DateTime":
                    return datetime.strptime(value, "%Y:%m:%d %H:%M:%S")
    except Exception as e:
        print(f"Error extracting EXIF data: {e}")

    return None


def create_thumbnail(image_data: bytes, max_size: Tuple[int, int] = (300, 300)) -> bytes:
    """
    Create a thumbnail from image data

    Args:
        image_data: Raw image data
        max_size: Maximum size for thumbnail (width, height)

    Returns:
        bytes: Thumbnail image data
    """
    try:
        # Open the image
        image = Image.open(BytesIO(image_data))

        # Create thumbnail
        image.thumbnail(max_size, Image.Resampling.LANCZOS)

        # Save thumbnail to bytes
        thumbnail_buffer = BytesIO()
        image.save(thumbnail_buffer, format=image.format)
        thumbnail_buffer.seek(0)

        return thumbnail_buffer.getvalue()
    except Exception as e:
        print(f"Error creating thumbnail: {e}")
        raise


def process_image(image_data: bytes) -> Tuple[bytes, Optional[datetime]]:
    """
    Process an image to create thumbnail and extract EXIF date

    Args:
        image_data: Raw image data

    Returns:
        Tuple[bytes, Optional[datetime]]: Thumbnail data and EXIF date (if available)
    """
    try:
        # Open the image
        image = Image.open(BytesIO(image_data))

        # Extract EXIF date
        exif_date = extract_exif_date(image)

        # Create thumbnail
        thumbnail_data = create_thumbnail(image_data)

        return thumbnail_data, exif_date
    except Exception as e:
        print(f"Error processing image: {e}")
        raise
