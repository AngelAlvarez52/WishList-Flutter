import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'GiftsPage.dart'; // Asegúrate de importar GiftsPage.dart

class FriendPage extends StatefulWidget {
  final int userId;
  final String authToken; // Agregar authToken aquí

  const FriendPage({Key? key, required this.userId, required this.authToken})
      : super(key: key);

  @override
  FriendPageState createState() => FriendPageState();
}

class FriendPageState extends State<FriendPage> {
  late TextEditingController nameController;
  late TextEditingController surnameController;
  late TextEditingController phoneController;
  late String userImageUrl;
  bool isLoading = true;
  bool isEditing = false;
  XFile? image;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    surnameController = TextEditingController();
    phoneController = TextEditingController();
    userImageUrl = '';
    _fetchUserData();
  }

  @override
  void dispose() {
    nameController.dispose();
    surnameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    final response = await http.get(
      Uri.parse('https://alvarez.terrabyteco.com/api/Users/${widget.userId}'),
    );

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      setState(() {
        nameController.text = userData['name'];
        surnameController.text = userData['surname'];
        phoneController.text = userData['phone'];
        userImageUrl = userData['image'];
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load user data');
    }
  }

  Future<void> _getImage() async {
    if (!isEditing) return;

    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        image = XFile(pickedImage.path);
      });
    }
  }

  Widget _buildUserAvatar() {
    return GestureDetector(
      onTap: isEditing ? _getImage : null,
      child: Stack(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(userImageUrl),
            radius: 50,
          ),
          if (isEditing)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de Usuario'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blueAccent, Colors.lightBlueAccent],
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),
                            Center(
                              child: _buildUserAvatar(),
                            ),
                            const SizedBox(height: 40),
                            _buildTextField("Nombre", nameController),
                            const SizedBox(height: 20),
                            _buildTextField("Apellido", surnameController),
                            const SizedBox(height: 20),
                            _buildTextField("Teléfono", phoneController),
                            const SizedBox(height: 20),
                            _buildButton(context), // Agrega el botón aquí
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: controller,
        enabled: isEditing,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white70,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GiftsPage(
                  userId: widget.userId,
                  authToken: widget.authToken), // Pasar authToken aquí
            ),
          );
        },
        child: const Text('Ver sus deseos'),
      ),
    );
  }
}
