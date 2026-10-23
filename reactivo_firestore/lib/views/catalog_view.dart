import 'package:flutter/material.dart';

import '../models/item_model.dart';
import '../services/catalog_service.dart';

/// Vista: se limita a renderizar el Stream mediante StreamBuilder.
/// StreamBuilder se suscribe en initState y cancela en dispose,
/// por lo que no hay suscripciones zombi.
class CatalogView extends StatefulWidget {
  const CatalogView({super.key});

  @override
  State<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<CatalogView> {
  final CatalogService _service = CatalogService();
  late Stream<List<ItemModel>> _stream;

  @override
  void initState() {
    super.initState();
    // Se crea una sola vez: evita reconectar en cada rebuild.
    _stream = _service.getCatalogStream();
  }

  void _retry() {
    setState(() => _stream = _service.getCatalogStream());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo en tiempo real')),
      body: StreamBuilder<List<ItemModel>>(
        stream: _stream,
        builder: (context, snapshot) {
          // Error: mensaje comprensible, sin trazas técnicas.
          if (snapshot.hasError) {
            debugPrint('Error en el stream: ${snapshot.error}');
            return _MessageState(
              icon: Icons.cloud_off,
              message: 'No pudimos cargar el catálogo.\n'
                  'Revisa tu conexión e inténtalo de nuevo.',
              actionLabel: 'Reintentar',
              onAction: _retry,
            );
          }

          // Loading: primera respuesta o negociación de conexión.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? const <ItemModel>[];

          // Empty: lista sin registros.
          if (items.isEmpty) {
            return const _MessageState(
              icon: Icons.inbox_outlined,
              message: 'Aún no hay registros en el catálogo.',
            );
          }

          // Success: ListView.builder recicla los elementos visibles.
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) => _ItemCard(item: items[index]),
          );
        },
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});

  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(item.title),
        subtitle: item.description.isEmpty ? null : Text(item.description),
        trailing: Text(
          '\$${item.price.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}