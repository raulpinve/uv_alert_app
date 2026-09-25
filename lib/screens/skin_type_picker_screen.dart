// lib/screens/skin_type_picker_screen.dart
import 'package:app/screens/uv_screen.dart' show gradientForUv;
import 'package:flutter/material.dart';

// ───────────────────────── Datos ─────────────────────────
// Los ids (1–6) son SUPUESTOS: deben coincidir con los skinTypeId de tu backend.

class SkinType {
  const SkinType(this.id, this.name, this.description, this.color);

  final int id;
  final String name;
  final String description;
  final Color color;
}

const skinTypes = <SkinType>[
  SkinType(
    1,
    'Piel muy clara',
    'Siempre se quema, nunca se broncea.',
    Color(0xFFF8E1D4),
  ),
  SkinType(
    2,
    'Piel clara',
    'Se quema con facilidad y se broncea poco.',
    Color(0xFFF1CDB0),
  ),
  SkinType(
    3,
    'Piel media',
    'A veces se quema, se broncea de forma gradual.',
    Color(0xFFE0AC85),
  ),
  SkinType(
    4,
    'Piel morena clara',
    'Se quema poco y se broncea fácil.',
    Color(0xFFC68B5F),
  ),
  SkinType(
    5,
    'Piel morena',
    'Rara vez se quema y se broncea mucho.',
    Color(0xFF8D5A3B),
  ),
  SkinType(6, 'Piel oscura', 'Casi nunca se quema.', Color(0xFF4A2C1D)),
];

SkinType? skinTypeById(int? id) {
  for (final t in skinTypes) {
    if (t.id == id) return t;
  }
  return null;
}

// ───────────────────────── Test ─────────────────────────
// Cada opción suma su índice. Total posible: 0–11.

class _Question {
  const _Question(this.text, this.options);
  final String text;
  final List<String> options;
}

const _questions = <_Question>[
  _Question('¿Cómo es el color natural de tu piel, sin sol?', [
    'Muy pálida',
    'Clara',
    'Media',
    'Morena',
    'Oscura',
  ]),
  _Question('Después de una hora al sol sin protección, tu piel…', [
    'Se quema con ardor o ampollas',
    'Se pone roja y duele',
    'Se pone un poco roja',
    'Casi nunca cambia',
  ]),
  _Question('¿Qué tanto te bronceas?', [
    'Nunca me bronceo',
    'Muy poco',
    'Poco a poco',
    'Con facilidad',
    'Muy rápido',
  ]),
];

int _typeForScore(int s) {
  if (s <= 1) return 1;
  if (s <= 3) return 2;
  if (s <= 5) return 3;
  if (s <= 7) return 4;
  if (s <= 9) return 5;
  return 6;
}

// ───────────────────────── Pantalla ─────────────────────────

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
    if (_step + 1 < _questions.length) {
      setState(() => _step++);
    } else {
      final id = _typeForScore(_score);
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
                  color: _ink.withOpacity(0.75),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              if (suggested != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
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
                children: skinTypes.map((t) => _card(t, width)).toList(),
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

  Widget _card(SkinType t, double width) {
    final selected = _selected == t.id;
    final checkColor = t.color.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;

    return GestureDetector(
      onTap: () => setState(() => _selected = t.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(selected ? 0.92 : 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _ink : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: t.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: selected ? Icon(Icons.check, color: checkColor) : null,
            ),
            const SizedBox(height: 10),
            Text(
              t.name,
              style: const TextStyle(
                color: _ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              t.description,
              style: TextStyle(
                color: _ink.withOpacity(0.7),
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Vista del test ──

  Widget _buildQuiz() {
    final q = _questions[_step];
    return ListView(
      key: ValueKey('quiz$_step'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Pregunta ${_step + 1} de ${_questions.length}',
          style: TextStyle(color: _ink.withOpacity(0.7), fontSize: 13),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (_step + 1) / _questions.length,
            minHeight: 6,
            backgroundColor: Colors.white.withOpacity(0.5),
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
              color: Colors.white.withOpacity(0.7),
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
