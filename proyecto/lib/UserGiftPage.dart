import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';
import 'GiftAddPage.dart';
import 'GiftEditPage.dart';

class UserGiftPage extends StatefulWidget {
  final String authToken;

  const UserGiftPage({Key? key, required this.authToken}) : super(key: key);

  @override
  UserGiftPageState createState() => UserGiftPageState();
}

class UserGiftPageState extends State<UserGiftPage> {
  late Future<List<Gift>> _giftsFuture;
  Gift? _selectedGift;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _giftsFuture = _fetchGifts();
  }

  Future<int> getUserId() async {
    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/userprofile'),
      headers: {
        'Authorization': 'Bearer ${widget.authToken}',
      },
    );
    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      return userData['id'];
    } else {
      throw Exception('Failed to get user id');
    }
  }

  Future<List<Gift>> _fetchGifts() async {
    final userId = await getUserId();
    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/gitf_user?user_id=$userId'),
      headers: {
        'Authorization': 'Bearer ${widget.authToken}',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((json) => Gift.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to load gifts. Status code: ${response.statusCode}');
    }
  }

  Future<List<Comment>> _fetchComments(int giftId) async {
    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/comments_gift?gift_id=$giftId'),
      headers: {
        'Authorization': 'Bearer ${widget.authToken}',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((json) => Comment.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to load comments. Status code: ${response.statusCode}');
    }
  }

  Future<List<User>> _fetchUsers(List<Comment> comments) async {
    final List<int> userIds =
        comments.map((comment) => comment.userId).toList();
    final List<Future<User>> userFutures =
        userIds.map((userId) => _fetchUser(userId)).toList();
    return await Future.wait(userFutures);
  }

  Future<User> _fetchUser(int userId) async {
    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/Users/$userId'),
      headers: {
        'Authorization': 'Bearer ${widget.authToken}',
      },
    );
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return User.fromJson(jsonData);
    } else {
      throw Exception(
          'Failed to load user. Status code: ${response.statusCode}');
    }
  }

  Future<void> eliminarRegalo(int giftId) async {
    final response = await http.delete(
      Uri.parse('http://127.0.0.1:8000/api/Gifts/delete/$giftId'),
      headers: {
        'Authorization': 'Bearer ${widget.authToken}',
      },
    );
    if (response.statusCode == 200) {
      setState(() {
        _selectedGift = null;
        _giftsFuture = _fetchGifts();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedGift != null ? _selectedGift!.name : 'Mis deseos'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      GiftAddPage(authToken: widget.authToken),
                ),
              );
              if (result == true) {
                setState(() {
                  _giftsFuture = _fetchGifts();
                });
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: _selectedGift != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildGiftDetails(),
                  const SizedBox(height: 20),
                  const Text(
                    'Comentarios',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  _buildCommentsSection(),
                ],
              )
            : _buildGiftsList(),
      ),
    );
  }

  Widget _buildGiftsList() {
    return FutureBuilder<List<Gift>>(
      future: _giftsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final List<Gift> gifts = snapshot.data!;
          return ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.all(5),
            itemCount: gifts.length,
            itemBuilder: (context, index) {
              final gift = gifts[index];
              return ListTile(
                title: Text(gift.name),
                subtitle: Text(gift.description),
                trailing: Text('\$${gift.price.toStringAsFixed(2)}'),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                leading: SizedBox(
                  width: 50,
                  child: Image.network(
                    gift.image,
                    fit: BoxFit.cover,
                  ),
                ),
                onTap: () async {
                  setState(() {
                    _selectedGift = gift;
                  });
                  _loadComments(gift.id);
                },
              );
            },
          );
        }
      },
    );
  }

  Widget _buildGiftDetails() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.network(
            _selectedGift!.image,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 20),
          Text(
            _selectedGift!.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _selectedGift!.description,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '\$${_selectedGift!.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: () {
                  _launchURL(_selectedGift!.url);
                },
                child: const Text('Ir al regalo'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GiftEditPage(
                        authToken: widget.authToken,
                        giftId: _selectedGift!.id,
                      ),
                    ),
                  );
                },
                child: const Text('Editar Regalo'),
              ),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Eliminar Regalo'),
                        content: const Text(
                            '¿Estás seguro de que deseas eliminar este regalo?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              eliminarRegalo(_selectedGift!.id);
                              Navigator.of(context).pop();
                            },
                            child: const Text('Eliminar'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Text('Eliminar regalo'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return FutureBuilder<List<Comment>>(
      future: _fetchComments(_selectedGift!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final List<Comment> comments = snapshot.data!;
          return FutureBuilder<List<User>>(
            future: _fetchUsers(comments),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (userSnapshot.hasError) {
                return Center(child: Text('Error: ${userSnapshot.error}'));
              } else {
                final List<User> users = userSnapshot.data!;
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(comments.length, (index) {
                      final comment = comments[index];
                      final user = users[index];
                      return ListTile(
                        title: Text('${user.name} ${user.surname}'),
                        subtitle: Text(comment.text),
                      );
                    }),
                  ),
                );
              }
            },
          );
        }
      },
    );
  }

  void _launchURL(String url) async {
    Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _loadComments(int giftId) async {
    try {
      setState(() {});
    } catch (e) {
      _logger.e('Error loading comments: $e');
    }
  }
}

class Gift {
  final int id;
  final String name;
  final String description;
  final String url;
  final double price;
  final String image;

  Gift({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required this.price,
    required this.image,
  });

  factory Gift.fromJson(Map<String, dynamic> json) {
    return Gift(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      url: json['url'],
      price: double.parse(json['price'].toString()),
      image: json['image'],
    );
  }
}

class Comment {
  final int userId;
  final String text;

  Comment({
    required this.userId,
    required this.text,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      userId: json['user_id'],
      text: json['text'],
    );
  }
}

class User {
  final String name;
  final String surname;

  User({
    required this.name,
    required this.surname,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      surname: json['surname'],
    );
  }
}
