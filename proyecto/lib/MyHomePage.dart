import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:animated_card/animated_card.dart';
import 'package:http/http.dart' as http;
import 'FriendPage.dart';
import 'ProfilePage.dart';
import 'UserGiftPage.dart';

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

  @override
  void initState() {
    super.initState();
    _getUsers();
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
                          title: 'Comentarios',
                          onTap: () {
                            // Implementa la lógica para Comentarios
                          },
                        ),
                        OptionCard(
                          title: 'Calificaciones',
                          onTap: () {
                            // Implementa la lógica para Calificaciones
                          },
                        ),
                        OptionCard(
                          title: 'LogOut',
                          onTap: () {
                            // Implementa la lógica para LogOut
                          },
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
                    userId: user
                        .id, // Asegúrate de tener este campo en tu clase User
                    userImageUrl: '', // URL de la imagen del usuario
                    nameController: TextEditingController(text: user.name),
                    surnameController:
                        TextEditingController(text: user.surname),
                    emailController:
                        TextEditingController(text: ''), // Si lo estás usando
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

  User({
    required this.name,
    required this.surname,
    required this.id,
    required this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      surname: json['surname'],
      id: json['id'],
      phone: json['phone'],
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
