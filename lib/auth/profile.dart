import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/profile_provider.dart';
import '../shared/widgets/common_widgets.dart';
import '../shared/widgets/mainnavigation.dart';
import 'dart:math';

class ProfileLoginPage extends StatefulWidget {
  const ProfileLoginPage({super.key});
  static const nameRoute = 'userProfilePage';

  @override
  State<ProfileLoginPage> createState() => _ProfileLoginPageState();
}

class _ProfileLoginPageState extends State<ProfileLoginPage> {
  final _usernameController = TextEditingController();
  final _ageController = TextEditingController(); // CONTROLLER BARU
  String _selectedLocale = 'id_ID';
  String? _selectedJobStatus; // State untuk menyimpan status pekerjaan
  bool _isSaving = false;

  final List<String> _jobStatusOptions = [ // OPSI PEKERJAAN
    'Students',
    'Office Workers',
    'Self-Employed',
    'Freelancers',
    'Housewives',
    'Unemployed'
  ];


  @override
  void dispose() {
    _usernameController.dispose();
    _ageController.dispose(); // Hapus controller
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

  Future<void> _next() async {
    if (_isSaving) return;
    final username = _usernameController.text;
    final ageText = _ageController.text;

    // VALIDASI INPUT
    if (username.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nickname cannot be empty.'), backgroundColor: Color(0xFFC62828)),
      );
      return;
    }
    if (ageText.trim().isEmpty || int.tryParse(ageText) == null || int.parse(ageText) <= 0) {
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
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final symbol = _getSymbolForLocale(_selectedLocale);
      final age = int.parse(ageText);

      // Panggil fungsi baru untuk menyimpan semua data awal
      await profileProvider.setInitialProfile(
        userName: username,
        currencyLocale: _selectedLocale,
        currencySymbol: symbol,
        age: age,
        jobStatus: _selectedJobStatus!,
      );


      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(MainNavigationWrapper.nameRoute, (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving profile: $e"), backgroundColor: const Color(0xFFC62828)),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isSaving = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double maxWidth = min(MediaQuery.of(context).size.width * 0.9, 540.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const GridBackground(gridSize: 50, lineColor: Color.fromARGB(50, 0, 0, 0)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: StyledCard(
                    child: _buildProfileForm(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    final Map<String, String> currencyOptions = {
      'id_ID': 'Indonesian Rupiah (Rp)',
      'en_US': 'US Dollar (\$)',
      'ja_JP': 'Japanese Yen (¥)',
      'en_GB': 'British Pound (£)',
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Let\'s start from basic',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const Text(
          'Set your profile for best experience',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        const Text('Nickname', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        CustomTextField(
          controller: _usernameController,
          hintText: 'Enter your nickname',
        ),
        const SizedBox(height: 16),
        // FORM BARU UNTUK UMUR
        const Text('Age', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        CustomTextField(
          controller: _ageController,
          hintText: 'Enter your age',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        // DROPDOWN BARU UNTUK STATUS PEKERJAAN
        const Text('Employment Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
         Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
              border: Border.all(),
              borderRadius: const BorderRadius.all(Radius.circular(4))),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
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
        ),
        const SizedBox(height: 16),
        const Text('Currency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
              border: Border.all(),
              borderRadius: const BorderRadius.all(Radius.circular(4))),
          child: DropdownButton<String>(
            isExpanded: true,
            underline: const SizedBox.shrink(),
            value: _selectedLocale,
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedLocale = newValue;
                });
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
            text: _isSaving ? 'Saving...' : 'Continue',
            onPressed: _isSaving ? null : _next,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}