import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class InformacionScreen extends StatefulWidget {
  const InformacionScreen({Key? key}) : super(key: key);

  @override
  State<InformacionScreen> createState() => _InformacionScreenState();
}

class _InformacionScreenState extends State<InformacionScreen> {
  final db = DBHelper();
  List<Map> anotaciones = [];

  @override
  void initState() {
    super.initState();
    _cargarAnotaciones();
  }

  void _cargarAnotaciones() async {
    final data = await db.obtenerAnotaciones();
    setState(() => anotaciones = data);
  }

  void _agregarAnotacion({bool esRecordatorio = false}) {
    final tituloController = TextEditingController();
    final contenidoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(esRecordatorio ? 'Nuevo Recordatorio' : 'Nueva Anotación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tituloController,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contenidoController,
              decoration: const InputDecoration(
                labelText: 'Contenido',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (tituloController.text.isNotEmpty) {
                await db.agregarAnotacion(
                  tituloController.text,
                  contenidoController.text,
                  esRecordatorio: esRecordatorio,
                );
                _cargarAnotaciones();
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Información')),
      body: anotaciones.isEmpty
          ? const Center(
              child: Text('No hay anotaciones'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: anotaciones.length,
              itemBuilder: (context, index) {
                final anotacion = anotaciones[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: anotacion['esRecordatorio'] == 1
                      ? Colors.orange.shade50
                      : Colors.white,
                  child: ListTile(
                    leading: Icon(
                      anotacion['esRecordatorio'] == 1
                          ? Icons.alarm
                          : Icons.note,
                      color: anotacion['esRecordatorio'] == 1
                          ? Colors.orange
                          : Colors.blue,
                    ),
                    title: Text(anotacion['titulo']),
                    subtitle: Text(anotacion['contenido']),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await db.eliminarAnotacion(anotacion['id']);
                        _cargarAnotaciones();
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'recordatorio',
            onPressed: () => _agregarAnotacion(esRecordatorio: true),
            backgroundColor: Colors.orange,
            child: const Icon(Icons.alarm),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'anotacion',
            onPressed: () => _agregarAnotacion(),
            backgroundColor: Colors.blue,
            child: const Icon(Icons.note_add),
          ),
        ],
      ),
    );
  }
}