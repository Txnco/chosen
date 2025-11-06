import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chosen/controllers/user_controller.dart';
import 'package:chosen/controllers/auth_controller.dart';
import 'package:chosen/models/user.dart';
import 'package:chosen/providers/theme_provider.dart';
import 'package:chosen/providers/notification_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _userController = UserController();
  final _authController = AuthController();
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadUserData();
    if (!mounted) return;
    await _loadNotificationSettings();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _userController.getStoredUser();
      if (mounted) {
        setState(() {
          _user = user;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadNotificationSettings() async {
    if (!mounted) return;
    
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    await notificationProvider.loadSettings(user: _user);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String getUserInitials() {
    if (_user == null) return 'U';
    final first = _user!.firstName.isNotEmpty ? _user!.firstName[0] : '';
    final last = _user!.lastName.isNotEmpty ? _user!.lastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Svijetla';
      case ThemeMode.dark:
        return 'Tamna';
      case ThemeMode.system:
        return 'Sistemska';
    }
  }

  void _showThemeDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Odaberite temu',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Svijetla'),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                themeProvider.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Tamna'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                themeProvider.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Sistemska'),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                themeProvider.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Postavke obavještenja',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        content: SingleChildScrollView(
          child: Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNotificationToggle(
                    title: 'Planiranje dana',
                    subtitle: 'Podsjetnik za planiranje sljedećeg dana',
                    value: provider.dailyPlanning,
                    onChanged: (value) => provider.setDailyPlanning(value),
                  ),
                  const SizedBox(height: 8),
                  _buildNotificationToggle(
                    title: 'Ocjena dana',
                    subtitle: 'Večernji podsjetnik za ocjenjivanje dana',
                    value: provider.dayRating,
                    onChanged: (value) => provider.setDayRating(value),
                  ),
                  const SizedBox(height: 8),
                  _buildNotificationToggle(
                    title: 'Fotografije napretka',
                    subtitle: 'Tjedni podsjetnik za fotografije',
                    value: provider.progressPhoto,
                    onChanged: (value) => provider.setProgressPhoto(value),
                  ),
                  const SizedBox(height: 8),
                  _buildNotificationToggle(
                    title: 'Vaganje',
                    subtitle: 'Tjedni podsjetnik za vaganje',
                    value: provider.weight,
                    onChanged: (value) => provider.setWeight(value),
                  ),
                  const SizedBox(height: 8),
                  _buildNotificationToggle(
                    title: 'Unos vode',
                    subtitle: 'Podsjetnici za piće vode',
                    value: provider.water,
                    onChanged: (value) => provider.setWater(value),
                  ),
                  const SizedBox(height: 8),
                  _buildNotificationToggle(
                    title: 'Rođendan',
                    subtitle: 'Čestitka na rođendan',
                    value: provider.birthday,
                    onChanged: (value) => provider.setBirthday(value, _user),
                  ),
                  
                  // Error message display
                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              provider.errorMessage!,
                              style: TextStyle(
                                color: Colors.red[900],
                                fontSize: 12,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, size: 16, color: Colors.red[700]),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => provider.clearError(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Clear any errors before closing
              final provider = Provider.of<NotificationProvider>(context, listen: false);
              provider.clearError();
              Navigator.pop(dialogContext);
            },
            child: const Text('Zatvori'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle({
    required String title,
    required String subtitle,
    required bool value,
    required Future<bool> Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) => onChanged(newValue),
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Odjava',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        content: const Text(
          'Jeste li sigurni da se želite odjaviti?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Odustani',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Odjavi se',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );

      try {
        await _authController.logout();
        if (mounted) {
          Navigator.pop(context);
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Greška pri odjavi: ${e.toString()}'),
              backgroundColor: Colors.red[600],
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Postavke',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildProfileSection(),
                    const SizedBox(height: 20),
                    _buildSettingsSection(themeProvider),
                    const SizedBox(height: 20),
                    _buildLogoutSection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildAvatar(),
            const SizedBox(height: 16),
            Text(
              _user != null
                  ? '${_user!.firstName} ${_user!.lastName}'.trim()
                  : 'Unknown User',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _user?.email ?? 'No email',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Uređivanje profila će biti dostupno uskoro'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                child: Text(
                  'Uredi profil',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
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

  Widget _buildAvatar() {
    final profilePictureUrl = _userController.getProfilePictureUrl(_user?.profilePicture);
    final hasAvatar = profilePictureUrl != null;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 3,
        ),
      ),
      child: ClipOval(
        child: hasAvatar
            ? Image.network(
                profilePictureUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildInitialsAvatar();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  );
                },
              )
            : _buildInitialsAvatar(),
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      child: Center(
        child: Text(
          getUserInitials(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(ThemeProvider themeProvider) {
    return Card(
      child: Column(
        children: [
          _buildSettingsItem(
            icon: Icons.brightness_6_outlined,
            title: 'Izgled',
            subtitle: _getThemeModeName(themeProvider.themeMode),
            onTap: () => _showThemeDialog(themeProvider),
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: Icons.notifications_outlined,
            title: 'Obavještenja',
            subtitle: 'Upravljanje obavještenjima',
            onTap: () => _showNotificationsDialog(),
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: Icons.security_outlined,
            title: 'Sigurnost',
            subtitle: 'Promjena lozinke i sigurnost',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sigurnosne postavke će biti dostupne uskoro'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: Icons.language_outlined,
            title: 'Jezik',
            subtitle: 'Hrvatski',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Izbor jezika će biti dostupan uskoro'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: Icons.help_outline,
            title: 'Pomoć i podrška',
            subtitle: 'FAQ i kontakt',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pomoć će biti dostupna uskoro'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: Icons.info_outline,
            title: 'O aplikaciji',
            subtitle: 'Verzija 1.0.0',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'CHOSEN',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2024 CHOSEN. Sva prava zadržana.',
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'CHOSEN je vaš personalizirani vodič za zdravlje i fitness.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              );
            },
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: Icons.info_outline,
            title: 'NOTIFIKACIJE',
            subtitle: 'DEBUG',
            onTap: () => Navigator.pushNamed(context, '/notification-test'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.logout_outlined,
            size: 48,
            color: Colors.red[600],
          ),
          const SizedBox(height: 12),
          Text(
            'Odjava',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Odjavit ćete se iz aplikacije',
            style: TextStyle(
              fontSize: 14,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Odjavi se',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).iconTheme.color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: Theme.of(context).dividerColor,
    );
  }
}