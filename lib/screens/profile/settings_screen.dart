import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:renthive/services/location_services.dart';
import 'package:renthive/services/notification_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/loading_overlay.dart';

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? false;
      _smsNotifications = prefs.getBool('sms_notifications') ?? true;
      _locationServices = prefs.getBool('location_services') ?? true;
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _language = prefs.getString('language') ?? 'English';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notifications Section
              _buildSection('Notifications', [
                _buildSwitchTile(
                  'Push Notifications',
                  'Receive push notifications on your device',
                  Icons.notifications_outlined,
                  _pushNotifications,
                  (value) async {
                    setState(() => _pushNotifications = value);
                    await _saveSetting('push_notifications', value);

                    if (value) {
                      final enabled =
                          await NotificationService().requestPermission();
                      if (!enabled && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enable notifications in settings',
                            ),
                          ),
                        );
                        setState(() => _pushNotifications = false);
                      }
                    }
                  },
                ),
                _buildSwitchTile(
                  'Email Notifications',
                  'Receive notifications via email',
                  Icons.email_outlined,
                  _emailNotifications,
                  (value) async {
                    setState(() => _emailNotifications = value);
                    await _saveSetting('email_notifications', value);
                  },
                ),
                _buildSwitchTile(
                  'SMS Notifications',
                  'Receive notifications via SMS',
                  Icons.sms_outlined,
                  _smsNotifications,
                  (value) async {
                    setState(() => _smsNotifications = value);
                    await _saveSetting('sms_notifications', value);
                  },
                ),
              ]),

              const SizedBox(height: 24),

              // Privacy & Security Section
              _buildSection('Privacy & Security', [
                _buildSwitchTile(
                  'Location Services',
                  'Allow app to access your location',
                  Icons.location_on_outlined,
                  _locationServices,
                  (value) async {
                    if (value) {
                      final hasPermission =
                          await LocationService().getCurrentLocation() != null;
                      if (!hasPermission && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enable location in settings'),
                          ),
                        );
                        return;
                      }
                    }
                    setState(() => _locationServices = value);
                    await _saveSetting('location_services', value);
                  },
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
                _buildNavigationTile(
                  'Data & Storage',
                  'Manage your data and storage',
                  Icons.storage_outlined,
                  () => _showDataStorageDialog(),
                ),
              ]),

              const SizedBox(height: 24),

              // App Preferences Section
              _buildSection('App Preferences', [
                _buildSwitchTile(
                  'Dark Mode',
                  'Enable dark theme',
                  Icons.dark_mode_outlined,
                  _darkMode,
                  (value) async {
                    setState(() => _darkMode = value);
                    await _saveSetting('dark_mode', value);
                    _showComingSoonSnackBar('Dark mode');
                  },
                ),
                _buildDropdownTile(
                  'Language',
                  'Choose your preferred language',
                  Icons.language_outlined,
                  _language,
                  ['English', 'Nepali', 'Hindi'],
                  (value) async {
                    setState(() => _language = value!);
                    await _saveSetting('language', value);
                    _showComingSoonSnackBar('Multi-language support');
                  },
                ),
              ]),

              const SizedBox(height: 24),

              // Support Section
              _buildSection('Support', [
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
                _buildNavigationTile(
                  'FAQ',
                  'Frequently asked questions',
                  Icons.question_answer_outlined,
                  () => _showFAQ(),
                ),
              ]),

              const SizedBox(height: 24),

              // About Section
              _buildSection('About', [
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
                _buildNavigationTile(
                  'Check for Updates',
                  'See if updates are available',
                  Icons.system_update_outlined,
                  () => _checkForUpdates(),
                ),
              ]),

              const SizedBox(height: 24),

              // Danger Zone
              _buildSection('Danger Zone', [
                _buildNavigationTile(
                  'Clear Cache',
                  'Free up space by clearing cache',
                  Icons.cleaning_services_outlined,
                  () => _clearCache(),
                ),
                _buildNavigationTile(
                  'Delete Account',
                  'Permanently delete your account',
                  Icons.delete_forever_outlined,
                  () => _showDeleteAccountDialog(),
                  isDestructive: true,
                ),
              ]),

              const SizedBox(height: 40),
            ],
          ),
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
            children:
                children.map((child) {
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
        child: Icon(icon, color: AppColors.primaryColor, size: 20),
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
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
    VoidCallback? onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDestructive ? AppColors.errorColor : AppColors.primaryColor)
              .withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDestructive ? AppColors.errorColor : AppColors.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? AppColors.errorColor : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing:
          onTap != null
              ? Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color:
                    isDestructive ? AppColors.errorColor : AppColors.textLight,
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
        child: Icon(icon, color: AppColors.primaryColor, size: 20),
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
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        underline: const SizedBox(),
        items:
            options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  // Add these methods to SettingsScreen class

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 600),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Privacy Policy',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: const Text('''Last updated: January 2026

Rent Hive ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information.

1. Information We Collect

a) Personal Information:
   • Name, email address, phone number
   • Profile photo
   • Identification documents (for verification)
   • Location data

b) Property Information:
   • Property details and photos
   • Rental information
   • Virtual tour images

c) Usage Information:
   • App usage patterns
   • Device information
   • IP address
   • Cookies and similar technologies

2. How We Use Your Information

We use collected information for:
   • Providing and maintaining our services
   • Processing transactions
   • Sending notifications about properties
   • Improving user experience
   • Preventing fraud and ensuring security
   • Complying with legal obligations

3. Information Sharing

We may share your information with:
   • Other users (property owners/seekers)
   • Service providers
   • Legal authorities when required
   
We do NOT sell your personal information.

4. Data Security

We implement appropriate security measures including:
   • Encryption of sensitive data
   • Secure servers
   • Regular security audits
   • Access controls

