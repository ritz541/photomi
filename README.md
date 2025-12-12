# Photomi - Personal Google Photos Alternative

A simple personal photo management application built with FastAPI (Python) backend and Flutter frontend, using Cloudflare R2 for storage.

> **Note:** This repository contains both the frontend and backend code. For production use, it's recommended to split them into separate repositories.

## Features

- Upload photos from your device
- Automatic thumbnail generation
- EXIF data extraction (date taken)
- Grid view of thumbnails
- Full-resolution image viewing
- Cloud storage with Cloudflare R2

## Repository Structure

This monorepo contains two main components:

1. **Backend** (`/backend/photomi`): FastAPI application with SQLite database and Cloudflare R2 integration
2. **Frontend** (`/frontend/photomi`): Flutter mobile application

## Prerequisites

- Python 3.8+
- Flutter SDK
- Cloudflare R2 account with bucket and credentials

## Quick Start

### Backend Setup (FastAPI)

1. Navigate to the backend directory:
   ```bash
   cd backend/photomi
   ```

2. Create a virtual environment and activate it:
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Configure environment variables:
   - Copy `.env.example` to `.env` in the backend directory
   - Update the values in `.env` with your Cloudflare R2 credentials

5. Run the backend server:
   ```bash
   uvicorn main:app --host $HOST --port $PORT --reload
   ```

   Or if you want to specify directly:
   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8000 --reload
   ```

The backend will be available at `http://0.0.0.0:8000` (accessible from other devices on the network).

### Frontend Setup (Flutter)

1. Navigate to the frontend directory:
   ```bash
   cd frontend/photomi
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure environment variables:
   - Copy `.env.example` to `.env` in the frontend directory
   - Update the values in `.env` with your backend URL

4. Run the app:
   ```bash
   flutter run
   ```

## API Endpoints

- `GET /` - Health check
- `POST /upload/` - Upload a photo
- `GET /photos/` - Get list of photos

## Project Structure

```
.
├── backend/
│   └── photomi/
│       ├── main.py          # FastAPI application
│       ├── models.py        # Database models
│       ├── database.py      # Database setup
│       ├── storage.py       # Cloudflare R2 integration
│       ├── image_processing.py # Image processing utilities
│       ├── requirements.txt # Python dependencies
│       └── photomi.db       # SQLite database (created on first run)
└── frontend/
    └── photomi/
        ├── lib/
        │   └── main.dart    # Flutter application
        └── pubspec.yaml     # Flutter dependencies
```

## Dependencies

### Backend
- FastAPI
- Uvicorn
- SQLAlchemy
- Pillow
- Boto3

### Frontend
- Flutter
- Dio (HTTP client)
- Cached Network Image
- Image Picker

## Deployment

For production deployment, it's recommended to:
1. Split this monorepo into separate repositories for frontend and backend
2. Deploy the backend to a cloud service (AWS, Google Cloud, etc.)
3. Build and deploy the frontend to app stores

## License

This project is licensed under the MIT License.