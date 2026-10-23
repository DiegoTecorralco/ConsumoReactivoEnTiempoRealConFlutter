import 'package:cloud_firestore/cloud_firestore.dart';

/// Convierte un documento remoto de Firestore en un objeto tipado y seguro.
class ItemModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final DateTime? createdAt;

  const ItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.createdAt,
  });

  /// Valida nulos y tipos: nunca lanza por un campo faltante.
  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    final created = data['createdAt'];

    return ItemModel(
      id: doc.id,
      title: (data['title'] as String?)?.trim().isNotEmpty == true
          ? data['title'] as String
          : 'Sin título',
      description: (data['description'] as String?) ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }
}