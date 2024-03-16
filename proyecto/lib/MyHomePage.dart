import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:animated_card/animated_card.dart';
import 'FriendPage.dart';
import 'ProfilePage.dart';
import 'UserGiftPage.dart';
import 'LoginPage.dart'; // Importa la página de inicio de sesión
import 'package:shared_preferences/shared_preferences.dart'; // Importa SharedPreferences

class MyHomePage extends StatefulWidget {
  final String title;
  final String authToken;

  const MyHomePage({Key? key, required this.title, required this.authToken})
      : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late List<User> _users = [];
  final TextEditingController _searchController = TextEditingController();
  late List<User> _searchResults = [];
  late BuildContext _context; // Variable para almacenar el BuildContext

  @override
  void initState() {
    super.initState();
    _getUsers();
    _context = context; // Asigna el valor de context a _context
  }

  Future<void> _getUsers() async {
    final response =
        await http.get(Uri.parse('http://127.0.0.1:8000/api/Users'));
    if (response.statusCode == 200) {
      setState(() {
        _users = (json.decode(response.body) as List)
            .map((data) => User.fromJson(data))
            .toList();
      });
    } else {
      throw Exception('Failed to load users');
    }
  }

  void _searchUsers(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    final List<User> searchResults = _users
        .where((user) =>
            user.name.toLowerCase().contains(query.toLowerCase()) ||
            user.surname.toLowerCase().contains(query.toLowerCase()))
        .toList();

    setState(() {
      _searchResults = searchResults;
    });
  }

  void _logout() async {
    final url = Uri.parse('http://127.0.0.1:8000/api/logout');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.authToken}',
      },
    );

    if (response.statusCode == 200) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('accessToken');
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.remove('isLoggedIn');
      await prefs.remove('rememberMe');

      // ignore: use_build_context_synchronously
      Navigator.pushReplacement(
        _context, // Usa _context en lugar de context
        MaterialPageRoute(
          builder: (context) => const LoginPage(title: 'Login'),
        ),
      );
    } else {
      _showSnackBar('Logout failed.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(_context).showSnackBar(SnackBar(
      content: Text(message),
      action: SnackBarAction(
        label: 'OK',
        onPressed: () => ScaffoldMessenger.of(_context).hideCurrentSnackBar(),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          "WishList",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blueAccent, Colors.lightBlueAccent],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(height: 20),
                    const Text(
                      'Busca a tus amigos',
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: Container(
                        color: Colors
                            .white, // Fondo blanco para la barra de búsqueda
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Buscar...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        _searchUsers(_searchController.text);
                        showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return _buildSearchResults(context);
                          },
                        );
                      },
                      child: const Text('Buscar'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Opciones',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10.0, // Reducir el espacio entre las tarjetas
                      runSpacing:
                          10.0, // Reducir el espacio entre las filas de tarjetas
                      children: <Widget>[
                        OptionCard(
                          title: 'Mi perfil',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UsersPage(
                                  authToken: widget.authToken,
                                ),
                              ),
                            );
                          },
                        ),
                        OptionCard(
                          title: 'Mis deseos',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserGiftPage(
                                  authToken: widget.authToken,
                                ),
                              ),
                            );
                          },
                        ),
                        OptionCard(
                          title: 'LogOut',
                          onTap: _logout,
                        ),
                      ],
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

  Widget _buildSearchResults(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final user = _searchResults[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FriendPage(
                    userId: user.id,
                    userImageUrl: user.imageUrl,
                    nameController: TextEditingController(text: user.name),
                    surnameController:
                        TextEditingController(text: user.surname),
                    emailController: TextEditingController(text: user.email),
                    phoneController: TextEditingController(text: user.phone),
                  ),
                ),
              );
            },
            child: ListTile(
              title: Text('${user.name} ${user.surname}'),
            ),
          );
        },
      ),
    );
  }
}

class User {
  final String name;
  final String surname;
  final int id;
  final String phone;
  final String imageUrl;
  final String email;

  User({
    required this.name,
    required this.surname,
    required this.id,
    required this.phone,
    required this.imageUrl,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      surname: json['surname'],
      id: json['id'],
      phone: json['phone'],
      imageUrl: json['image'],
      email: json['email'],
    );
  }
}

class OptionCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const OptionCard({Key? key, required this.title, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: AnimatedCard(
          direction: AnimatedCardDirection.top,
          initDelay: const Duration(milliseconds: 0),
          duration: const Duration(seconds: 1),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
