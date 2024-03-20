import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class Gift {
  final int id;
  final String name;
  final String description;
  final String url;
  final double price;
  final String image;
  final int categoryId;
  final int userId;
  final int shopId;
  final List<Comment> comments;

  Gift({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required this.price,
    required this.image,
    required this.categoryId,
    required this.userId,
    required this.shopId,
    required this.comments,
  });

  factory Gift.fromJson(Map<String, dynamic> json) {
    List<Comment> comments = [];
    if (json['comments'] != null) {
      comments =
          json['comments'].map<Comment>((c) => Comment.fromJson(c)).toList();
    }
    return Gift(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      url: json['url'],
      price: double.parse(json['price'].toString()),
      image: json['image'],
      categoryId: json['category_id'],
      userId: json['user_id'],
      shopId: json['shop_id'],
      comments: comments,
    );
  }
}

class GiftsPage extends StatefulWidget {
  final int userId;
  final String authToken;

  const GiftsPage({Key? key, required this.userId, required this.authToken})
      : super(key: key);

  @override
  GiftsPageState createState() => GiftsPageState();
}

class GiftsPageState extends State<GiftsPage> {
  late Future<List<Gift>> _giftsFuture;
  Gift? _selectedGift;
  final TextEditingController _controller = TextEditingController();

  // Agregar esta variable para almacenar el ID del usuario
  late int _currentUserId;

  @override
  void initState() {
    super.initState();
    _giftsFuture = _fetchGifts();
    _initializeCurrentUser();
  }

  Future<void> _initializeCurrentUser() async {
    final userId = await getUserId();
    setState(() {
      _currentUserId = userId;
    });
  }

  Future<List<Gift>> _fetchGifts() async {
    final response = await http.get(Uri.parse(
        'https://alvarez.terrabyteco.com/api/gitf_user/?user_id=${widget.userId}'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((json) => Gift.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load gifts');
    }
  }

  Future<int?> _fetchGiftRating(int giftId) async {
    final response = await http.get(Uri.parse(
        'https://alvarez.terrabyteco.com/api/rating_gift?gift_id=$giftId'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      if (jsonData.isNotEmpty) {
        final Map<String, dynamic> ratingData = jsonData.first;
        final int? rating = ratingData['rating'];
        return rating;
      } else {
        return null;
      }
    } else {
      throw Exception('Failed to load gift rating');
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

  Future<User> _fetchUser(int userId) async {
    final response = await http.get(
      Uri.parse('https://alvarez.terrabyteco.com/api/Users/$userId'),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return User.fromJson(jsonData);
    } else {
      throw Exception('Failed to load user data');
    }
  }

  Future<void> _postComment(String text) async {
    const url = 'https://alvarez.terrabyteco.com/api/Comments/create';

    // Obtener el user_id del método getUserId()
    int userId = await getUserId();

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${widget.authToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'text': text,
        'user_id': userId, // Usar el user_id obtenido del método getUserId()
        'gift_id': _selectedGift!.id,
      }),
    );
    if (response.statusCode == 200) {
      _controller.clear();
      // Forzar la reconstrucción del widget después de enviar el comentario
      setState(() {
        // Actualizar _selectedGift para forzar la reconstrucción del widget
        _selectedGift = _selectedGift!;
      });
    } else {
      // Manejar el error si la publicación del comentario falla
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
                onTap: () {
                  setState(() {
                    _selectedGift = gift;
                  });
                },
              );
            },
          );
        }
      },
    );
  }

  Widget _buildGiftDetails() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Image.network(
              _selectedGift!.image,
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                ElevatedButton(
                  onPressed: () {
                    _launchURL(_selectedGift!.url);
                  },
                  child: const Text('Ir al regalo'),
                ),
                const SizedBox(height: 20),
                FutureBuilder<int?>(
                  future: _fetchGiftRating(_selectedGift!.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      final int? rating = snapshot.data;
                      return rating != null
                          ? Row(
                              children: [
                                const Text('Calificación: '),
                                _buildRatingStars(rating),
                              ],
                            )
                          : const Text('Sin calificaciones');
                    }
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Comentarios:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FutureBuilder<List<Comment>>(
                  future: _fetchComments(_selectedGift!.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else {
                      final List<Comment> comments = snapshot.data!;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return _buildCommentItem(comment);
                        },
                      );
                    }
                  },
                ),
                _buildCommentForm(),
              ],
            ),
          ),
        ],
      ),
    );
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
        // Encuentra el comentario en la lista y actualiza su texto
        for (int i = 0; i < _selectedGift!.comments.length; i++) {
          if (_selectedGift!.comments[i].id == commentId) {
            _selectedGift!.comments[i] = Comment(
              id: _selectedGift!.comments[i].id,
              text: newText,
              userId: _selectedGift!.comments[i].userId,
            );
            break;
          }
        }
      });
    } else {
      throw Exception('Failed to update comment');
    }
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      children: List.generate(
        5,
        (index) => Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.yellow,
        ),
      ),
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

  Widget _buildCommentItem(Comment comment) {
    bool isOwner = comment.userId == _currentUserId;

    return ListTile(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<User>(
            future: _fetchUser(comment.userId),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (userSnapshot.hasError) {
                return Text('Error: ${userSnapshot.error}');
              } else {
                final User user = userSnapshot.data!;
                return Text(
                  '${user.name} ${user.surname}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                );
              }
            },
          ),
          Text(comment.text),
        ],
      ),
      trailing: isOwner
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    eliminarComentario(comment.id);
                    setState(() {
                      // Actualizar la lista de comentarios después de eliminar uno
                      _selectedGift!.comments.remove(comment);
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        TextEditingController controller =
                            TextEditingController(text: comment.text);
                        return AlertDialog(
                          title: const Text('Editar Comentario'),
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
                                editarComentario(
                                    comment.id,
                                    controller
                                        .text); // Aquí se pasa el commentId
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
              ],
            )
          : null,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        title: Text(_selectedGift != null ? _selectedGift!.name : 'Sus deseos'),
      ),
      body: _selectedGift != null ? _buildGiftDetails() : _buildGiftsList(),
    );
  }
}

class Comment {
  final int id;
  final String text;
  final int userId;

  Comment({required this.id, required this.text, required this.userId});

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      text: json['text'],
      userId: json['user_id'],
    );
  }
}

class User {
  final String name;
  final String surname;

  User({required this.name, required this.surname});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      surname: json['surname'],
    );
  }
}

Future<void> eliminarComentario(int commentId) async {
  final url = 'https://alvarez.terrabyteco.com/api/comments/delete/$commentId';
  final response = await http.delete(Uri.parse(url));
  if (response.statusCode == 200) {
    // Comentario eliminado correctamente, no necesitas actualizar el estado aquí
    // porque la lista de comentarios se actualiza automáticamente al construirse.
  } else {
    throw Exception(
        'Error al eliminar el comentario. Código de estado: ${response.statusCode}');
  }
}
