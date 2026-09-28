import 'dart:io';

import 'package:app/features/profile/data/models/user_profile.dart';
import 'package:app/features/profile/data/services/user_service.dart';
import 'package:app/features/profile/data/models/skin_type.dart';
import 'package:app/features/profile/presentation/screens/skin_type_picker_screen.dart';
import 'package:app/features/profile/presentation/widgets/profile_section.dart';
import 'package:app/features/profile/presentation/widgets/profile_tile.dart';
import 'package:app/features/uv/presentation/logic/uv_level.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app/core/network/api_exception.dart';

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
      setState(() => _error = _messageFrom(e, 'No se pudo cargar el perfil.'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  String _messageFrom(Object e, String fallback) {
    if (e is ApiException) return e.displayMessage;
    if (e is SocketException) return 'Sin conexión a internet.';
    return fallback;
  }

  Future<void> _editName() async {
    final profile = _profile!;

    final saved = await showDialog<({String first, String last})>(
      context: context,
      builder: (_) => _EditNameDialog(profile: profile, service: _service),
    );

    if (saved == null || !mounted) return;
    setState(() {
      _profile = profile.copyWith(firstName: saved.first, lastName: saved.last);
      _changed = true;
    });
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
      final refreshed = await _service.fetchProfile();
      if (!mounted) return;
      setState(() {
        _profile = refreshed;
        _changed = true;
      });
    } catch (e) {
      if (!mounted) return;
      _snack(_messageFrom(e, 'No se pudo guardar el tipo de piel.'));
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context, _changed),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: _ink,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
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
    final fullName = profile.fullName.trim();
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Center(
          child: CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white.withValues(alpha: 0.65),
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
            fullName.isEmpty ? 'Sin nombre' : fullName,
            style: const TextStyle(
              color: _ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 24),
        ProfileSection(
          children: [
            ProfileTile(
              leading: const Icon(Icons.person_outline, color: _ink),
              title: 'Nombre',
              value: fullName.isEmpty ? 'Agregar' : fullName,
              onTap: _editName,
            ),
            const Divider(height: 1, indent: 64),
            ProfileTile(
              leading: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: skin?.color ?? Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
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
        SizedBox(
          width: double.infinity,
          height: 52,
          child: Material(
            color: Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _signOut,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: Color(0xFFA92B2B), size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Cerrar sesión',
                      style: TextStyle(
                        color: Color(0xFFA92B2B),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog({required this.profile, required this.service});

  final UserProfile profile;
  final UserService service;

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  static const _accent = Color(0xFF2F6FDB);

  late final TextEditingController _firstCtrl;
  late final TextEditingController _lastCtrl;
  Map<String, String> _errors = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _firstCtrl = TextEditingController(text: widget.profile.firstName);
    _lastCtrl = TextEditingController(text: widget.profile.lastName);
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec(String hint, String? errorText) => InputDecoration(
    hintText: hint,
    errorText: errorText,
    filled: true,
    fillColor: _accent.withValues(alpha: 0.06),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _accent, width: 1.5),
    ),
  );

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _submit() async {
    final first = _firstCtrl.text.trim();
    final last = _lastCtrl.text.trim();

    if (first == widget.profile.firstName && last == widget.profile.lastName) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _saving = true;
      _errors = {};
    });

    try {
      await widget.service.updateProfile(firstName: first, lastName: last);
      if (mounted) Navigator.pop(context, (first: first, last: last));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errors = e.fieldErrorMap;
      });
      if (e.fieldErrors.isEmpty) _snack(e.message);
    } on SocketException {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Sin conexión a internet.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('No se pudo guardar el nombre.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'Tu nombre',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _firstCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            cursorColor: _accent,
            decoration: _dec('Nombre', _errors['firstName']),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _lastCtrl,
            textCapitalization: TextCapitalization.words,
            cursorColor: _accent,
            decoration: _dec('Apellido', _errors['lastName']),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: Colors.grey),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
