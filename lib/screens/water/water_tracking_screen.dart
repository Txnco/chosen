// lib/screens/water/water_tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:chosen/models/water_intake.dart';
import 'package:chosen/controllers/water_controller.dart';
import 'dart:math' as math;

class WaterTrackingScreen extends StatefulWidget {
  const WaterTrackingScreen({super.key});

  @override
  State<WaterTrackingScreen> createState() => _WaterTrackingScreenState();
}

class _WaterTrackingScreenState extends State<WaterTrackingScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  DateTime _selectedDate = DateTime.now();
  String _selectedPeriod = 'Day'; // Day, Week, Month
  
  // Data from API
  WaterDailyStats? _dailyStats;
  List<WaterIntake> _todayIntakes = [];
  bool _isLoading = true;
  bool _isAddingWater = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    
    _loadDataForDate(_selectedDate);
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadDataForDate(DateTime date) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Ensure user has a water goal first
      await WaterController.ensureUserHasWaterGoal();
      
      // Load daily stats and intake entries
      final stats = await WaterController.getDailyWaterStats(targetDate: date);
      final intakes = await WaterController.getWaterIntakeForDate(date);
      
      setState(() {
        _dailyStats = stats;
        _todayIntakes = intakes;
        _isLoading = false;
      });
      
      // Update progress animation
      if (stats != null) {
        _updateProgressAnimation(stats.progressPercentage / 100);
      }
      
    } catch (e) {
      print('Error loading water data: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load water data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateProgressAnimation(double targetProgress) {
    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: targetProgress.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    
    _progressController.reset();
    _progressController.forward();
  }

  void _showAddWaterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AddWaterModal(
        onAddWater: _addWaterIntake,
        isLoading: _isAddingWater,
      ),
    );
  }

  Future<void> _addWaterIntake(double amount, {bool fromModal = false}) async {
    setState(() {
      _isAddingWater = true;
    });

    try {
      final newIntake = await WaterController.addWaterIntake(amount.toInt());
      
      if (newIntake != null) {
        // Reload data for the current date
        await _loadDataForDate(_selectedDate);
        
        if (mounted) {
          if (fromModal) {
            // Close modal only if called from modal
            Navigator.of(context).pop();
          }
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${amount.toInt()}ml water intake!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add water intake. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error adding water intake: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isAddingWater = false;
      });
    }
  }

  Future<void> _deleteWaterIntake(WaterIntake intake) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Water Intake'),
        content: Text('Are you sure you want to delete the ${intake.waterIntake}ml intake?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && intake.id != null) {
      try {
        final success = await WaterController.deleteWaterIntakeEntry(intake.id!);
        
        if (success) {
          // Reload data
          await _loadDataForDate(_selectedDate);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Deleted ${intake.waterIntake}ml intake'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to delete intake. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        print('Error deleting water intake: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting intake: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _previousDate() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _loadDataForDate(_selectedDate);
  }

  void _nextDate() {
    final tomorrow = _selectedDate.add(const Duration(days: 1));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (DateTime(tomorrow.year, tomorrow.month, tomorrow.day).isAfter(today)) {
      return; // Don't allow future dates
    }
    
    setState(() {
      _selectedDate = tomorrow;
    });
    _loadDataForDate(_selectedDate);
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadDataForDate(picked);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);
    
    if (selectedDay == today) {
      return 'Danas';
    } else if (selectedDay == today.subtract(const Duration(days: 1))) {
      return 'Jučer';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
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
          'Unos vode',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.black,
          ),
          SizedBox(height: 16),
          Text(
            'Loading water data...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildDateSelector(),
          const SizedBox(height: 32),
          _buildProgressSemiCircle(),
          const SizedBox(height: 32),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildIntakeLog(),
          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    final isToday = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day) == 
                   DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    
    return isToday ? Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: FloatingActionButton(
        onPressed: _showAddWaterModal,
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    ) : const SizedBox.shrink();
  }

  Widget _buildDateSelector() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final canGoForward = selectedDay.isBefore(today);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _previousDate,
            icon: const Icon(Icons.chevron_left, size: 24),
            color: Colors.grey[700],
          ),
          Expanded(
            child: GestureDetector(
              onTap: _selectDate,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatDate(_selectedDate),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.calendar_today, 
                       color: Colors.grey[600], 
                       size: 18),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: canGoForward ? _nextDate : null,
            icon: const Icon(Icons.chevron_right, size: 24),
            color: canGoForward ? Colors.grey[700] : Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSemiCircle() {
    final currentIntake = _dailyStats?.totalIntake ?? 0.0;
    final dailyGoal = _dailyStats?.goalAmount ?? 2500.0;
    final progressPercentage = _dailyStats?.progressPercentage ?? 0.0;
    
    return Container(
      width: 280,
      height: 180,
      child: Stack(
        children: [
          // Background semicircle
          Center(
            child: Container(
              width: 240,
              height: 240,
              child: CustomPaint(
                painter: _SemiCircleProgressPainter(
                  progress: 1.0,
                  color: Colors.grey[200]!,
                  strokeWidth: 20,
                ),
              ),
            ),
          ),
          // Progress semicircle
          Center(
            child: Container(
              width: 240,
              height: 240,
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _SemiCircleProgressPainter(
                      progress: _progressAnimation.value,
                      color: _getProgressColor(_progressAnimation.value),
                      strokeWidth: 20,
                    ),
                  );
                },
              ),
            ),
          ),
          // Center content
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Icon(
                  Icons.water_drop,
                  size: 32,
                  color: _getProgressColor(progressPercentage / 100),
                ),
                const SizedBox(height: 8),
                Text(
                  '${currentIntake.toInt()}ml',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'od ${dailyGoal.toInt()}ml',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${progressPercentage.toInt()}% postignut cilj',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return Colors.red[400]!;
    if (progress < 0.7) return Colors.orange[400]!;
    if (progress < 1.0) return Colors.blue[400]!;
    return Colors.green[400]!;
  }

  Widget _buildQuickActions() {
    final quickAmounts = [250, 500, 750];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: quickAmounts.map((amount) {
        return _buildQuickActionButton(amount);
      }).toList(),
    );
  }

  Widget _buildQuickActionButton(int amount) {
    final isToday = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day) == 
                   DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    
    return InkWell(
      onTap: isToday ? () => _addWaterIntake(amount.toDouble()) : null,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: isToday ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            children: [
              Icon(Icons.water_drop_outlined, color: Colors.blue[600], size: 28),
              const SizedBox(height: 8),
              Text(
                '+${amount}ml',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildIntakeLog() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  '${_formatDate(_selectedDate)} unešeno',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_todayIntakes.length} unosa',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_todayIntakes.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.water_drop_outlined, 
                         size: 48, 
                         color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'Nema unosa za ovaj datum',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _todayIntakes.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final intake = _todayIntakes[index];
                return _buildIntakeItem(intake, index == 0);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildIntakeItem(WaterIntake intake, bool isLatest) {
    final isToday = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day) == 
                   DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    
    return Container(
      color: isLatest && isToday ? Colors.blue[25] : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getGlassColor(intake.amount),
                shape: BoxShape.circle,
              ),
              child: _getGlassIcon(intake.amount),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${intake.waterIntake}ml',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getGlassSize(intake.amount),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isLatest && isToday) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Najnovije',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${intake.timestamp.hour.toString().padLeft(2, '0')}:${intake.timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  _getTimeAgo(intake.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            if (isToday) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _deleteWaterIntake(intake),
                icon: const Icon(Icons.delete_outline),
                color: Colors.red[400],
                iconSize: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Sada';
    } else if (difference.inMinutes < 60) {
      return 'Prije ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Prije ${difference.inHours}h';
    } else {
      return 'Prije ${difference.inDays}d';
    }
  }

  Color _getGlassColor(double amount) {
    if (amount <= 200) return Colors.blue[100]!;
    if (amount <= 350) return Colors.blue[200]!;
    if (amount <= 500) return Colors.blue[300]!;
    if (amount <= 750) return Colors.blue[400]!;
    if (amount <= 1000) return Colors.blue[500]!;
    return Colors.blue[600]!;
  }

  Widget _getGlassIcon(double amount) {
    IconData iconData;
    Color iconColor = Colors.white;
    
    if (amount <= 200) {
      iconData = Icons.local_cafe;
      iconColor = Colors.blue[700]!;
    } else if (amount <= 350) {
      iconData = Icons.coffee_outlined;
      iconColor = Colors.blue[700]!;
    } else if (amount <= 500) {
      iconData = Icons.local_drink;
      iconColor = Colors.blue[700]!;
    } else if (amount <= 750) {
      iconData = Icons.sports_bar;
    } else if (amount <= 1000) {
      iconData = Icons.water_drop;
    } else {
      iconData = Icons.kitchen;
    }
    
    return Icon(iconData, color: iconColor, size: 22);
  }

  String _getGlassSize(double amount) {
    if (amount <= 200) return 'Mala čaša';
    if (amount <= 350) return 'Srednja čaša';
    if (amount <= 500) return 'Velika čaša';
    if (amount <= 750) return 'Boca';
    if (amount <= 1000) return 'Velika boca';
    return 'Posuda';
  }
}

// SemiCircle painter
class _SemiCircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _SemiCircleProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 60);
    final radius = (size.width / 2) - (strokeWidth / 2);
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = math.pi;
    final sweepAngle = math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _AddWaterModal extends StatefulWidget {
  final Function(double amount) onAddWater;
  final bool isLoading;

  const _AddWaterModal({
    required this.onAddWater,
    required this.isLoading,
  });

  @override
  State<_AddWaterModal> createState() => _AddWaterModalState();
}

class _AddWaterModalState extends State<_AddWaterModal> {
  double _selectedAmount = 250;
  
  final List<Map<String, dynamic>> _glassTypes = [
    {'amount': 150.0, 'name': 'Mala šalica', 'icon': Icons.local_cafe},
    {'amount': 250.0, 'name': 'Čaša', 'icon': Icons.local_drink},
    {'amount': 330.0, 'name': 'Veća čaša', 'icon': Icons.sports_bar},
    {'amount': 500.0, 'name': 'Boca', 'icon': Icons.water_drop},
    {'amount': 750.0, 'name': 'Sportska boca', 'icon': Icons.fitness_center},
    {'amount': 1000.0, 'name': 'Velika boca', 'icon': Icons.kitchen},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 24),
            const Text(
              'Dodaj unos vode',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.water_drop,
                size: 60,
                color: Colors.blue[600],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '${_selectedAmount.toInt()}ml',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 32),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: _glassTypes.length,
              itemBuilder: (context, index) {
                final glassType = _glassTypes[index];
                final amount = glassType['amount'] as double;
                final isSelected = _selectedAmount == amount;
                
                return GestureDetector(
                  onTap: widget.isLoading ? null : () => setState(() => _selectedAmount = amount),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey[200]!,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          glassType['icon'] as IconData,
                          color: isSelected ? Colors.white : Colors.grey[700],
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          glassType['name'] as String,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          '${amount.toInt()}ml',
                          style: TextStyle(
                            color: isSelected ? Colors.white70 : Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Colors.black),
                    ),
                    child: const Text(
                      'Otkaži',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.isLoading ? null : () {
                      widget.onAddWater(_selectedAmount);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: widget.isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Dodaj',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}