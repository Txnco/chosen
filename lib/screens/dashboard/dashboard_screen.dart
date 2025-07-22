import 'package:flutter/material.dart';
import 'package:chosen/controllers/user_controller.dart';
import 'package:chosen/controllers/auth_controller.dart';
import 'package:chosen/models/user.dart';
import 'package:chosen/utils/questionnaire_manager.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  final _userController = UserController();
  final _authController = AuthController();
  UserModel? _user;
  bool _isLoading = true;

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
      
      // If questionnaire is completed, load user data
      await _loadUser();
    } catch (e) {
      print('Error initializing dashboard: $e');
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
    
    if (state == AppLifecycleState.resumed) {
      // Recheck questionnaire status when app comes to foreground
      _initializeDashboard();
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
                  child: _buildTodaysFoodSection(),
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
          _buildNavItem(Icons.home_outlined, true),
          _buildNavItem(Icons.fitness_center_outlined, false),
          _buildNavItem(Icons.local_drink_outlined, false),
          _buildNavItem(Icons.settings_outlined, false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Icon(
        icon,
        color: isActive ? Colors.black : Colors.grey[400],
        size: 24,
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
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.black12),
          ),
          elevation: 8,
        ),
      ),
      child: PopupMenuButton<String>(
        onSelected: (value) async {
          if (value == 'logout') {
            await _authController.logout();
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'profile',
            child: Row(
              children: [
                Icon(Icons.person_outline, color: Colors.grey[600], size: 18),
                const SizedBox(width: 12),
                const Text('Profile', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
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
          _buildDashboardCard('Dnevni plan', Icons.today_outlined, '5 tasks'),
          _buildDashboardCard('Motivacija dana', Icons.bolt_outlined, 'Samo nastavi!'),
          _buildDashboardCard('Unos vode', Icons.water_drop_outlined, '1.2L / 2.5L'),
          _buildDashboardCard('Trening', Icons.fitness_center_outlined, '45 min'),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(String title, IconData icon, String subtitle) {
    return Container(
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
    );
  }

  Widget _buildTodaysFoodSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              const Text(
                'Današnja jela',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Text(
                '1,247 kcal',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: const [
              _ModernFoodCard(
                emoji: '🍳',
                title: 'Breakfast',
                description: 'Oatmeal & banana',
                calories: '320 kcal',
                time: '8:00 AM',
              ),
              _ModernFoodCard(
                emoji: '🥛',
                title: 'Snack',
                description: 'Greek yogurt',
                calories: '150 kcal',
                time: '10:30 AM',
              ),
              _ModernFoodCard(
                emoji: '🍗',
                title: 'Lunch',
                description: 'Chicken & rice',
                calories: '450 kcal',
                time: '12:30 PM',
              ),
              _ModernFoodCard(
                emoji: '🍣',
                title: 'Dinner',
                description: 'Salmon & veggies',
                calories: '327 kcal',
                time: '7:00 PM',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModernFoodCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final String calories;
  final String time;

  const _ModernFoodCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.calories,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$calories • $time',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }
}