5. Your Rights

You have the right to:
   • Access your personal data
   • Correct inaccurate data
   • Delete your account
   • Opt-out of communications
   • Data portability

6. Children's Privacy

Our service is not intended for users under 18 years of age.

7. Changes to Privacy Policy

We may update this policy periodically. Continued use constitutes acceptance of changes.

8. Contact Us

For privacy concerns, contact:
Email: privacy@renthive.com
Phone: +977-1-4567890
                    ''', style: TextStyle(fontSize: 14, height: 1.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 600),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Terms of Service',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: const Text('''Last updated: January 2026

By accessing Rent Hive, you agree to these Terms of Service.

1. Account Registration
   • Must be 18 years or older
   • Provide accurate information
   • Maintain account security
   • One account per person

2. User Responsibilities

For Property Owners:
   • Provide accurate property information
   • Maintain property as described
   • Respond to inquiries promptly
   • Comply with local rental laws
   • Provide necessary documentation

For Room Seekers:
   • Communicate honestly
   • Respect property viewings
   • Honor agreements made
   • Provide required verification

3. Prohibited Activities
   • Fraudulent listings
   • Discrimination
   • Harassment
   • Spam or unauthorized marketing
   • Illegal activities
   • Misuse of platform

4. Property Listings
   • Must be accurate and current
   • Photos must represent actual property
   • Pricing must be clear
   • Availability must be updated
   • Remove listing when unavailable

5. Payments and Fees
   • Platform may charge service fees
   • All payments through approved methods
   • Refund policy as stated
   • Users responsible for taxes

6. Verification Process
   • Required documents must be genuine
   • Verification does not guarantee safety
   • We reserve right to verify information
   • False documents lead to account termination

7. Privacy and Data
   • Your data handled per Privacy Policy
   • Share only necessary information
   • Report privacy violations

8. Intellectual Property
   • Users retain rights to their content
   • Grant us license to use content
   • Respect others' intellectual property

9. Limitation of Liability
   • Platform is a marketplace
   • Not party to rental agreements
   • Not responsible for property conditions
   • Not liable for user disputes
   • Users interact at own risk

10. Dispute Resolution
   • Good faith negotiation first
   • Mediation if needed
   • Arbitration clause
   • Governing law applies

11. Termination
   We may terminate accounts for:
   • Terms violation
   • Fraudulent activity
   • Illegal use
   • Prolonged inactivity

12. Changes to Terms
   • We may modify terms
   • Notice of significant changes
   • Continued use = acceptance

13. Contact
For questions about terms:
Email: legal@renthive.com
Phone: +977-1-4567890
                    ''', style: TextStyle(fontSize: 14, height: 1.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showDataStorageDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Data & Storage'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Manage your data and storage'),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(
                    Icons.download_outlined,
                    color: AppColors.primaryColor,
                  ),
                  title: const Text('Download Your Data'),
                  subtitle: const Text('Export all your data'),
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoonSnackBar('Data export');
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.storage_outlined,
                    color: AppColors.infoColor,
                  ),
                  title: const Text('Storage Usage'),
                  subtitle: const Text('View storage details'),
                  onTap: () {
                    Navigator.pop(context);
                    _showStorageUsage();
                  },
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

  void _showStorageUsage() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Storage Usage'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStorageItem('Profile Photos', '2.5 MB'),
                _buildStorageItem('Property Images', '45.3 MB'),
                _buildStorageItem('Cache', '12.8 MB'),
                _buildStorageItem('Messages', '5.2 MB'),
                const Divider(),
                _buildStorageItem('Total', '65.8 MB', isBold: true),
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

  Widget _buildStorageItem(String label, String size, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            size,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _openHelpCenter() {
    // Navigate to help screen or show help dialog
    _showComingSoonSnackBar('Help Center');
  }

  void _contactSupport() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Contact Support'),
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
          Icon(icon, size: 16, color: AppColors.primaryColor),
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
    _showComingSoonSnackBar('Bug reporting');
  }

  void _showFAQ() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 600),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'FAQ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildFAQItem(
                          'How do I list a property?',
                          'Go to Dashboard > Add Property and fill in the details.',
                        ),
                        _buildFAQItem(
                          'Is verification mandatory?',
                          'Yes, we require verification for safety and trust.',
                        ),
                        _buildFAQItem(
                          'How do I contact property owners?',
                          'Use the message button on the property details page.',
                        ),
                        _buildFAQItem(
                          'Can I edit my listing?',
                          'Yes, go to My Properties and tap edit.',
                        ),
                        _buildFAQItem(
                          'What if I face issues?',
                          'Contact our support team anytime.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            answer,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  void _rateApp() {
    _showComingSoonSnackBar('App rating');
  }

  void _shareApp() {
    _showComingSoonSnackBar('App sharing');
  }

  void _checkForUpdates() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Check for Updates'),
            content: const Text('You are using the latest version (1.0.0)'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<void> _clearCache() async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Clear Cache?'),
            content: const Text(
              'This will free up space but may slow down the app temporarily.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  await Future.delayed(const Duration(seconds: 2));
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cache cleared successfully'),
                      backgroundColor: AppColors.successColor,
                    ),
                  );
                },
                child: const Text(
                  'Clear',
                  style: TextStyle(color: AppColors.errorColor),
                ),
              ),
            ],
          ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Delete Account',
              style: TextStyle(color: AppColors.errorColor),
            ),
            content: const Text(
              'This action cannot be undone. All your data including properties, messages, and reviews will be permanently deleted.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showComingSoonSnackBar('Account deletion');
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.errorColor),
                ),
              ),
            ],
          ),
    );
  }

  void _showComingSoonSnackBar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be available soon'),
        backgroundColor: AppColors.infoColor,
      ),
    );
  }
}
