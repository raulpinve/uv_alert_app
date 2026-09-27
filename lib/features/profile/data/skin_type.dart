// lib/features/profile/data/skin_type.dart
import 'package:flutter/material.dart';

// Los ids (1–6) son SUPUESTOS: deben coincidir con los skinTypeId del backend.
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
