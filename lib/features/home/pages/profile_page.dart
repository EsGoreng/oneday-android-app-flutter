import 'dart:math';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:oneday/core/providers/profile_provider.dart';
import 'package:oneday/shared/widgets/common_widgets.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:url_launcher/url_launcher.dart';
import 'avatar_customizer_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const nameRoute = '/profile-page';

  void _handleLogout(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Logout Confirmation',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) => const _LogoutConfirmationDialog(),
      transitionBuilder: (context, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5 * anim1.value, sigmaY: 5 * anim1.value),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double maxWidth = min(MediaQuery.of(context).size.width * 0.9, 540.0);
    return Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) => Scaffold(
          backgroundColor: customCream, // customCream
          body: Stack(
            children: [
              const GridBackground(gridSize: 50, lineColor: Color.fromARGB(50, 0, 0, 0)),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SingleChildScrollView(
                        clipBehavior: Clip.none,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Column(
                          children: [
                              TopNavigationBar(
                              title: 'Profile Page',
                              actionIcon: Icons.logout_outlined,
                              onEditPressed: () => _handleLogout(context),
                            ),
                            const SizedBox(height: 12),
                            UserProfileCard(profileProvider: profileProvider),
                            const SizedBox(height: 12),
                            const SettingsCard(),
                            const SizedBox(height: 64),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _LogoutConfirmationDialog extends StatefulWidget {
  const _LogoutConfirmationDialog();

  @override
  State<_LogoutConfirmationDialog> createState() => _LogoutConfirmationDialogState();
}

class _LogoutConfirmationDialogState extends State<_LogoutConfirmationDialog> {
  bool _isLoggingOut = false;

  Future<void> _performLogout() async {
    if (_isLoggingOut) return;
    setState(() { _isLoggingOut = true; });

    try {
      // PERBAIKAN: Lakukan semua proses sign-out
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      if(mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error logging out: $e"), backgroundColor: customRed),
        );
        setState(() { _isLoggingOut = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: StyledCard(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Confirm Logout', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                const Text('Are you sure you want to log out?', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        padding: const EdgeInsets.all(8),
                        text: 'Cancel',
                        onPressed: () => Navigator.of(context).pop(),
                        color: Colors.grey.shade300,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        padding: const EdgeInsets.all(8),
                        text: _isLoggingOut ? 'Logging out...' : 'Logout',
                        onPressed: _isLoggingOut ? null : _performLogout,
                        color: customRed, // customRed
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UserProfileCard extends StatelessWidget {
  const UserProfileCard({
    super.key,
    required this.profileProvider,
  });

  final ProfileProvider profileProvider;

  @override
  Widget build(BuildContext context) {
    final String avatarUrl = profileProvider.profilePicturePath;
    final bool isSvg =
        avatarUrl.contains('api.dicebear.com') || avatarUrl.endsWith('.svg');

    return StyledCard(
      color: customYellow,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all()
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey.shade300,
                child: ClipOval(
                  child: isSvg
                      ? SvgPicture.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          width: 65,
                          height: 65,
                          placeholderBuilder: (_) =>
                              const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          width: 65,
                          height: 65,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.person, size: 40, color: Colors.white),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nickname :', style: TextStyle(fontSize: 12)),
                Text(profileProvider.userName,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const Text('Email :', style: TextStyle(fontSize: 12)),
                Text(
                  FirebaseAuth.instance.currentUser?.email ?? 'No email',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                // TAMPILKAN DATA BARU
                 const Text('Age :', style: TextStyle(fontSize: 12)),
                Text('${profileProvider.age} Years old',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                 const Text('Busyness :', style: TextStyle(fontSize: 12)),
                Text(profileProvider.jobStatus,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
class SettingsCard extends StatefulWidget {
  const SettingsCard({super.key});

  @override
  State<SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<SettingsCard> {
  late TextEditingController _usernameController;
  late TextEditingController _ageController;
  String? _selectedJobStatus;
  bool _isSaving = false;

    final List<String> _jobStatusOptions = [
    'Students',
    'Office Workers',
    'Self-Employed',
    'Freelancers',
    'Housewives',
    'Unemployed'
  ];

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _ageController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final profileProvider = context.read<ProfileProvider>();
        _usernameController.text = profileProvider.userName;
        _ageController.text = profileProvider.age.toString();
        _selectedJobStatus = profileProvider.jobStatus;

      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  String _getSymbolForLocale(String locale) {
    switch (locale) {
      case 'id_ID': return 'Rp';
      case 'en_US': return '\$';
      case 'ja_JP': return '¥';
      case 'en_GB': return '£';
      default: return '';
    }
  }

  Future<void> _saveSettings() async {
    if (_isSaving) return;
    final profileProvider = context.read<ProfileProvider>();
    final newUsername = _usernameController.text;
    final newAgeText = _ageController.text;

    // VALIDASI INPUT
    if (newUsername.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nickname cannot be empty.'), backgroundColor: Color(0xFFC62828)),
      );
      return;
    }
     if (newAgeText.trim().isEmpty || int.tryParse(newAgeText) == null || int.parse(newAgeText) <= 0) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Age must be filled with valid numbers.'), backgroundColor: Color(0xFFC62828)),
      );
      return;
    }
     if (_selectedJobStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your employment status.'), backgroundColor: Color(0xFFC62828)),
      );
      return;
    }

    setState(() { _isSaving = true; });

    try {
      final newAge = int.parse(newAgeText);
      // Panggil fungsi secara terpisah untuk memperbarui data
      await profileProvider.setUserName(newUsername);
      await profileProvider.setAgeAndJobStatus(newAge, _selectedJobStatus!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Color(0xFF4CAF50)),
        );
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e'), backgroundColor: const Color(0xFFC62828)),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isSaving = false; });
      }
    }
  }

  Future<void> _launchDonationUrl() async {
    final Uri url = Uri.parse('https://saweria.co/amazingdev'); // Ganti dengan URL Saweria Anda
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }


  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();

    if (_usernameController.text != profileProvider.userName) {
      _usernameController.text = profileProvider.userName;
    }
     if (_ageController.text != profileProvider.age.toString()) {
      _ageController.text = profileProvider.age.toString();
    }

    final Map<String, String> currencyOptions = {
      'id_ID': 'Indonesian Rupiah (Rp)',
      'en_US': 'US Dollar (\$)',
      'ja_JP': 'Japanese Yen (¥)',
      'en_GB': 'British Pound (£)',
    };

    return StyledCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          const Text('Nickname', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          CustomTextField(
            controller: _usernameController,
            hintText: 'Enter your nickname',
          ),
           const SizedBox(height: 16),
          // FORM EDIT BARU
          const Text('Age', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          CustomTextField(
            controller: _ageController,
            hintText: 'Enter your age',
            keyboardType: TextInputType.number,
          ),
           const SizedBox(height: 16),
          const Text('Busyness', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
           Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(),
              borderRadius: const BorderRadius.all(Radius.circular(4)),
            ),
              child: DropdownButton<String>(
                isExpanded: true,
                underline: const SizedBox.shrink(),
                value: _selectedJobStatus,
                 hint: const Text('Select job status'),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedJobStatus = newValue;
                    });
                  }
                },
                items: _jobStatusOptions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
          ),
          const SizedBox(height: 16),
          const Text('Currency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(),
              borderRadius: const BorderRadius.all(Radius.circular(4)),
            ),
              child: DropdownButton<String>(
                isExpanded: true,
                underline: const SizedBox.shrink(),
                value: profileProvider.currencyLocale,
                onChanged: (String? newValue) async {
                  if (newValue != null) {
                    try {
                      await initializeDateFormatting(newValue, null);
                      String symbol = _getSymbolForLocale(newValue);
                      await profileProvider.setCurrency(newValue, symbol);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to set locale: $e'))
                      );
                    }
                  }
                },
                items: currencyOptions.entries.map<DropdownMenuItem<String>>((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
              ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 42,
            width: double.infinity,
            child: PrimaryButton(
              color: customPink,
              text: 'Customize Avatar',
              icon: const Icon(CupertinoIcons.pencil_outline),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AvatarCustomizerPage())),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            width: double.infinity,
            child: PrimaryButton(
              text: 'Support us with Saweria',
              onPressed: _launchDonationUrl, // Panggil fungsi donasi
              color: customRed,
              icon: const Icon(CupertinoIcons.heart_fill), // Warna khas Saweria
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            width: double.infinity,
            child: PrimaryButton(
              text: _isSaving ? 'Saving...' : 'Save Changes',
              onPressed: _isSaving ? null : _saveSettings,
              icon: const Icon(CupertinoIcons.floppy_disk),
            ),
          ),
        ],
      ),
    );
  }
}