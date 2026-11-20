import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _error;
  String _search = '';

  int get _myId => context.read<AuthProvider>().user!.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getUsers(_myId);
      if (!mounted) return;
      setState(() => _users = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isAktif(Map<String, dynamic> u) =>
      u['aktif'] == 1 || u['aktif'] == true;

  Future<void> _toggle(Map<String, dynamic> u, bool aktif) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(aktif ? 'Aktifkan akun?' : 'Nonaktifkan akun?'),
        content: Text(
          '${u['nama_lengkap']} (${u['username']}) ${aktif ? 'dapat' : 'tidak dapat'} login ke aplikasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('BATAL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('YA'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ApiService.setUserAktif(_myId, u['id_user'] as int, aktif);
      if (!mounted) return;
      setState(() => u['aktif'] = aktif ? 1 : 0);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Coba Lagi')),
          ],
        ),
      );
    }

    final q = _search.toLowerCase();
    final list = _users.where((u) {
      return '${u['nama_lengkap']} ${u['username']}'.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Cari nama / username',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final u = list[i];
                final aktif = _isAktif(u);
                final isMe = u['id_user'] == _myId;
                return SwitchListTile(
                  title: Text('${u['nama_lengkap']}'),
                  subtitle: Text(
                    '${u['username']} · ${u['role']} · cabang ${u['id_cabang']}',
                  ),
                  value: aktif,
                  onChanged: isMe ? null : (v) => _toggle(u, v),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
