// lib/features/profile/presentation/logic/skin_quiz.dart

/// Preguntas del test rápido para sugerir un tipo de piel.
/// Cada opción suma su índice. Total posible: 0–11.
class SkinQuizQuestion {
  const SkinQuizQuestion(this.text, this.options);

  final String text;
  final List<String> options;
}

const skinQuizQuestions = <SkinQuizQuestion>[
  SkinQuizQuestion('¿Cómo es el color natural de tu piel, sin sol?', [
    'Muy pálida',
    'Clara',
    'Media',
    'Morena',
    'Oscura',
  ]),
  SkinQuizQuestion('Después de una hora al sol sin protección, tu piel…', [
    'Se quema con ardor o ampollas',
    'Se pone roja y duele',
    'Se pone un poco roja',
    'Casi nunca cambia',
  ]),
  SkinQuizQuestion('¿Qué tanto te bronceas?', [
    'Nunca me bronceo',
    'Muy poco',
    'Poco a poco',
    'Con facilidad',
    'Muy rápido',
  ]),
];

/// Convierte el puntaje acumulado del test (0–11) en un skinTypeId (1–6).
int skinTypeIdForScore(int score) {
  if (score <= 1) return 1;
  if (score <= 3) return 2;
  if (score <= 5) return 3;
  if (score <= 7) return 4;
  if (score <= 9) return 5;
  return 6;
}
