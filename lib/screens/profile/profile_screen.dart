import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chosen/controllers/user_controller.dart';
import 'package:chosen/controllers/auth_controller.dart';
import 'package:chosen/controllers/tracking_controller.dart';
import 'package:chosen/models/user.dart';
import 'package:chosen/models/weight_tracking.dart';
import 'package:chosen/models/day_rating.dart';
import 'package:chosen/models/progress_photo.dart';
import 'package:chosen/screens/tracking/weight_tracking_screen.dart';
import 'package:chosen/screens/tracking/day_rating_tracking_screen.dart';
import 'package:chosen/screens/tracking/progress_photos_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userController = UserController();
  final _authController = AuthController();
  
  UserModel? _user;
  List<WeightTracking> _weightHistory = [];
  DayRating? _lastDayRating;
  List<ProgressPhoto> _progressPhotos = [];
  List<DayRating> _dayRatings = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load user data
      await _userController.getCurrentUser();
      final user = await _userController.getStoredUser();
      
      // Load tracking data
      final weightHistory = await TrackingController.getWeightTracking();
      final dayRatings = await TrackingController.getDayRatings();
      final progressPhotos = await TrackingController.getProgressPhotos();
      
      setState(() {
        _user = user;
        _weightHistory = weightHistory;
        _dayRatings = dayRatings;
        _lastDayRating = dayRatings.isNotEmpty ? dayRatings.first : null;
        _progressPhotos = progressPhotos;
      });
    } catch (e) {
      print('Error loading profile data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Add Weight Dialog
  void _showAddWeightDialog() {
    final TextEditingController weightController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.monitor_weight_outlined, color: Colors.black, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'Add Weight Entry',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Weight (kg)',
                        hintText: 'Enter your weight',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixText: 'kg',
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Colors.black,
                                  onPrimary: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null && picked != selectedDate) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            final weight = double.tryParse(weightController.text);
                            if (weight != null && weight > 0) {
                              Navigator.of(context).pop();
                              
                              final result = await TrackingController.saveWeight(
                                weight,
                                date: selectedDate,
                              );
                              if (result != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Weight saved successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                _loadProfileData();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to save weight'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  // Add Day Rating Dialog
  void _showAddDayRatingDialog() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final todayRating = _dayRatings.firstWhere(
      (rating) {
        final ratingDate = DateTime(
          rating.createdAt.year,
          rating.createdAt.month,
          rating.createdAt.day,
        );
        return ratingDate.isAtSameMomentAs(today);
      },
      orElse: () => DayRating(
        id: -1,
        userId: -1,
        createdAt: DateTime(1970),
        updatedAt: DateTime(1970),
      ),
    );
    
    if (todayRating.id != -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Već ste ocijenili danas! Možete urediti postojeću ocjenu.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    int? selectedScore;
    final TextEditingController noteController = TextEditingController();
    
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
                        const Icon(Icons.sentiment_satisfied, color: Colors.black, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'Ocijeni svoj dan',
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
                      'Kako je prošao tvoj dan? (1-10)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(10, (index) {
                        final score = index + 1;
                        final isSelected = selectedScore == score;
                        return GestureDetector(
                          onTap: () => setState(() => selectedScore = score),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.black : Colors.transparent,
                              border: Border.all(color: Colors.black),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                score.toString(),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Zašto?',
                        hintText: 'Zašto daješ ovu ocjenu svom danu?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Odustani'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: selectedScore != null ? () async {
                            Navigator.of(context).pop();
                            
                            final result = await TrackingController.createDayRating(
                              score: selectedScore,
                              note: noteController.text.isNotEmpty ? noteController.text : null,
                            );
                            
                            if (result != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Ocjena dana uspješno spremljena!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadProfileData();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Greška kod spremanja ocjene'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Spremi'),
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

  // Add Progress Photo Dialog
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
                          'Add Progress Photo',
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
                      'Select photo angle:',
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
                                  'Klikni i odaberi sliku',
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
                            label: const Text('Camera'),
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
                            label: const Text('Gallery'),
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
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: (selectedAngle != null && imagePath != null) 
                              ? () async {
                                  Navigator.of(context).pop();
                                  
                                  // Show loading indicator
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
                                  
                                  // Upload the image
                                  final result = await TrackingController.uploadProgressPhoto(
                                    selectedAngle!.name,
                                    imagePath!,
                                  );
                                  
                                  // Clear loading indicator
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  
                                  if (result != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Progress photo saved!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    _loadProfileData();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to save photo'),
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
                          child: const Text('Save'),
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

  String getUserInitials() {
    if (_user == null) return 'ER';
    final first = _user!.firstName.isNotEmpty ? _user!.firstName[0] : '';
    final last = _user!.lastName.isNotEmpty ? _user!.lastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  String getFullName() {
    if (_user == null) return 'Loading...';
    return '${_user!.firstName} ${_user!.lastName}';
  }

  double? getCurrentWeight() {
    if (_weightHistory.isEmpty) return null;
    
    // Sort by date (newest first) to get the most recent weight
    final sortedHistory = List<WeightTracking>.from(_weightHistory)
      ..sort((a, b) {
        final dateA = a.date ?? a.createdAt;
        final dateB = b.date ?? b.createdAt;
        return dateB.compareTo(dateA); // Descending order
      });
    
    return sortedHistory.first.weight;
  }

  double? getWeightChange() {
    if (_weightHistory.length < 2) return null;
    
    // Sort by date (newest first)
    final sortedHistory = List<WeightTracking>.from(_weightHistory)
      ..sort((a, b) {
        final dateA = a.date ?? a.createdAt;
        final dateB = b.date ?? b.createdAt;
        return dateB.compareTo(dateA); // Descending order
      });
    
    // Calculate change between the two most recent entries
    return sortedHistory[0].weight - sortedHistory[1].weight;
  }

  int get totalWeightEntries => _weightHistory.length;

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
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'settings') {
                // Navigate to settings when implemented
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings coming soon!')),
                );
              } else if (value == 'logout') {
                await _authController.logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, color: Colors.grey[600], size: 18),
                    const SizedBox(width: 12),
                    const Text('Settings', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_outlined, color: Colors.red[400], size: 18),
                    const SizedBox(width: 12),
                    Text('Logout', style: TextStyle(fontSize: 14, color: Colors.red[400])),
                  ],
                ),
              ),
            ],
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: const Icon(Icons.more_vert, color: Colors.black),
            ),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.black))
        : RefreshIndicator(
            onRefresh: _loadProfileData,
            color: Colors.black,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 32),
                  _buildWeightStatsSection(),
                  const SizedBox(height: 24),
                  _buildDayRatingSection(),
                  const SizedBox(height: 24),
                  _buildProgressPhotosSection(),
                ],
              ),
            ),
          ),
    );
  }

 Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
             Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[300]!, width: 3),
                ),
                child: _user?.profilePicture != null
                    ? CircleAvatar(
                        backgroundColor: Colors.black,
                        radius: 50,
                        child: ClipOval(
                          child: Image.network(
                            _userController.getProfilePictureUrl(_user!.profilePicture) ?? '',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              }
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              // Show initials if image fails to load
                              return Container(
                                width: 100,
                                height: 100,
                                color: Colors.black,
                                child: Center(
                                  child: Text(
                                    getUserInitials(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 28,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      )
                    : CircleAvatar(
                        backgroundColor: Colors.black,
                        radius: 50,
                        child: Text(
                          getUserInitials(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showImagePickerOptions,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            getFullName(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _user?.email ?? '',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Promijeni profilnu sliku',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.blue),
                  ),
                  title: const Text('Kamera'),
                  subtitle: const Text('Snimi novu sliku'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.photo_library, color: Colors.purple),
                  ),
                  title: const Text('Galerija'),
                  subtitle: const Text('Odaberi iz galerije'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_user?.profilePicture != null)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                    title: const Text('Ukloni sliku'),
                    subtitle: const Text('Vrati na inicijalnu'),
                    onTap: () {
                      Navigator.pop(context);
                      _removeProfilePicture();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 16),
                  Text('Uploading profile picture...'),
                ],
              ),
              duration: Duration(seconds: 30),
            ),
          );
        }

        // Upload the image
        final File imageFile = File(image.path);
        final success = await _userController.updateProfilePicture(
          _user!.id,
          imageFile,
        );

        // Clear loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
        }

        if (success) {
          // Reload profile data to get the updated image
          await _loadProfileData();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profilna slika uspješno ažurirana!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Greška kod uploada slike'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _removeProfilePicture() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Ukloni profilnu sliku?'),
          content: const Text('Jesi li siguran da želiš ukloniti profilnu sliku?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Odustani'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ukloni'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // For now, just show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Funkcionalnost uklanjanja slike će uskoro biti dostupna'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Widget _buildWeightStatsSection() {
      double? currentWeight;
      double? weightChange;
      
      if (_weightHistory.isNotEmpty) {
        // Sort by date (newest first) to get current and previous weights
        final sortedHistory = List<WeightTracking>.from(_weightHistory)
          ..sort((a, b) {
            final dateA = a.date ?? a.createdAt;
            final dateB = b.date ?? b.createdAt;
            return dateB.compareTo(dateA); // Descending order
          });
        
        currentWeight = sortedHistory.first.weight;
        
        if (sortedHistory.length >= 2) {
          weightChange = sortedHistory[0].weight - sortedHistory[1].weight;
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Praćenje kilaže',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              GestureDetector(
                onTap: _showAddWeightDialog,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WeightTrackingScreen(),
                ),
              );
            },
            child: Container(
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
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildWeightStat(
                        'Trenutna kilaža',
                        currentWeight?.toStringAsFixed(1) ?? '--',
                        'kg',
                        Icons.monitor_weight_outlined,
                      ),
                      Container(
                        width: 1,
                        height: 50,
                        color: Colors.grey[200],
                      ),
                      _buildWeightStat(
                        'Ukupno unosa',
                        totalWeightEntries.toString(),
                        '',
                        Icons.history,
                      ),
                    ],
                  ),
                  if (weightChange != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: weightChange >= 0 ? Colors.red[50] : Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            weightChange >= 0 ? Icons.trending_up : Icons.trending_down,
                            color: weightChange >= 0 ? Colors.red : Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${weightChange >= 0 ? '+' : ''}${weightChange.toStringAsFixed(1)} kg od zadnjeg unosa',
                            style: TextStyle(
                              color: weightChange >= 0 ? Colors.red : Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.show_chart, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Pogledaj više detalja',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

  Widget _buildWeightStat(String label, String value, String unit, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 24, color: Colors.black),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDayRatingSection() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ocjenjivanje dana',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              GestureDetector(
                onTap: _showAddDayRatingDialog,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DayRatingTrackingScreen(),
                ),
              );
            },
            child: Container(
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
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildRatingStat(
                        'Najnovija ocjena',
                        _lastDayRating?.score?.toString() ?? '--',
                        '/10',
                        _getRatingIcon(_lastDayRating?.score),
                        _getRatingColor(_lastDayRating?.score),
                      ),
                      Container(
                        width: 1,
                        height: 50,
                        color: Colors.grey[200],
                      ),
                      _buildRatingStat(
                        'Prosječna ocjena',
                        _getAverageRating()?.toStringAsFixed(1) ?? '--',
                        '/10',
                        Icons.trending_up,
                        Colors.blue,
                      ),
                    ],
                  ),
                  if (_lastDayRating != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getRatingColor(_lastDayRating!.score).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getRatingIcon(_lastDayRating!.score),
                            color: _getRatingColor(_lastDayRating!.score),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _lastDayRating!.note?.isNotEmpty == true 
                                  ? _lastDayRating!.note!
                                  : 'Dan ocjenjen ${_formatDate(_lastDayRating!.createdAt)}',
                              style: TextStyle(
                                color: _getRatingColor(_lastDayRating!.score),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Pogledaj više detalja',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    Widget _buildRatingStat(String label, String value, String unit, IconData icon, Color color) {
      return Expanded(
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Helper method to calculate average rating
    double? _getAverageRating() {
      if (_dayRatings.isEmpty) return null;
      
      final validRatings = _dayRatings.where((rating) => rating.score != null).toList();
      if (validRatings.isEmpty) return null;
      
      final sum = validRatings.fold<int>(0, (sum, rating) => sum + (rating.score ?? 0));
      return sum / validRatings.length;
    }

    Color _getRatingColor(int? score) {
      if (score == null) return Colors.grey;
      if (score >= 8) return Colors.green;
      if (score >= 6) return Colors.orange;
      if (score >= 4) return Colors.yellow[700]!;
      return Colors.red;
    }

    IconData _getRatingIcon(int? score) {
      if (score == null) return Icons.sentiment_neutral;
      if (score >= 8) return Icons.sentiment_very_satisfied;
      if (score >= 6) return Icons.sentiment_satisfied;
      if (score >= 4) return Icons.sentiment_neutral;
      return Icons.sentiment_very_dissatisfied;
    }

 Widget _buildProgressPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Slike napredka',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            GestureDetector(
              onTap: _showAddProgressPhotoDialog,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProgressPhotosScreen(),
              ),
            );
          },
          child: Container(
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
            child: _progressPhotos.isEmpty
                ? _buildEmptyPhotosWidget()
                : _buildPhotosPreviewWidget(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPhotosWidget() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.photo_camera_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Nema slika napredaka',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Dodaj svoju prvu sliku napredaka i kreni voditi svoj put!',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              'Pogledaj više detalja',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotosPreviewWidget() {
    // Group photos by angle
    Map<PhotoAngle, List<ProgressPhoto>> groupedPhotos = {};
    for (var photo in _progressPhotos) {
      if (!groupedPhotos.containsKey(photo.angle)) {
        groupedPhotos[photo.angle] = [];
      }
      groupedPhotos[photo.angle]!.add(photo);
    }

    return Column(
      children: [
        // Stats row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildPhotoStat(
              'Ukupno slika',
              _progressPhotos.length.toString(),
              '',
              Icons.photo_camera_outlined,
              Colors.blue,
            ),
            Container(
              width: 1,
              height: 50,
              color: Colors.grey[200],
            ),
            _buildPhotoStat(
              'Uglova snimljeno',
              groupedPhotos.length.toString(),
              '/3',
              Icons.view_carousel_outlined,
              Colors.green,
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Latest photos preview
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Najnovije slike',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _formatDate(_progressPhotos.first.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Photos grid preview (max 3 photos)
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _progressPhotos.length > 3 ? 4 : _progressPhotos.length,
            itemBuilder: (context, index) {
              if (index == 3) {
                return _buildMorePhotosPreview(_progressPhotos.length - 3);
              }
              return Container(
                margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                child: _buildMiniPhotoCard(_progressPhotos[index]),
              );
            },
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Progress indicator for angles
        _buildAngleProgress(groupedPhotos),
        
        const SizedBox(height: 12),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              'Pogledaj sve slike i detalje',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoStat(String label, String value, String unit, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPhotoCard(ProgressPhoto photo) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
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
                    size: 24,
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
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getAngleDisplayName(photo.angle),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildMorePhotosPreview(int remainingCount) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 4),
          Text(
            '+$remainingCount',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAngleProgress(Map<PhotoAngle, List<ProgressPhoto>> groupedPhotos) {
    final angles = [PhotoAngle.front, PhotoAngle.side, PhotoAngle.back];
    final angleNames = ['Front', 'Side', 'Back'];
    
    return Row(
      children: List.generate(3, (index) {
        final angle = angles[index];
        final hasPhotos = groupedPhotos.containsKey(angle);
        final photoCount = hasPhotos ? groupedPhotos[angle]!.length : 0;
        
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: hasPhotos ? Colors.green[50] : Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasPhotos ? Colors.green[200]! : Colors.grey[200]!,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasPhotos ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                  size: 16,
                  color: hasPhotos ? Colors.green : Colors.grey[400],
                ),
                const SizedBox(width: 6),
                Text(
                  angleNames[index],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: hasPhotos ? Colors.green[700] : Colors.grey[600],
                  ),
                ),
                if (hasPhotos) ...[
                  const SizedBox(width: 4),
                  Text(
                    '($photoCount)',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateShort(DateTime date) {
    return '${date.day}/${date.month}';
  }
}