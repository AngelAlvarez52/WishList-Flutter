import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
      Uri.parse('http://127.0.0.1:8000/api/userprofile'),
      headers: {
        'Authorization': 'Bearer ${widget.authToken}',
      },
    );

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      setState(() {
        _nameController.text = userData['name'];
        _surnameController.text = userData['surname'];
        _emailController.text = userData['email'];
        _phoneController.text = userData['phone'];
        _userImageUrl = userData['image'];
        _isLoading = false; // Marcamos la carga como completada
      });
    } else {
      throw Exception('Failed to load user data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de Usuario'),
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
                              child: CircleAvatar(
                                backgroundImage: NetworkImage(_userImageUrl),
                                radius: 50,
                              ),
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
      padding: const EdgeInsets.only(bottom: 8.0), // Espaciado hacia abajo
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText:
              null, // Aquí establecemos el labelText como null para eliminar el texto
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0, vertical: 20.0), // Ajuste de contenido
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        enabled: false,
      ),
    );
  }
}
