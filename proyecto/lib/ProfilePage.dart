import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class UsersPage extends StatefulWidget {
  final String authToken;

  const UsersPage({Key? key, required this.authToken}) : super(key: key);

  @override
  UsersPageState createState() => UsersPageState();
}

class UsersPageState extends State<UsersPage> {
  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late String _userImageUrl;
  bool _isLoading = true;
  int _userId = 0;
  bool _isEditing = false;
  XFile? _image;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _surnameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _userImageUrl = '';
    _fetchUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    final response = await http.get(
      Uri.parse('https://alvarez.terrabyteco.com/api/userprofile'),
      headers: {
        'Authorization': 'Bearer ${widget.authToken}',
      },
    );

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      setState(() {
        _userId = userData['id'];
        _nameController.text = userData['name'];
        _surnameController.text = userData['surname'];
        _emailController.text = userData['email'];
        _phoneController.text = userData['phone'];
        _userImageUrl = userData['image'];
        _isLoading = false;
      });
    } else {
      throw Exception('Failed to load user data');
    }
  }

  Future<void> _editUser() async {
    if (!_isEditing) {
      setState(() {
        _isEditing = true;
      });
    } else {
      final apiUrl =
          'https://alvarez.terrabyteco.com/api/Users/$_userId/update';

      // Construir el cuerpo de la solicitud
      final Map<String, String> body = {
        'id': _userId.toString(),
        'name': _nameController.text,
        'surname': _surnameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
      };

      if (_image != null) {
        final bytes = await _image!.readAsBytes();
        final String base64Image = base64Encode(bytes);
        body['image'] = base64Image;
      } else {
        body['image'] = _userImageUrl;
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        // Recargar los datos del usuario para actualizar la imagen
        await _fetchUserData();
      } else {
        throw Exception('Failed to update user data');
      }

      setState(() {
        _isEditing = false;
      });
    }
  }

  Future<void> _getImage() async {
    if (!_isEditing) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = image;
    });
  }

  Widget _buildUserAvatar() {
    return GestureDetector(
      onTap: _isEditing ? _getImage : null,
      child: Stack(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(_userImageUrl),
            radius: 50,
          ),
          Positioned(
            top: 0,
            right: 0,
            child: _isEditing
                ? Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                    ),
                  )
                : Container(),
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
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: _editUser,
          ),
        ],
      ),
      body: _isLoading
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
                            _buildTextField(_nameController),
                            const SizedBox(height: 20),
                            _buildTextField(_surnameController),
                            const SizedBox(height: 20),
                            _buildTextField(_emailController),
                            const SizedBox(height: 20),
                            _buildTextField(_phoneController),
                            const SizedBox(height: 20),
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

  Widget _buildTextField(TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: controller,
        enabled: _isEditing,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: null,
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
}
