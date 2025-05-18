import 'package:flutter/material.dart';
import 'otp_verification_screen.dart';
import 'package:swipelit/utils/constants.dart';

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
      builder: (_) => ListView.builder(
        itemCount: countries.length,
        itemBuilder: (_, index) {
          final country = countries[index];
          return ListTile(
            leading: Text(country.flag, style: const TextStyle(fontSize: 24)),
            title: Text("${country.name} (${country.code})"),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 🔙 Back Button
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 24),

            const Center(
              child: Text(
                "My number is",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.grey.shade300),
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
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const VerticalDivider(width: 1, thickness: 1),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "Enter your phone number",
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                            style: const TextStyle(fontSize: 18),
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
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(36),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
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
