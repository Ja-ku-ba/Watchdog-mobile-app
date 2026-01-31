import 'package:flutter/material.dart';
import '../../layouts/base/loged_in_layout.dart';
import '../../models/verified_user.dart';
import '../../utils/request.dart';


class VerifiedUsersList extends StatefulWidget {
  const VerifiedUsersList({Key? key}) : super(key: key);

  @override
  State<VerifiedUsersList> createState() => _VerifiedUsersListState();
}

class _VerifiedUsersListState extends State<VerifiedUsersList> {
  List<VerifiedUserModel> _users = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final client = RequestClient();
    await client.initialize();

    try {
      final response = await client.get('/users/get-verified-users');
      final List<dynamic> data = response.data as List<dynamic>;
      final users = data.map((json) => VerifiedUserModel.fromJson(json)).toList();

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      child: SafeArea(
        child: Scaffold(
          body: _buildBody(),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).pushNamed('/add_user'),
            icon: const Icon(Icons.person_add),
            label: const Text('Dodaj użytkownika'),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Błąd, odśwież stronę',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Brak użytkowników',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80, top: 8),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return _UserListItem(
          user: user,
          onTap: () => Navigator.pushNamed(
            context,
            '/edit_verified_user',
            arguments: {
              'verified_user': user,
            },
          ),
        );
      },
    );
  }
}

class _UserListItem extends StatelessWidget {
  final VerifiedUserModel user;
  final VoidCallback onTap;

  const _UserListItem({
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          user.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Icon(Icons.photo_library, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${user.filesCounter} ${user.filesCounter == 1
                    ? 'zdjęcie'
                    : 'zdjęć'}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
