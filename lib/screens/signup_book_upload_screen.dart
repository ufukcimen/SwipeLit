import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:swipelit/utils/constants.dart';

class SignUpUploadBookScreen extends StatefulWidget {
  const SignUpUploadBookScreen({super.key});

  @override
  State<SignUpUploadBookScreen> createState() => _SignUpUploadBookScreenState();
}

class _SignUpUploadBookScreenState extends State<SignUpUploadBookScreen> {
  final List<File> _bookImages = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    print("📸 PLUS BUTTON TAPPED");

    var status = await Permission.photos.request();

    if (!status.isGranted) {
      print("❌ Permission not granted");
      return;
    }

    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _bookImages.add(File(pickedFile.path));
      });
    } else {
      print("No image selected.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: AppPaddings.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // 🔁 Back button + progress bar
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Container(
                    width: screenWidth * 0.5,
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.green.shade100,
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              const Center(
                child: Text(
                  "Upload Your Books",
                  style: AppTextStyles.heading,
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  "Share your favorite books to begin\nexchanging",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),

              const SizedBox(height: 32),

              // Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    ..._bookImages.map(
                          (image) => ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(image, fit: BoxFit.cover),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _pickImage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green),
                          ),
                          child: const Center(
                            child: Icon(Icons.add, size: 40, color: Colors.green),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ✅ Finish Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/locationPermission');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(36),
                    ),
                  ),
                  child: const Text(
                    "Finish",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
