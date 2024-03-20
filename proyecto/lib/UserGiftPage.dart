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
  late User _currentUser;
  final Logger _logger = Logger();
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _giftsFuture = _fetchGifts();
    _fetchCurrentUser();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentUser() async {
    final userId = await getUserId();
    final response = await http.get(
      Uri.parse('https://alvarez.terrabyteco.com/api/Users/$userId'),
      headers: {
        'Authorization': 'Bearer ${widget.authToken}',
      },
    );
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      setState(() {
        _currentUser = User.fromJson(jsonData);
      });
    } else {
      throw Exception('Failed to load current user');
    }
  }

  Future<int> getUserId() async {
    final response = await http.get(
      Uri.parse('https://alvarez.terrabyteco.com/api/userprofile'),
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
      Uri.parse(
          'https://alvarez.terrabyteco.com/api/gitf_user?user_id=$userId'),
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
      Uri.parse(
          'https://alvarez.terrabyteco.com/api/comments_gift?gift_id=$giftId'),
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
      Uri.parse('https://alvarez.terrabyteco.com/api/Users/$userId'),
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
      Uri.parse('https://alvarez.terrabyteco.com/api/Gifts/delete/$giftId'),
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
          const SizedBox(height: 20),
          const Text(
            'Calificación:',
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          FutureBuilder<int?>(
            future: _fetchRating(
                _selectedGift!.id, _currentUser.id, widget.authToken),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                final int? rating = snapshot.data;
                return _buildStarRating(rating ?? 0);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(int rating) {
    return Row(
      children: List.generate(
        5,
        (index) {
          IconData iconData = index < rating ? Icons.star : Icons.star_border;
          Color iconColor = index < rating ? Colors.amber : Colors.grey;
          return IconButton(
            onPressed: () {
              _postRating(index + 1);
            },
            icon: Icon(
              iconData,
              color: iconColor,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommentsSection() {
    return FutureBuilder<List<Comment>>(
      future: _selectedGift != null
          ? _fetchComments(_selectedGift!.id)
          : Future.value([]),
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
                    children: [
                      ...List.generate(comments.length, (index) {
                        final comment = comments[index];
                        final user = users[index];
                        bool isCurrentUserComment =
                            comment.userId == _currentUser.id;
                        return ListTile(
                          title: Text('${user.name} ${user.surname}'),
                          subtitle: Text(comment.text),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isCurrentUserComment)
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        TextEditingController controller =
                                            TextEditingController(
                                                text: comment.text);
                                        return AlertDialog(
                                          title:
                                              const Text('Editar Comentario'),
                                          content: TextField(
                                            controller: controller,
                                            onChanged: (text) {},
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                editarComentario(comment.id,
                                                    controller.text);
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('Guardar'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              if (isCurrentUserComment)
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title:
                                              const Text('Eliminar Comentario'),
                                          content: const Text(
                                              '¿Estás seguro de que deseas eliminar este comentario?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                eliminarComentario(comment.id);
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('Eliminar'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                      _buildCommentForm(),
                    ],
                  ),
                );
              }
            },
          );
        }
      },
    );
  }

  Widget _buildCommentForm() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Añadir Comentario',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Escribe tu comentario aquí',
              border: OutlineInputBorder(),
            ),
            onChanged: (text) {},
            onSubmitted: (text) {
              _postComment(text);
            },
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              _postComment(_controller.text);
            },
            child: const Text('Enviar Comentario'),
          ),
        ],
      ),
    );
  }

  Future<void> _postComment(String text) async {
    final userId = await getUserId();
    final response = await http.post(
      Uri.parse('https://alvarez.terrabyteco.com/api/Comments/create'),
      headers: {
        'Authorization': 'Bearer ${widget.authToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'text': text,
        'user_id': userId,
        'gift_id': _selectedGift!.id,
      }),
    );
    if (response.statusCode == 200) {
      setState(() {
        _fetchComments(_selectedGift!.id);
      });
    } else {
      throw Exception('Failed to post comment');
    }
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
      setState(() {
        _fetchComments(giftId);
      });
    } catch (e) {
      _logger.e('Error loading comments: $e');
    }
  }

  Future<void> eliminarComentario(int commentId) async {
    final response = await http.delete(
      Uri.parse(
          'https://alvarez.terrabyteco.com/api/comments/delete/$commentId'),
      headers: {
        'Authorization': 'Bearer ${widget.authToken}',
      },
    );
    if (response.statusCode == 200) {
      setState(() {
        _fetchComments(_selectedGift!.id);
      });
    } else {
      throw Exception('Failed to delete comment');
    }
  }

  Future<void> editarComentario(int commentId, String newText) async {
    final response = await http.post(
      Uri.parse(
          'https://alvarez.terrabyteco.com/api/Comments/$commentId/update'),
      headers: {
        'Authorization': 'Bearer ${widget.authToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'id': commentId,
        'text': newText,
      }),
    );
    if (response.statusCode == 200) {
      setState(() {
        _fetchComments(_selectedGift!.id);
      });
    } else {
      throw Exception('Failed to update comment');
    }
  }

  Future<void> _postRating(int rating) async {
    final userId = await getUserId();
    final response = await http.post(
      Uri.parse('https://alvarez.terrabyteco.com/api/Ratings/create'),
      headers: {
        'Authorization': 'Bearer ${widget.authToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'rating': rating,
        'user_id': userId,
        'gift_id': _selectedGift!.id,
      }),
    );
    if (response.statusCode == 200) {
      setState(() {
        _selectedGift!.rating = rating; // Actualiza la calificación localmente
      });
    } else {
      throw Exception('Failed to post rating');
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
  int? rating;
  int? ratingId;

  Gift({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required this.price,
    required this.image,
    this.rating,
    this.ratingId,
  });

  factory Gift.fromJson(Map<String, dynamic> json) {
    return Gift(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      url: json['url'],
      price: double.parse(json['price'].toString()),
      image: json['image'],
      rating: json['rating'],
      ratingId: json['rating_id'],
    );
  }
}

class Comment {
  final int id;
  final int userId;
  final String text;

  Comment({
    required this.id,
    required this.userId,
    required this.text,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      userId: json['user_id'],
      text: json['text'],
    );
  }
}

class User {
  final int id;
  final String name;
  final String surname;

  User({
    required this.id,
    required this.name,
    required this.surname,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      surname: json['surname'],
    );
  }
}

Future<int?> _fetchRating(int giftId, int userId, String authToken) async {
  final response = await http.get(
    Uri.parse(
        'https://alvarez.terrabyteco.com/api/rating_gift?gift_id=$giftId'),
    headers: {
      'Authorization': 'Bearer $authToken',
    },
  );
  if (response.statusCode == 200) {
    final List<dynamic> jsonData = jsonDecode(response.body);
    for (var ratingData in jsonData) {
      final rating = ratingData as Map<String, dynamic>;
      if (rating['user_id'] == userId) {
        return rating['rating'];
      }
    }
    return null;
  } else {
    throw Exception('Failed to load rating');
  }
}
