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

  Future<void> _tambahSatpam() async {
    List<dynamic> cabang;
    try {
      cabang = await ApiService.fetchCabangList();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
      return;
    }
    if (!mounted) return;

    final username = TextEditingController();
    final password = TextEditingController();
    final nama = TextEditingController();
    int? idCabang;
    String? error;
    bool saving = false;

    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (c) => StatefulBuilder(
        builder: (c, setD) => AlertDialog(
          title: const Text('Tambah Akun Satpam'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nama,
                    decoration:
                        const InputDecoration(labelText: 'Nama lengkap')),
                TextField(
                    controller: username,
                    decoration: const InputDecoration(labelText: 'Username')),
                TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Password (min. 6 karakter)')),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: idCabang,
                  decoration: const InputDecoration(labelText: 'Cabang'),
                  items: cabang
                      .map((e) => DropdownMenuItem<int>(
                            value: int.tryParse('${e['id_cabang']}') ?? 0,
                            child: Text('${e['nama_cabang']}'),
                          ))
                      .toList(),
                  onChanged: (v) => setD(() => idCabang = v),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child:
                        Text(error!, style: const TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: saving ? null : () => Navigator.pop(c, false),
                child: const Text('BATAL')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (nama.text.trim().isEmpty ||
                          username.text.trim().isEmpty ||
                          idCabang == null) {
                        setD(() => error = 'Lengkapi semua kolom.');
                        return;
                      }
                      setD(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        await ApiService.createSatpam(
                          requesterId: _myId,
                          username: username.text.trim(),
                          password: password.text,
                          namaLengkap: nama.text.trim(),
                          idCabang: idCabang!,
                        );
                        if (c.mounted) Navigator.pop(c, true);
                      } catch (e) {
                        setD(() {
                          saving = false;
                          error = e.toString().replaceAll('Exception: ', '');
                        });
                      }
                    },
              child: const Text('SIMPAN'),
            ),
          ],
        ),
      ),
    );

    if (created == true) _load();
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

    return Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _tambahSatpam,
          icon: const Icon(Icons.person_add),
          label: const Text('Tambah Satpam'),
        ),
        body: Column(
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
                  padding: const EdgeInsets.only(bottom: 80),
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
        ));
  }
}
