import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'GiftAddPage.dart';

class UserGiftPage extends StatefulWidget {
  final String authToken;

  const UserGiftPage({Key? key, required this.authToken}) : super(key: key);

  @override
  UserGiftPageState createState() => UserGiftPageState();
}

class UserGiftPageState extends State<UserGiftPage> {
  late Future<List<Gift>> _giftsFuture;
  Gift? _selectedGift;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedGift != null ? _selectedGift!.name : 'User Gifts'),
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
              // If a gift was added, refresh the list
              if (result == true) {
                setState(() {
                  _giftsFuture = _fetchGifts();
                });
              }
            },
          ),
        ],
      ),
      body: _selectedGift != null ? _buildGiftDetails() : _buildGiftsList(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Image.network(
              _selectedGift!.image,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
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
              ],
            ),
          ),
        ),
      ],
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
