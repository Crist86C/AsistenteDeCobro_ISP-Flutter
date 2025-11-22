import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'planes_screen.dart';

class RegionClientesScreen extends StatefulWidget {
  final int regionId;
  final String regionNombre;

  const RegionClientesScreen({
    Key? key,
    required this.regionId,
    required this.regionNombre,
  }) : super(key: key);

  @override
  State<RegionClientesScreen> createState() => _RegionClientesScreenState();
}

class _RegionClientesScreenState extends State<RegionClientesScreen> {
  final db = DBHelper();
  List<Map> clientes = [];

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  void _cargarClientes() async {
    final data = await db.obtenerClientesPorRegion(widget.regionId);
    setState(() => clientes = data);
  }

  void _agregarCliente() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlanesScreen(
          regionId: widget.regionId,
          onClienteAgregado: _cargarClientes,
        ),
      ),
    );
  }

  void _editarCliente(Map cliente) {
    // Similar a agregar pero con los datos precargados
    _agregarCliente();
  }

  void _eliminarCliente(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: const Text('¿Estás seguro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await db.eliminarCliente(id);
              _cargarClientes();
              Navigator.pop(context);
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
        title: Text('${widget.regionNombre} - Clientes'),
      ),
      body: clientes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text('No hay clientes en esta región'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _agregarCliente,
                    child: const Text('Agregar Cliente'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: clientes.length,
              itemBuilder: (context, index) {
                final cliente = clientes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(cliente['nombre']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Usuario: ${cliente['nombreUsuario']}'),
                        Text('IP: ${cliente['ip']}'),
                        Text('Plan: ${cliente['nombrePlan']} - \$${cliente['precio']}'),
                        Text('Antena: ${cliente['antena']}'),
                      ],
                    ),
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
                          _editarCliente(cliente);
                        } else if (value == 'eliminar') {
                          _eliminarCliente(cliente['id']);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarCliente,
        child: const Icon(Icons.add),
      ),
    );
  }
}