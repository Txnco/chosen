// lib/screens/tracking/progress_photos_screen.dart
import 'package:flutter/material.dart';
import 'package:chosen/controllers/tracking_controller.dart';
import 'package:chosen/models/progress_photo.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProgressPhotosScreen extends StatefulWidget {
  const ProgressPhotosScreen({super.key});

  @override
  State<ProgressPhotosScreen> createState() => _ProgressPhotosScreenState();
}

class _ProgressPhotosScreenState extends State<ProgressPhotosScreen> with SingleTickerProviderStateMixin {
  List<ProgressPhoto> _progressPhotos = [];
  bool _isLoading = true;
  late TabController _tabController;
  PhotoAngle _selectedFilter = PhotoAngle.front;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // All, Front, Side, Back
    _loadProgressPhotos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProgressPhotos() async {
    setState(() => _isLoading = true);
    
    try {
      final photos = await TrackingController.getProgressPhotos();
      setState(() {
        _progressPhotos = photos;
      });
    } catch (e) {
      print('Error loading progress photos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<ProgressPhoto> _getFilteredPhotos() {
    if (_tabController.index == 0) return _progressPhotos; // All photos
    
    final angles = [PhotoAngle.front, PhotoAngle.side, PhotoAngle.back];
    final selectedAngle = angles[_tabController.index - 1];
    
    return _progressPhotos.where((photo) => photo.angle == selectedAngle).toList();
  }

  Map<PhotoAngle, List<ProgressPhoto>> _getGroupedPhotos() {
    Map<PhotoAngle, List<ProgressPhoto>> grouped = {};
    for (var photo in _progressPhotos) {
      if (!grouped.containsKey(photo.angle)) {
        grouped[photo.angle] = [];
      }
      grouped[photo.angle]!.add(photo);
    }
    return grouped;
  }

  void _showAddProgressPhotoDialog() {
    PhotoAngle? selectedAngle;
    String? imagePath;
    final ImagePicker picker = ImagePicker();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.photo_camera_outlined, color: Colors.black, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'Dodaj sliku napredaka',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Izaberi ugao:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildAngleButton('Front', PhotoAngle.front, selectedAngle, (angle) {
                          setState(() => selectedAngle = angle);
                        }),
                        const SizedBox(width: 8),
                        _buildAngleButton('Side', PhotoAngle.side, selectedAngle, (angle) {
                          setState(() => selectedAngle = angle);
                        }),
                        const SizedBox(width: 8),
                        _buildAngleButton('Back', PhotoAngle.back, selectedAngle, (angle) {
                          setState(() => selectedAngle = angle);
                        }),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: imagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(imagePath!),
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, 
                                     size: 40, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text(
                                  'Dodaj sliku',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.camera,
                                imageQuality: 80,
                              );
                              if (image != null) {
                                setState(() => imagePath = image.path);
                              }
                            },
                            icon: const Icon(Icons.camera_alt_outlined, size: 18),
                            label: const Text('Kamera'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 80,
                              );
                              if (image != null) {
                                setState(() => imagePath = image.path);
                              }
                            },
                            icon: const Icon(Icons.photo_library_outlined, size: 18),
                            label: const Text('Galerija'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Otkaži'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: (selectedAngle != null && imagePath != null) 
                              ? () async {
                                  Navigator.of(context).pop();
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Row(
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                          SizedBox(width: 16),
                                          Text('Uploading photo...'),
                                        ],
                                      ),
                                      duration: Duration(seconds: 30),
                                    ),
                                  );
                                  
                                  final result = await TrackingController.uploadProgressPhoto(
                                    selectedAngle!.name,
                                    imagePath!,
                                  );
                                  
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  
                                  if (result != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Slika uspješno dodana!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    _loadProgressPhotos();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Greška pri dodavanju slike'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } 
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Sačuvaj'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAngleButton(String label, PhotoAngle angle, PhotoAngle? selectedAngle, Function(PhotoAngle) onTap) {
    final isSelected = selectedAngle == angle;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(angle),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.transparent,
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _showPhotoDetail(ProgressPhoto photo) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Photo
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        photo.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[100],
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey[400],
                              size: 48,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_getAngleDisplayName(photo.angle)} View',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(photo.createdAt),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Slike napredka',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showAddProgressPhotoDialog,
            icon: const Icon(Icons.add, color: Colors.black),
          ),
        ],
        bottom: _progressPhotos.isNotEmpty ? TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
          onTap: (index) => setState(() {}),
          tabs: [
            Tab(text: 'Sve (${_progressPhotos.length})'),
            Tab(text: 'Front (${_getGroupedPhotos()[PhotoAngle.front]?.length ?? 0})'),
            Tab(text: 'Side (${_getGroupedPhotos()[PhotoAngle.side]?.length ?? 0})'),
            Tab(text: 'Back (${_getGroupedPhotos()[PhotoAngle.back]?.length ?? 0})'),
          ],
        ) : null,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.black))
        : RefreshIndicator(
            onRefresh: _loadProgressPhotos,
            color: Colors.black,
            child: _buildContent(),
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProgressPhotoDialog,
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildContent() {
    if (_progressPhotos.isEmpty) {
      return _buildEmptyState();
    }

    final filteredPhotos = _getFilteredPhotos();
    
    if (filteredPhotos.isEmpty) {
      return _buildEmptyFilterState();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats section
          _buildStatsSection(),
          const SizedBox(height: 24),
          
          // Photos grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: filteredPhotos.length,
              itemBuilder: (context, index) {
                return _buildPhotoCard(filteredPhotos[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final grouped = _getGroupedPhotos();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Ukupno slika',
            _progressPhotos.length.toString(),
            Icons.photo_camera_outlined,
            Colors.blue,
          ),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          _buildStatItem(
            'Front',
            (grouped[PhotoAngle.front]?.length ?? 0).toString(),
            Icons.person_outlined,
            Colors.green,
          ),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          _buildStatItem(
            'Side',
            (grouped[PhotoAngle.side]?.length ?? 0).toString(),
            Icons.accessibility_outlined,
            Colors.orange,
          ),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          _buildStatItem(
            'Back',
            (grouped[PhotoAngle.back]?.length ?? 0).toString(),
            Icons.back_hand_outlined,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPhotoCard(ProgressPhoto photo) {
    return GestureDetector(
      onTap: () => _showPhotoDetail(photo),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                photo.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[100],
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.grey[400],
                      size: 32,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[100],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / 
                              loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
              ),
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              // Angle badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getAngleColor(photo.angle).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getAngleDisplayName(photo.angle),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              // Date and action
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(photo.createdAt),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(photo.createdAt),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              // View indicator
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.visibility_outlined,
                    size: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height - 200,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.photo_camera_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nema slika napredaka',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Dodaj svoju prvu sliku napredaka i kreni voditi svoj put ka cilju!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showAddProgressPhotoDialog,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Dodaj prvu sliku'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    final tabNames = ['sve slike', 'front slike', 'side slike', 'back slike'];
    final currentTab = tabNames[_tabController.index];
    
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height - 300,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Nema $currentTab',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Dodaj slike za ovaj ugao da bi vidio svoj napredak!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getAngleColor(PhotoAngle angle) {
    switch (angle) {
      case PhotoAngle.front:
        return Colors.green;
      case PhotoAngle.side:
        return Colors.orange;
      case PhotoAngle.back:
        return Colors.purple;
    }
  }

  String _getAngleDisplayName(PhotoAngle angle) {
    switch (angle) {
      case PhotoAngle.front:
        return 'Front';
      case PhotoAngle.side:
        return 'Side';
      case PhotoAngle.back:
        return 'Back';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}