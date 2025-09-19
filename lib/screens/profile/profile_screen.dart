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
                          'Rate Your Day',
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
                      'How was your day? (1-10)',
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
                        labelText: 'Notes (optional)',
                        hintText: 'How are you feeling today?',
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
                          child: const Text('Cancel'),
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
                                  content: Text('Day rating saved!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadProfileData();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to save rating'),
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
                                  'Tap to select photo',
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
    return _weightHistory.first.weight;
  }

  double? getWeightChange() {
    if (_weightHistory.length < 2) return null;
    return _weightHistory.first.weight - _weightHistory[1].weight;
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
                  _buildLastDayRatingSection(),
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
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[300]!, width: 3),
            ),
            child: CircleAvatar(
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

  Widget _buildWeightStatsSection() {
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
            Row(
              children: [
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.show_chart, size: 16, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                      getCurrentWeight()?.toStringAsFixed(1) ?? '--',
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
                if (getWeightChange() != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: getWeightChange()! >= 0 ? Colors.red[50] : Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          getWeightChange()! >= 0 ? Icons.trending_up : Icons.trending_down,
                          color: getWeightChange()! >= 0 ? Colors.red : Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${getWeightChange()! >= 0 ? '+' : ''}${getWeightChange()!.toStringAsFixed(1)} kg since last entry',
                          style: TextStyle(
                            color: getWeightChange()! >= 0 ? Colors.red : Colors.green,
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
                      'Tap to view detailed charts',
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

  Widget _buildLastDayRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ocijenjivanje dana',
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
        Container(
          width: double.infinity,
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
          child: _lastDayRating == null
              ? Column(
                  children: [
                    Icon(Icons.sentiment_neutral, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'Još niste ocijelini svoj dan',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ocijeni svoj dan!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getRatingColor(_lastDayRating!.score).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getRatingIcon(_lastDayRating!.score),
                            color: _getRatingColor(_lastDayRating!.score),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ocijena: ${_lastDayRating!.score ?? 'N/A'}/10',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(_lastDayRating!.createdAt),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_lastDayRating!.note != null && _lastDayRating!.note!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _lastDayRating!.note!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
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
            Row(
              children: [
                Text(
                  '${_progressPhotos.length} slika',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 12),
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
          ],
        ),
        const SizedBox(height: 16),
        _progressPhotos.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
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
                    Icon(Icons.photo_camera_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Nema slika',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kreni voditi slike napredtka!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: _progressPhotos.length > 6 ? 6 : _progressPhotos.length,
                itemBuilder: (context, index) {
                  if (index == 5 && _progressPhotos.length > 6) {
                    return _buildMorePhotosCard(_progressPhotos.length - 5);
                  }
                  return _buildProgressPhotoCard(_progressPhotos[index]);
                },
              ),
      ],
    );
  }

  Widget _buildProgressPhotoCard(ProgressPhoto photo) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getAngleDisplayName(photo.angle),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatDateShort(photo.createdAt),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMorePhotosCard(int remainingCount) {
    return Container(
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
            size: 32,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 8),
          Text(
            '+$remainingCount',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Text(
            'more',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
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
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateShort(DateTime date) {
    return '${date.day}/${date.month}';
  }
}