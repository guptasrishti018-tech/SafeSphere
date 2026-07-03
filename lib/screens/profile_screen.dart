import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../global.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  final contact1Controller = TextEditingController();
  final contact2Controller = TextEditingController();
  final contact3Controller = TextEditingController();
  File? profileImage;

  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> saveProfile() async {
    if (emailController.text.isNotEmpty &&
        !emailController.text.contains("@")) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter a valid email")));
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('name', nameController.text);
    AppData.userName = nameController.text;
    await prefs.setString('phone', phoneController.text);
    await prefs.setString('email', emailController.text);

    await prefs.setString('contact1', contact1Controller.text);
    await prefs.setString('contact2', contact2Controller.text);
    await prefs.setString('contact3', contact3Controller.text);

    if (profileImage != null) {
      await prefs.setString('profileImage', profileImage!.path);
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Profile Saved Successfully")));
  }

  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      nameController.text = prefs.getString('name') ?? '';
      phoneController.text =
          FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
      emailController.text = prefs.getString('email') ?? '';

      contact1Controller.text = prefs.getString('contact1') ?? '';
      contact2Controller.text = prefs.getString('contact2') ?? '';
      contact3Controller.text = prefs.getString('contact3') ?? '';
      String? imagePath = prefs.getString('profileImage');

      if (imagePath != null) {
        profileImage = File(imagePath);
      }
    });
  }

  Future<void> pickImage(ImageSource source) async {
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        profileImage = File(image.path);
      });
      await saveProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.blue,
        title: const Text(
          "My Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.lightBlueAccent],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return SafeArea(
                            child: Wrap(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.photo),
                                  title: const Text("Gallery"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    pickImage(ImageSource.gallery);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text("Camera"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    pickImage(ImageSource.camera);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          profileImage != null
                              ? FileImage(profileImage!)
                              : null,
                      child:
                          profileImage == null
                              ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.blue,
                              )
                              : null,
                    ),
                  ),
                  const SizedBox(height: 8),

                  const Text(
                    "Tap to change photo",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    nameController.text.isEmpty
                        ? "SafeSphere User"
                        : nameController.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    phoneController.text,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: nameController,
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person),
                labelText: "Full Name",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: phoneController,
              readOnly: true,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.phone),
                labelText: "Phone Number",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.email),
                labelText: "Email",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.verified, color: Colors.green),
                title: const Text("Digital ID Status"),
                subtitle: const Text("Verified"),
              ),
            ),
            Card(
              elevation: 3,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.shield, color: Colors.white),
                ),
                title: const Text(
                  "Safety Level",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text("Protected"),
              ),
            ),
            const SizedBox(height: 25),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    const Text(
                      "🚨 Emergency Contacts",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: contact1Controller,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.contact_phone),
                        labelText: "Emergency Contact 1",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: contact2Controller,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.contact_phone),
                        labelText: "Emergency Contact 2",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: contact3Controller,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.contact_phone),
                        labelText: "Emergency Contact 3",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: saveProfile,
                icon: const Icon(Icons.save),
                label: const Text(
                  "Save Profile",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text(
                  "Logout",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();

    contact1Controller.dispose();
    contact2Controller.dispose();
    contact3Controller.dispose();

    super.dispose();
  }
}
