import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class PlanesScreen extends StatefulWidget {
  final int regionId;
  final Function onClienteAgregado;

  const PlanesScreen({
    Key? key,
    required this.regionId,
    required this.onClienteAgregado,
  }) : super(key: key);

  @override
  State<PlanesScreen> createState() => _PlanesScreenState();
}

class _PlanesScreenState extends State<PlanesScreen> {
  final db = DBHelper();
  List<Map> planes = [];
  bool mostrarFormulario = false;
  final nombreController = TextEditingController();
  final usuarioController = TextEditingController();
  final ipController = TextEditingController();
  String? planSeleccionado;
  String antenaSeleccionada = 'Propia';

  @override
  void initState() {
    super.initState();
    _cargarPlanes();
  }

  void _cargarPlanes() async {
    final data = await db.obtenerPlanesPorRegion(widget.regionId);
    setState(() => planes = data);
  }

  void _agregarCliente() async {
    if (nombreController.text.isEmpty ||
        usuarioController.text.isEmpty ||
        ipController.text.isEmpty ||
        planSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    try {
      await db.agregarCliente(
        regionId: widget.regionId,
        nombre: nombreController.text,
        nombreUsuario: usuarioController.text,
        ip: ipController.text,
        planId: int.parse(planSeleccionado!),
        antena: antenaSeleccionada,
      );
      widget.onClienteAgregado();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Cliente')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (planes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Card(
                color: Colors.orange,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Primero debes crear planes en esta región',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            )
          else ...[
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del cliente',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: usuarioController,
              decoration: const InputDecoration(
                labelText: 'Nombre de usuario',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ipController,
              decoration: const InputDecoration(
                labelText: 'IP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              decoration: const InputDecoration(
                labelText: 'Plan',
                border: OutlineInputBorder(),
              ),
              items: planes
                  .map((p) => DropdownMenuItem(
                        value: p['id'].toString(),
                        child: Text('${p['nombre']} - \$${p['precio']}'),
                      ))
                  .toList(),
              onChanged: (value) => planSeleccionado = value,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              value: antenaSeleccionada,
              decoration: const InputDecoration(
                labelText: 'Antena',
                border: OutlineInputBorder(),
              ),
              items: ['Propia', 'Rentada']
                  .map((a) => DropdownMenuItem(
                        value: a,
                        child: Text(a),
                      ))
                  .toList(),
              onChanged: (value) =>
                  setState(() => antenaSeleccionada = value ?? 'Propia'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _agregarCliente,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Agregar Cliente'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}