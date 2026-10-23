import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/item_model.dart';

/// Repositorio: consulta Firestore, ordena y limita resultados.
/// Expone un Stream tipado; no sabe nada de la interfaz.
class CatalogService {
  CatalogService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Cada inserción, edición o baja en la colección "items"
  /// produce una nueva emisión con la lista completa actualizada.
  Stream<List<ItemModel>> getCatalogStream({int limit = 50}) {
    return _firestore
        .collection('items')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(ItemModel.fromFirestore).toList(growable: false));
  }
}