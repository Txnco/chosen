import 'package:flutter/material.dart';
import 'package:chosen/controllers/user_controller.dart';
import 'package:chosen/controllers/water_controller.dart';
import 'package:chosen/models/user.dart';
import 'package:chosen/models/water_intake.dart';
import 'package:chosen/managers/questionnaire_manager.dart';

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
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeDashboard();
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
      
      // If questionnaire is completed, load user data and water stats
      await _loadUser();
      await _loadWaterStats();
      
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
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 70,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home_outlined, true, () {
            // Already on dashboard, do nothing or refresh water stats
            _loadWaterStats();
          }),
          _buildNavItem(Icons.fitness_center_outlined, false, () {
            // TODO: Navigate to workout/fitness screen
          }),
          _buildNavItem(Icons.chat_outlined, false, () {
            // Navigate to messaging screen
            Navigator.pushNamed(context, '/messaging');
          }),
          _buildNavItem(Icons.settings_outlined, false, () {
            Navigator.pushNamed(context, '/settings');
          }),
        ],
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
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/profile');
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
          child: Text(
            getUserInitials(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
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
            '5 tasks',
            onTap: () {
              // TODO: Navigate to daily plan
            },
          ),
          _buildDashboardCard(
            'Motivacija dana', 
            Icons.bolt_outlined, 
            'Samo nastavi!',
            onTap: () {
              // TODO: Navigate to motivation
            },
          ),
          _buildWaterCard(),
          _buildDashboardCard(
            'Trening', 
            Icons.fitness_center_outlined, 
            '45 min',
            onTap: () {
              // TODO: Navigate to workout
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