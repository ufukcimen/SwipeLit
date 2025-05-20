import 'package:flutter/material.dart';
import 'otp_verification_screen.dart';
import 'package:pain/utils/constants.dart';

// 🌍 Country data model
class CountryData {
  final String name;
  final String flag;
  final String code;

  CountryData(this.name, this.flag, this.code);
}

class PhoneEntryScreen extends StatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final TextEditingController phoneController = TextEditingController();

  final List<CountryData> countries = [
    CountryData("Brazil", "🇧🇷", "+55"),
    CountryData("Canada", "🇨🇦", "+1"),
    CountryData("France", "🇫🇷", "+33"),
    CountryData("Germany", "🇩🇪", "+49"),
    CountryData("India", "🇮🇳", "+91"),
    CountryData("Italy", "🇮🇹", "+39"),
    CountryData("Japan", "🇯🇵", "+81"),
    CountryData("Turkey", "🇹🇷", "+90"),
    CountryData("United Kingdom", "🇬🇧", "+44"),
    CountryData("United States", "🇺🇸", "+1"),
  ];

  late CountryData selectedCountry;

  @override
  void initState() {
    super.initState();
    countries.sort((a, b) => a.name.compareTo(b.name));
    selectedCountry = countries.firstWhere((c) => c.code == "+90");
  }

  void _openCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.getCardBackground(context),
      builder: (_) => ListView.builder(
        itemCount: countries.length,
        itemBuilder: (_, index) {
          final country = countries[index];
          return ListTile(
            leading: Text(country.flag, style: const TextStyle(fontSize: 24)),
            title: Text(
              "${country.name} (${country.code})",
              style: TextStyle(color: AppColors.getTextPrimary(context)),
            ),
            onTap: () {
              setState(() => selectedCountry = country);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }

  String squeezePhone(String code, String number) {
    final digitsOnly = number.replaceAll(RegExp(r'\D'), '');
    return "$code$digitsOnly";
  }

  void _handleContinue() {
    final raw = phoneController.text.trim();
    final digitsOnly = raw.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phone number must be at least 10 digits")),
      );
      return;
    }

    final squeezed = squeezePhone(selectedCountry.code, raw);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OTPVerificationScreen(
          phoneNumber: squeezed,
          fromSignUp: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get theme-aware colors
    final backgroundColor = AppColors.getBackground(context);
    final textColor = AppColors.getTextPrimary(context);
    final textSecondaryColor = AppColors.getTextSecondary(context);
    final cardColor = AppColors.getCardBackground(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 🔙 Back Button
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: textColor),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 24),

            Center(
              child: Text(
                "My number is",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),

            const Spacer(flex: 2),

            // 📱 Phone Input Section
            Column(
              children: [
                Padding(
                  padding: AppPaddings.screen,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: borderColor!),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: _openCountryPicker,
                          child: Row(
                            children: [
                              Text(selectedCountry.flag, style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 6),
                              Text(
                                selectedCountry.code,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              Icon(Icons.arrow_drop_down, color: textColor),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: borderColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(fontSize: 18, color: textColor),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Enter your phone number",
                              hintStyle: TextStyle(color: textSecondaryColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ✅ Continue Button
                Padding(
                  padding: AppPaddings.screen,
                  child: GestureDetector(
                    onTap: _handleContinue,
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(36),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode ? Colors.black26 : Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "Continue",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}