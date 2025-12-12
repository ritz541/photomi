import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'config.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photomi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PhotoGalleryScreen(),
    );
  }
}

class Photo {
  final int id;
  final String filename;
  final String thumbnailUrl;
  final String originalUrl;
  final String createdAt;

  Photo({
    required this.id,
    required this.filename,
    required this.thumbnailUrl,
    required this.originalUrl,
    required this.createdAt,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'],
      filename: json['filename'],
      thumbnailUrl: json['thumbnail_url'],
      originalUrl: json['original_url'],
      createdAt: json['created_at'],
    );
  }
}

class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({super.key});

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  final Dio _dio = Dio();
  final ImagePicker _picker = ImagePicker();
  List<Photo> _photos = [];
  bool _isLoading = false;
  late String _baseUrl;

  @override
  void initState() {
    super.initState();
    _baseUrl = AppConfig.apiUrl;
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _dio.get('$_baseUrl/photos/');
      if (response.statusCode == 200) {
        final List<dynamic> photosJson = response.data;
        setState(() {
          _photos = photosJson.map((json) => Photo.fromJson(json)).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load photos: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      try {
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            image.path,
            filename: image.name,
          ),
        });

        final response = await _dio.post(
          '$_baseUrl/upload/',
          data: formData,
          options: Options(contentType: 'multipart/form-data'),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo uploaded successfully!')),
          );
          _loadPhotos(); // Refresh the photo list
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload photo: $e')));
      }
    }
  }

  void _showPhotoDetail(Photo photo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CachedNetworkImage(
                imageUrl: photo.originalUrl,
                placeholder: (context, url) =>
                    const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.error),
                fit: BoxFit.contain,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  photo.filename,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text('Uploaded: ${photo.createdAt}'),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photomi Gallery'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                final photo = _photos[index];
                return GestureDetector(
                  onTap: () => _showPhotoDetail(photo),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: photo.thumbnailUrl,
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndUploadImage,
        tooltip: 'Upload Photo',
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
