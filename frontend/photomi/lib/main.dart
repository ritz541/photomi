import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'dart:io';
import 'config.dart';
import 'screens/photo_viewer_screen.dart';

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
  String _errorMessage = '';
  late String _baseUrl;
  Set<int> _selectedPhotos = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _baseUrl = AppConfig.apiUrl;
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
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
      setState(() {
        _errorMessage = 'Failed to load photos: $e';
      });
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
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null && images.isNotEmpty) {
      // Show uploading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Uploading ${images.length} photos...'),
              ],
            ),
          );
        },
      );

      int successCount = 0;
      int failCount = 0;

      try {
        for (int i = 0; i < images.length; i++) {
          final image = images[i];
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
              successCount++;
            } else {
              failCount++;
            }
          } catch (e) {
            failCount++;
          }
        }

        Navigator.of(context).pop(); // Close the uploading dialog

        // Show results
        String message;
        if (failCount == 0) {
          message = 'All photos uploaded successfully!';
        } else if (successCount == 0) {
          message = 'Failed to upload all photos.';
        } else {
          message =
              '$successCount photos uploaded successfully. $failCount failed.';
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));

        _loadPhotos(); // Refresh the photo list
      } catch (e) {
        Navigator.of(context).pop(); // Close the uploading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload photos: $e')));
      }
    }
  }

  Future<void> _deletePhoto(Photo photo) async {
    try {
      final response = await _dio.delete('$_baseUrl/photos/${photo.id}');
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo deleted successfully')),
        );
        _loadPhotos(); // Refresh the photo list
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete photo: $e')));
    }
  }

  Future<void> _deleteSelectedPhotos() async {
    if (_selectedPhotos.isEmpty) return;

    int successCount = 0;
    int failCount = 0;

    try {
      // Show deleting indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Deleting ${_selectedPhotos.length} photos...'),
              ],
            ),
          );
        },
      );

      for (int id in _selectedPhotos) {
        try {
          final response = await _dio.delete('$_baseUrl/photos/$id');
          if (response.statusCode == 200) {
            successCount++;
          } else {
            failCount++;
          }
        } catch (e) {
          failCount++;
        }
      }

      Navigator.of(context).pop(); // Close the deleting dialog

      // Show results
      String message;
      if (failCount == 0) {
        message = 'All photos deleted successfully!';
      } else if (successCount == 0) {
        message = 'Failed to delete all photos.';
      } else {
        message =
            '$successCount photos deleted successfully. $failCount failed.';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));

      // Exit selection mode
      setState(() {
        _isSelectionMode = false;
        _selectedPhotos.clear();
      });

      _loadPhotos(); // Refresh the photo list
    } catch (e) {
      Navigator.of(context).pop(); // Close the deleting dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete photos: $e')));
    }
  }

  void _toggleSelection(int photoId) {
    setState(() {
      if (_selectedPhotos.contains(photoId)) {
        _selectedPhotos.remove(photoId);
      } else {
        _selectedPhotos.add(photoId);
      }

      // If no photos are selected, exit selection mode
      if (_selectedPhotos.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedPhotos = Set.from(_photos.map((photo) => photo.id));
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedPhotos.clear();
      _isSelectionMode = false;
    });
  }

  void _showPhotoDetail(Photo photo) {
    // Find the index of the selected photo
    int index = _photos.indexWhere((p) => p.id == photo.id);
    if (index == -1) index = 0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PhotoViewerScreen(photos: _photos, initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedPhotos.length} selected')
            : const Text('Photomi Gallery'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: _selectAll,
                  tooltip: 'Select All',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteSelectedPhotos,
                  tooltip: 'Delete Selected',
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearSelection,
                  tooltip: 'Cancel Selection',
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = true;
                    });
                  },
                  tooltip: 'Select Photos',
                ),
                PopupMenuButton<String>(
                  onSelected: (String result) {
                    if (result == 'refresh') {
                      _loadPhotos();
                    } else if (result == 'sort_newest') {
                      // Sorting is already newest first, but we can refresh to ensure
                      _loadPhotos();
                    } else if (result == 'sort_oldest') {
                      // We would need to modify the backend for this
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sort by oldest not implemented'),
                        ),
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'refresh',
                          child: ListTile(
                            leading: Icon(Icons.refresh),
                            title: Text('Refresh'),
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'sort_newest',
                          child: ListTile(
                            leading: Icon(Icons.sort_by_alpha),
                            title: Text('Sort by Newest'),
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'sort_oldest',
                          child: ListTile(
                            leading: Icon(Icons.sort_by_alpha),
                            title: Text('Sort by Oldest'),
                          ),
                        ),
                      ],
                ),
              ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading photos...'),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_errorMessage),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadPhotos,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _photos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_library, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No photos found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _pickAndUploadImage,
                    child: const Text('Upload Your First Photo'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadPhotos,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    snap: true,
                    floating: true,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.inversePrimary,
                    expandedHeight: 60.0,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text('${_photos.length} Photos'),
                      centerTitle: true,
                    ),
                  ),
                  SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.0,
                        ),
                    delegate: SliverChildBuilderDelegate((
                      BuildContext context,
                      int index,
                    ) {
                      final photo = _photos[index];
                      return GestureDetector(
                        onTap: _isSelectionMode
                            ? () => _toggleSelection(photo.id)
                            : () => _showPhotoDetail(photo),
                        onLongPress: () {
                          if (!_isSelectionMode) {
                            setState(() {
                              _isSelectionMode = true;
                              _selectedPhotos.add(photo.id);
                            });
                          } else {
                            _toggleSelection(photo.id);
                          }
                        },
                        child: Hero(
                          tag: photo.id,
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side:
                                  _isSelectionMode &&
                                      _selectedPhotos.contains(photo.id)
                                  ? BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      width: 3,
                                    )
                                  : BorderSide.none,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: photo.thumbnailUrl,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        const Center(child: Icon(Icons.error)),
                                    fit: BoxFit.cover,
                                  ),
                                  if (_isSelectionMode)
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color:
                                              _selectedPhotos.contains(photo.id)
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : Colors.transparent,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color:
                                                _selectedPhotos.contains(
                                                  photo.id,
                                                )
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.primary
                                                : Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child:
                                            _selectedPhotos.contains(photo.id)
                                            ? const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 16,
                                              )
                                            : null,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }, childCount: _photos.length),
                  ),
                ],
              ),
            ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _pickAndUploadImage,
              tooltip: 'Upload Photos',
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Upload'),
            ),
    );
  }
}
