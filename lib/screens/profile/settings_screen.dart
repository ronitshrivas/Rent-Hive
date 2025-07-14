import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _smsNotifications = true;
  bool _locationServices = true;
  bool _darkMode = false;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notifications Section
            _buildSection(
              'Notifications',
              [
                _buildSwitchTile(
                  'Push Notifications',
                  'Receive push notifications on your device',
                  Icons.notifications_outlined,
                  _pushNotifications,
                  (value) => setState(() => _pushNotifications = value),
                ),
                _buildSwitchTile(
                  'Email Notifications',
                  'Receive notifications via email',
                  Icons.email_outlined,
                  _emailNotifications,
                  (value) => setState(() => _emailNotifications = value),
                ),
                _buildSwitchTile(
                  'SMS Notifications',
                  'Receive notifications via SMS',
                  Icons.sms_outlined,
                  _smsNotifications,
                  (value) => setState(() => _smsNotifications = value),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Privacy & Security Section
            _buildSection(
              'Privacy & Security',
              [
                _buildSwitchTile(
                  'Location Services',
                  'Allow app to access your location',
                  Icons.location_on_outlined,
                  _locationServices,
                  (value) => setState(() => _locationServices = value),
                ),
                _buildNavigationTile(
                  'Privacy Policy',
                  'Read our privacy policy',
                  Icons.privacy_tip_outlined,
                  () => _showPrivacyPolicy(),
                ),
                _buildNavigationTile(
                  'Terms of Service',
                  'Read terms and conditions',
                  Icons.description_outlined,
                  () => _showTermsOfService(),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // App Preferences Section
            _buildSection(
              'App Preferences',
              [
                _buildSwitchTile(
                  'Dark Mode',
                  'Enable dark theme',
                  Icons.dark_mode_outlined,
                  _darkMode,
                  (value) => setState(() => _darkMode = value),
                ),
                _buildDropdownTile(
                  'Language',
                  'Choose your preferred language',
                  Icons.language_outlined,
                  _language,
                  ['English', 'Nepali', 'Hindi'],
                  (value) => setState(() => _language = value!),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Support Section
            _buildSection(
              'Support',
              [
                _buildNavigationTile(
                  'Help Center',
                  'Get help and support',
                  Icons.help_outline,
                  () => _openHelpCenter(),
                ),
                _buildNavigationTile(
                  'Contact Us',
                  'Get in touch with our team',
                  Icons.contact_support_outlined,
                  () => _contactSupport(),
                ),
                _buildNavigationTile(
                  'Report a Bug',
                  'Report issues or bugs',
                  Icons.bug_report_outlined,
                  () => _reportBug(),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // About Section
            _buildSection(
              'About',
              [
                _buildNavigationTile(
                  'App Version',
                  'Version 1.0.0',
                  Icons.info_outline,
                  null,
                ),
                _buildNavigationTile(
                  'Rate App',
                  'Rate us on the app store',
                  Icons.star_outline,
                  () => _rateApp(),
                ),
                _buildNavigationTile(
                  'Share App',
                  'Share with friends and family',
                  Icons.share_outlined,
                  () => _shareApp(),
                ),
              ],
            ),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: 16),
        
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children.map((child) {
              int index = children.indexOf(child);
              return Column(
                children: [
                  child,
                  if (index < children.length - 1)
                    const Divider(height: 1, color: AppColors.borderColor),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppColors.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryColor,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildNavigationTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppColors.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: onTap != null
          ? const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.textLight,
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    IconData icon,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppColors.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        underline: const SizedBox(),
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(
              option,
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'At Rent Hive, we value your privacy and are committed to protecting your personal information. This Privacy Policy explains how we collect, use, and safeguard your data when you use our app.\n\n'
            'Information We Collect:\n'
            '• Personal information (name, email, phone)\n'
            '• Location data for property search\n'
            '• Property listings and preferences\n'
            '• Communication data\n\n'
            'How We Use Your Information:\n'
            '• Provide and improve our services\n'
            '• Connect you with property owners/seekers\n'
            '• Send relevant notifications\n'
            '• Ensure app security and prevent fraud\n\n'
            'Your Rights:\n'
            '• Access your personal data\n'
            '• Update or correct information\n'
            '• Request data deletion\n'
            '• Opt-out of communications',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Terms of Service',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'Welcome to Rent Hive. By using our app, you agree to these terms:\n\n'
            '1. Account Responsibility:\n'
            '• You are responsible for your account security\n'
            '• Provide accurate and complete information\n'
            '• Notify us of any unauthorized use\n\n'
            '2. Property Listings:\n'
            '• Property owners must provide accurate information\n'
            '• No false or misleading listings\n'
            '• Comply with local laws and regulations\n\n'
            '3. User Conduct:\n'
            '• Respectful communication with other users\n'
            '• No spam, harassment, or inappropriate content\n'
            '• Report any violations to our support team\n\n'
            '4. Limitation of Liability:\n'
            '• We facilitate connections between users\n'
            '• Not responsible for property conditions\n'
            '• Users enter agreements at their own risk',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openHelpCenter() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening Help Center...'),
      ),
    );
  }

  void _contactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Contact Support',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Get in touch with our support team:'),
            const SizedBox(height: 16),
            _buildContactRow(
              'Email',
              'support@renthive.com',
              Icons.email_outlined,
            ),
            _buildContactRow(
              'Phone',
              '+977-1-4567890',
              Icons.phone_outlined,
            ),
            _buildContactRow(
              'WhatsApp',
              '+977-9876543210',
              Icons.chat_outlined,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.primaryColor,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _reportBug() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Report a Bug',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Found a bug or issue? We\'d love to hear about it!\n\n'
          'Please email us at bugs@renthive.com with:\n'
          '• Description of the issue\n'
          '• Steps to reproduce\n'
          '• Screenshots (if applicable)\n'
          '• Your device information\n\n'
          'Our team will investigate and fix the issue as soon as possible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Open email client
            },
            child: const Text('Send Email'),
          ),
        ],
      ),
    );
  }

  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening App Store...'),
      ),
    );
  }

  void _shareApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality will be implemented'),
      ),
    );
  }
}