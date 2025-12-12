# Photomi Frontend

Flutter frontend for the Photomi personal photo manager.

## Features

- Photo grid view with thumbnails
- Full-resolution image viewer
- Photo upload from device gallery
- Responsive UI design

## Prerequisites

- Flutter SDK

## Setup

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Configure environment variables:
   - Copy `.env.example` to `.env`
   - Update the values in `.env` with your backend URL

3. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
.
├── lib/
│   ├── main.dart    # Main application
│   └── config.dart  # Configuration loader
└── pubspec.yaml     # Flutter dependencies
```

## Dependencies

- Flutter SDK
- Dio (HTTP client)
- Cached Network Image
- Image Picker

## License

This project is licensed under the MIT License.