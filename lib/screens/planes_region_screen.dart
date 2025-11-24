import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class PlanesRegionScreen extends StatefulWidget {
  final int regionId;
  final String regionNombre;

  const PlanesRegionScreen({
    Key? key,
    required this.regionId,
    required this.regionNombre,
  }) : super(key: key);

  @override
  State<PlanesRegionScreen> createState() => _PlanesRegionScreenState();
}

class _PlanesRegionScreenState extends State<PlanesRegionScreen> {
  final db = DBHelper();
  List<Map> planes = [];

  @override
  void initState() {
    super.initState();
    _cargarPlanes();
  }

  void _cargarPlanes() async {
    final data = await db.obtenerPlanesPorRegion(widget.regionId);
    setState(() => planes = data);
  }

  void _agregarPlan() {
    final nombreController = TextEditingController();
    final precioController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del plan (Ej: Internet 20MB)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: precioController,
              decoration: const InputDecoration(
                labelText: 'Precio (Ej: 300)',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
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
              if (nombreController.text.isNotEmpty &&
                  precioController.text.isNotEmpty) {
                try {
                  await db.agregarPlan(
                    widget.regionId,
                    nombreController.text,
                    double.parse(precioController.text),
                  );
                  _cargarPlanes();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Plan agregado exitosamente')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Completa todos los campos')),
                );
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _editarPlan(Map plan) {
    final nombreController = TextEditingController(text: plan['nombre']);
    final precioController =
        TextEditingController(text: plan['precio'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del plan',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: precioController,
              decoration: const InputDecoration(
                labelText: 'Precio',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
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
              if (nombreController.text.isNotEmpty &&
                  precioController.text.isNotEmpty) {
                try {
                  await db.actualizarPlan(
                    plan['id'],
                    nombreController.text,
                    double.parse(precioController.text),
                  );
                  _cargarPlanes();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Plan actualizado')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _eliminarPlan(int planId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Plan'),
        content: const Text('¿Estás seguro de eliminar este plan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await db.eliminarPlan(planId);
                _cargarPlanes();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Plan eliminado')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Planes - ${widget.regionNombre}'),
      ),
      body: planes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.card_giftcard, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text('No hay planes. Crea uno nuevo.'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _agregarPlan,
                    child: const Text('Crear Plan'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: planes.length,
              itemBuilder: (context, index) {
                final plan = planes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.card_giftcard, color: Colors.blue),
                    title: Text(
                      plan['nombre'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('\$${plan['precio'].toStringAsFixed(2)}'),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'editar',
                          child: Text('Editar'),
                        ),
                        const PopupMenuItem(
                          value: 'eliminar',
                          child: Text('Eliminar'),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'editar') {
                          _editarPlan(plan);
                        } else if (value == 'eliminar') {
                          _eliminarPlan(plan['id']);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarPlan,
        child: const Icon(Icons.add),
      ),
    );
  }
}
