// lib/screens/profile_screen.dart
import 'package:app/features/profile/presentation/screens/skin_type_picker_screen.dart';
import 'package:app/features/profile/data/user_service.dart';
import 'package:app/features/uv/presentation/screens/uv_screen.dart' show gradientForUv;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Hace pop con `true` si el usuario cambió algo que afecta la pantalla UV
/// (por ejemplo el tipo de piel), para que la pantalla anterior se refresque.
/// Requiere Flutter 3.22+ (PopScope con onPopInvokedWithResult).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _ink = Color(0xFF1F2A37);

  final _service = UserService();
  UserProfile? _profile;
  bool _loading = true;
  String? _error;
  bool _changed = false;

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
      final p = await _service.fetchProfile();
      if (!mounted) return;
      setState(() => _profile = p);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _editName() async {
    final profile = _profile!;
    final controller = TextEditingController(text: profile.name);

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tu nombre'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty || newName == profile.name) return;

    try {
      await _service.updateProfile(name: newName);
      if (!mounted) return;
      setState(() => _profile = profile.copyWith(name: newName));
    } catch (e) {
      _snack('No se pudo guardar el nombre.');
    }
  }

  Future<void> _editSkinType() async {
    final profile = _profile!;
    final id = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => SkinTypePickerScreen(initialId: profile.skinTypeId),
      ),
    );

    if (id == null || id == profile.skinTypeId) return;

    try {
      await _service.updateProfile(skinTypeId: id);
      if (!mounted) return;
      setState(() {
        _profile = profile.copyWith(skinTypeId: id);
        _changed = true;
      });
    } catch (e) {
      _snack('No se pudo guardar el tipo de piel.');
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    // AuthGate mostrará el login; cerramos las pantallas apiladas.
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: gradientForUv(2)),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: _ink),
                        onPressed: () => Navigator.pop(context, _changed),
                      ),
                      const Text(
                        'Perfil',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _body()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    final profile = _profile;

    if (profile == null) {
      return Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _error ?? 'Sin datos',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _ink),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _load,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
      );
    }

    final skin = skinTypeById(profile.skinTypeId);
    final initial = profile.name.isNotEmpty
        ? profile.name[0].toUpperCase()
        : '?';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Center(
          child: CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white.withOpacity(0.65),
            child: Text(
              initial,
              style: const TextStyle(
                color: _ink,
                fontSize: 34,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            profile.name.isEmpty ? 'Sin nombre' : profile.name,
            style: const TextStyle(
              color: _ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Center(
          child: Text(
            profile.email,
            style: TextStyle(color: _ink.withOpacity(0.7), fontSize: 13),
          ),
        ),
        const SizedBox(height: 24),
        _Section(
          children: [
            _Tile(
              leading: const Icon(Icons.person_outline, color: _ink),
              title: 'Nombre',
              value: profile.name.isEmpty ? 'Agregar' : profile.name,
              onTap: _editName,
            ),
            const Divider(height: 1, indent: 64),
            _Tile(
              leading: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: skin?.color ?? Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: skin == null
                    ? const Icon(Icons.help_outline, size: 16, color: _ink)
                    : null,
              ),
              title: 'Tipo de piel',
              value: skin?.name ?? 'Sin configurar',
              onTap: _editSkinType,
            ),
          ],
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _signOut,
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFA92B2B),
            minimumSize: const Size.fromHeight(50),
            side: BorderSide(color: const Color(0xFFA92B2B).withOpacity(0.5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.leading,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final Widget leading;
  final String title, value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF1F2A37);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(width: 32, child: Center(child: leading)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: ink.withOpacity(0.65),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: ink.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
