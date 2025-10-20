// dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chosen/controllers/user_controller.dart';
import 'package:chosen/controllers/water_controller.dart';
import 'package:chosen/models/user.dart';
import 'package:chosen/models/water_intake.dart';
import 'package:chosen/models/weight_tracking.dart';
import 'package:chosen/controllers/tracking_controller.dart';
import 'package:chosen/managers/questionnaire_manager.dart';
import 'package:fl_chart/fl_chart.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> 
    with WidgetsBindingObserver {
  final _userController = UserController();
  UserModel? _user;
  bool _isLoading = true;
  WaterDailyStats? _waterStats;
  bool _isLoadingWater = false;
  bool _isLoadingWeight = false;
  bool _hasInitialized = false;
   List<WeightTracking> _weightHistory = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeDashboard();
    _loadWeightData();
  }

  Future<void> _loadWeightData() async {
    try {
        final weightHistory = await TrackingController.getWeightTracking();
        if (mounted) {
          setState(() {
            _weightHistory = weightHistory;
            _isLoadingWeight = false;
          });
        }
      } catch (e) {
        print('Error loading weight data: $e');
        if (mounted) {
          setState(() => _isLoadingWeight = false);
        }
      }
    }

  Future<void> _initializeDashboard() async {
    try {
      // First check if questionnaire is completed
      final isQuestionnaireCompleted = await QuestionnaireManager.isQuestionnaireCompleted();
      
      if (!isQuestionnaireCompleted && mounted) {
        // If questionnaire is not completed, redirect to questionnaire screen
        Navigator.pushReplacementNamed(context, '/questionnaire');
        return;
      }
      
      await Future.wait([
        _loadUser(),
        _loadWaterStats(),
        _loadWeightData(),  // Include weight data in initialization
      ]);
      
      _hasInitialized = true;
    } catch (e) {
      print('Dashboard initialization error: $e');
      // On error, redirect to login
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed && _hasInitialized) {
      // Refresh water stats when app comes to foreground
      _loadWaterStats();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadUser() async {
    await _userController.getCurrentUser();
    final user = await _userController.getStoredUser();
    setState(() {
      _user = user;
    });
    if(_user == null) {
      // If user is null, redirect to login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _loadWaterStats() async {
    try {
      setState(() {
        _isLoadingWater = true;
      });
      
      // Ensure user has a water goal
      await WaterController.ensureUserHasWaterGoal();
      
      // Get today's water stats
      final stats = await WaterController.getTodayWaterStats();
      
      setState(() {
        _waterStats = stats;
        _isLoadingWater = false;
      });
    } catch (e) {
      print('Error loading water stats: $e');
      setState(() {
        _isLoadingWater = false;
      });
    }
  }

  String getUserInitials() {
    if (_user == null) return 'ER';
    final first = _user!.firstName.isNotEmpty ? _user!.firstName[0] : '';
    final last = _user!.lastName.isNotEmpty ? _user!.lastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  String getWelcomeMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Dobro jutro';
    if (hour < 17) return 'Dobar dan';
    return 'Dobra večer';
  }

  String getUserName() {
    if (_user == null) return 'User';
    return _user!.firstName.isNotEmpty ? _user!.firstName : 'User';
  }

  Future<void> _refreshDashboard() async {
    setState(() => _isLoading = true);
    await _initializeDashboard();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking questionnaire status
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.black,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomNavBar(),
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        color: Colors.black,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildTopBar(),
                _buildWelcomeSection(),
                _buildDashboardGrid(),
                if (_isLoadingWeight)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                  )
                else
                  _buildWeightChart(), // now it actually renders
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

    Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(Icons.home_outlined, true, () {
                _loadWaterStats();
              }),
              _buildNavItem(Icons.chat_outlined, false, () {
                Navigator.pushNamed(context, '/messaging');
              }),
              _buildNavItem(Icons.settings_outlined, false, () {
                Navigator.pushNamed(context, '/settings');
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Icon(
          icon,
          color: isActive ? Colors.black : Colors.grey[400],
          size: 24,
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          const Text(
            'CHOSEN',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          _buildProfileMenu(),
        ],
      ),
    );
  }

  Widget _buildProfileMenu() {
  final profilePictureUrl = _user?.profilePicture != null
      ? _userController.getProfilePictureUrl(_user!.profilePicture)
      : null;

  return GestureDetector(
    onTap: () async {
      await Navigator.pushNamed(context, '/profile');
      // Refresh user data when returning from profile
      if (mounted && _hasInitialized) {
        _loadUser();
      }
    },
    child: Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[300]!, width: 2),
      ),
      child: CircleAvatar(
        backgroundColor: Colors.black,
        radius: 22,
        backgroundImage: profilePictureUrl != null
            ? NetworkImage(profilePictureUrl)
            : null,
        child: profilePictureUrl == null
            ? Text(
                getUserInitials(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              )
            : null,
      ),
    ),
  );
}

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${getWelcomeMessage()}, ${getUserName()}!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w300,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Jesi li spreman danas srušiti svoje ciljeve?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
        children: [
          _buildDashboardCard(
            'Dnevni plan', 
            Icons.today_outlined, 
            'Kreni i planiraj svoj dan!',
            onTap: () {
              Navigator.pushNamed(context, '/events');
            },
          ),
          _buildDashboardCard(
            'Prehrana', 
            Icons.food_bank, 
            'Jedi pravilno!',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Opcija dolazi uskoro!'),
                  backgroundColor: Colors.blue[600],
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          _buildWaterCard(),
          _buildDashboardCard(
            'Trening', 
            Icons.fitness_center_outlined,
            'Napravi trening!',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Opcija dolazi uskoro!'),
                  backgroundColor: Colors.blue[600],
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(String title, IconData icon, String subtitle, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32, color: Colors.black),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

 Widget _buildWeightChart() {
    if (_weightHistory.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.monitor_weight_outlined, color: Colors.grey[400], size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Još nema unosa težine.\nDodaj prvi unos da vidiš graf.',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    // Sort by date (oldest first for chart display)
    final sortedHistory = List<WeightTracking>.from(_weightHistory)
      ..sort((a, b) {
        final dateA = a.date ?? a.createdAt;
        final dateB = b.date ?? b.createdAt;
        return dateA.compareTo(dateB);
      });

    final chartData = sortedHistory.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight);
    }).toList();

    final weights = sortedHistory.map((e) => e.weight).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b) - 5;
    final maxWeight = weights.reduce((a, b) => a > b ? a : b) + 5;

    return Container(
      margin: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progres težine',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await Navigator.pushNamed(context, '/weight-tracking');
                  if (mounted && _hasInitialized) {
                    _loadWeightData();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Prikaži sve',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      interval: sortedHistory.length > 5 ? (sortedHistory.length / 3).floorToDouble() : 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < sortedHistory.length) {
                          final date = sortedHistory[index].date ?? sortedHistory[index].createdAt;
                          return Text(
                            '${date.day}/${date.month}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 9,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: Colors.grey[300]!),
                    bottom: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                minX: 0,
                maxX: (sortedHistory.length - 1).toDouble(),
                minY: minWeight,
                maxY: maxWeight,
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData,
                    isCurved: true,
                    color: Colors.black,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: Colors.black,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.black.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterCard() {
    final currentIntake = _waterStats?.totalIntake ?? 0.0;
    final dailyGoal = _waterStats?.goalAmount ?? 2500.0;
    final progress = dailyGoal > 0 ? (currentIntake / dailyGoal) : 0.0;
    
    return InkWell(
      onTap: () async {
        // Navigate to water tracking and refresh when returning
        await Navigator.pushNamed(context, '/water-tracking');
        // Refresh water stats when returning from water tracking screen
        if (mounted && _hasInitialized) {
          _loadWaterStats();
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.water_drop_outlined, size: 32, color: Colors.black),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showQuickAddWater(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Text(
                'Unos vode',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              if (_isLoadingWater)
                Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                )
              else
                Row(
                  children: [
                    Text(
                      '${currentIntake.toInt()}ml',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[600],
                      ),
                    ),
                    Text(
                      ' / ${dailyGoal.toInt()}ml',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              // Mini progress bar
              if (!_isLoadingWater)
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: progress < 0.5 ? Colors.orange[400] : Colors.blue[600],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickAddWater() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _QuickAddWaterModal(
        onAddWater: _addWaterFromDashboard,
        onNavigateToWaterTracking: _navigateToWaterTracking,
        isLoading: _isLoadingWater,
      ),
    );
  }

  Future<void> _navigateToWaterTracking() async {
    Navigator.pop(context); // Close modal first
    await Navigator.pushNamed(context, '/water-tracking');
    // Refresh water stats when returning from water tracking screen
    if (mounted && _hasInitialized) {
      _loadWaterStats();
    }
  }

  Future<void> _addWaterFromDashboard(double amount) async {
    setState(() {
      _isLoadingWater = true;
    });

    try {
      final newIntake = await WaterController.addWaterIntake(amount.toInt());
      
      if (newIntake != null) {
        // Reload water stats immediately
        await _loadWaterStats();
        
        if (mounted) {
          // Close modal
          Navigator.of(context).pop();
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Dodano ${amount.toInt()}ml vode!'),
              backgroundColor: Colors.blue[600],
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Greška pri dodavanju vode. Pokušajte ponovo.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error adding water from dashboard: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingWater = false;
      });
    }
  }
}



// Quick Add Weight Modal
class _QuickAddWeightModal extends StatefulWidget {
  final Function(double weight) onAddWeight;
  final VoidCallback onNavigateToWeightTracking;
  final bool isLoading;

  const _QuickAddWeightModal({
    required this.onAddWeight,
    required this.onNavigateToWeightTracking,
    required this.isLoading,
  });

  @override
  State<_QuickAddWeightModal> createState() => _QuickAddWeightModalState();
}

class _QuickAddWeightModalState extends State<_QuickAddWeightModal> {
  final TextEditingController _weightController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
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
            Icon(
              Icons.monitor_weight,
              size: 60,
              color: Colors.green[600],
            ),
            const SizedBox(height: 16),
            const Text(
              'Brzi unos težine',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Težina (kg)',
                hintText: 'Unesite svoju težinu',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixText: 'kg',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
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
                if (picked != null && picked != _selectedDate) {
                  setState(() {
                    _selectedDate = picked;
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
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
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
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.isLoading ? null : widget.onNavigateToWeightTracking,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Colors.black),
                    ),
                    child: const Text(
                      'Detaljni prikaz',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.isLoading ? null : () {
                      final weight = double.tryParse(_weightController.text);
                      if (weight != null && weight > 0) {
                        widget.onAddWeight(weight);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Molimo unesite validnu težinu'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
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
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Spremi',
                            style: TextStyle(
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

class _QuickAddWaterModal extends StatelessWidget {
  final Function(double amount) onAddWater;
  final VoidCallback onNavigateToWaterTracking;
  final bool isLoading;

  const _QuickAddWaterModal({
    required this.onAddWater,
    required this.onNavigateToWaterTracking,
    required this.isLoading,
  });

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
            Icon(
              Icons.water_drop,
              size: 60,
              color: Colors.blue[600],
            ),
            const SizedBox(height: 16),
            const Text(
              'Brzi unos vode',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickButton(context, 250),
                _buildQuickButton(context, 500),
                _buildQuickButton(context, 750),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: isLoading ? null : onNavigateToWaterTracking,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Colors.black),
                ),
                child: const Text(
                  'Otvori detaljni prikaz',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickButton(BuildContext context, int amount) {
    return GestureDetector(
      onTap: isLoading ? null : () {
        onAddWater(amount.toDouble());
      },
      child: Opacity(
        opacity: isLoading ? 0.5 : 1.0,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading && amount == 250)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              else
                Icon(Icons.water_drop_outlined, color: Colors.blue[600], size: 24),
              const SizedBox(height: 4),
              Text(
                '${amount}ml',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}