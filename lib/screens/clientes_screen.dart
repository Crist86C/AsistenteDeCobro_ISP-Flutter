import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'region_clientes_screen.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({Key? key}) : super(key: key);

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final db = DBHelper();
  List<Map> regiones = [];

  @override
  void initState() {
    super.initState();
    _cargarRegiones();
  }

  void _cargarRegiones() async {
    final data = await db.obtenerRegiones();
    setState(() => regiones = data);
  }

  void _agregarRegion() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Región'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nombre de la región',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await db.agregarRegion(controller.text);
                _cargarRegiones();
                Navigator.pop(context);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Regiones')),
      body: regiones.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text('No hay regiones. Crea una nueva.'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _agregarRegion,
                    child: const Text('Crear Región'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: regiones.length,
              itemBuilder: (context, index) {
                final region = regiones[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.blue),
                    title: Text(
                      region['nombre'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      region['isCorteFinalizado'] == 1
                          ? 'Corte finalizado'
                          : 'Corte abierto',
                      style: TextStyle(
                        color: region['isCorteFinalizado'] == 1
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RegionClientesScreen(
                              regionId: region['id'],
                              regionNombre: region['nombre'],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarRegion,
        child: const Icon(Icons.add),
      ),
    );
  }
}