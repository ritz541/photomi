# Photomi Backend

FastAPI backend for the Photomi personal photo manager.

## Features

- RESTful API for photo management
- Cloudflare R2 integration for image storage
- SQLite database for metadata storage
- Automatic thumbnail generation
- EXIF data extraction

## Prerequisites

- Python 3.8+

## Setup

1. Create a virtual environment:
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Configure environment variables:
   - Copy `.env.example` to `.env`
   - Update the values in `.env` with your Cloudflare R2 credentials

4. Run the server:
   ```bash
   uvicorn main:app --host $HOST --port $PORT --reload
   ```

   Or if you want to specify directly:
   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8000 --reload
   ```

The API will be available at `http://0.0.0.0:8000` (accessible from other devices on the network).

## API Endpoints

- `GET /` - Health check
- `POST /upload/` - Upload a photo
- `GET /photos/` - Get list of photos

## Project Structure

```
.
├── main.py          # FastAPI application
├── models.py        # Database models
├── database.py      # Database setup
├── storage.py       # Cloudflare R2 integration
├── image_processing.py # Image processing utilities
├── requirements.txt # Python dependencies
└── photomi.db       # SQLite database (created on first run)
```

## Dependencies

- FastAPI
- Uvicorn
- SQLAlchemy
- Pillow
- Boto3

## License

This project is licensed under the MIT License.