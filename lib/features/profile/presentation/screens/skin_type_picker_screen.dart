import 'package:app/features/profile/data/skin_type.dart';
import 'package:app/features/profile/presentation/logic/skin_quiz.dart';
import 'package:app/features/profile/presentation/widgets/skin_type_card.dart';
import 'package:app/features/uv/presentation/logic/uv_level.dart';
import 'package:flutter/material.dart';

/// Devuelve el id del tipo de piel elegido con Navigator.pop, o null si se cancela.
class SkinTypePickerScreen extends StatefulWidget {
  const SkinTypePickerScreen({super.key, this.initialId});

  final int? initialId;

  @override
  State<SkinTypePickerScreen> createState() => _SkinTypePickerScreenState();
}

class _SkinTypePickerScreenState extends State<SkinTypePickerScreen> {
  static const _ink = Color(0xFF1F2A37);

  int? _selected;
  int? _suggested;
  int _step = -1; // -1 = vista de colores, 0.. = pregunta del test
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialId;
  }

  void _startQuiz() => setState(() {
    _step = 0;
    _score = 0;
  });

  void _answer(int index) {
    _score += index;
    if (_step + 1 < skinQuizQuestions.length) {
      setState(() => _step++);
    } else {
      final id = skinTypeIdForScore(_score);
      setState(() {
        _selected = id;
        _suggested = id;
        _step = -1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inQuiz = _step >= 0;
    return Scaffold(
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
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Tipo de piel',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: inQuiz ? _buildQuiz() : _buildColors(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Vista de colores ──

  Widget _buildColors() {
    final width = (MediaQuery.of(context).size.width - 32 - 12) / 2;
    final suggested = skinTypeById(_suggested);

    return Column(
      key: const ValueKey('colors'),
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              const Text(
                '¿Cuál se parece más a tu piel?',
                style: TextStyle(
                  color: _ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Elige según el tono de tu piel sin exposición al sol. '
                'Lo usamos para calcular en cuántos minutos podrías quemarte.',
                style: TextStyle(
                  color: _ink.withValues(alpha: 0.75),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              if (suggested != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: Color(0xFF2F6FDB),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Según tus respuestas, podría ser "${suggested.name}". '
                          'Puedes cambiarlo si no te identificas.',
                          style: const TextStyle(color: _ink, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: skinTypes
                    .map(
                      (t) => SkinTypeCard(
                        type: t,
                        width: width,
                        selected: _selected == t.id,
                        onTap: () => setState(() => _selected = t.id),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _startQuiz,
                  icon: const Icon(Icons.help_outline, size: 18),
                  label: const Text('No estoy seguro, hacer test rápido'),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _selected == null
                  ? null
                  : () => Navigator.pop(context, _selected),
              child: const Text('Guardar'),
            ),
          ),
        ),
      ],
    );
  }

  // ── Vista del test ──

  Widget _buildQuiz() {
    final q = skinQuizQuestions[_step];
    return ListView(
      key: ValueKey('quiz$_step'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Pregunta ${_step + 1} de ${skinQuizQuestions.length}',
          style: TextStyle(color: _ink.withValues(alpha: 0.7), fontSize: 13),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (_step + 1) / skinQuizQuestions.length,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          q.text,
          style: const TextStyle(
            color: _ink,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < q.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _answer(i),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    q.options[i],
                    style: const TextStyle(color: _ink, fontSize: 15),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _step = -1),
            child: const Text('Cancelar test'),
          ),
        ),
      ],
    );
  }
}
