import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import 'package:share_plus/share_plus.dart';

class RegionCorteScreen extends StatefulWidget {
  final int regionId;
  final String regionNombre;

  const RegionCorteScreen({
    Key? key,
    required this.regionId,
    required this.regionNombre,
  }) : super(key: key);

  @override
  State<RegionCorteScreen> createState() => _RegionCorteScreenState();
}

class _RegionCorteScreenState extends State<RegionCorteScreen> {
  final db = DBHelper();
  List<Map> clientes = [];
  List<Map> servicios = [];
  double totalDinero = 0;
  int clientesPagaron = 0;
  final fechaCorteActual = DateTime.now().toIso8601String().split('T')[0];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() async {
    final clientesData =
        await db.obtenerClientesPorRegion(widget.regionId);
    
    // Obtener los estados del corte actual
    for (var cliente in clientesData) {
      final estado = await db.obtenerEstadoCliente(
          cliente['id'], fechaCorteActual);
      cliente['estadoCorte'] = estado;
      if (estado == 'Pagó') {
        clientesPagaron++;
        totalDinero += (cliente['precio'] as num).toDouble();
      }
    }

    setState(() {
      clientes = clientesData;
    });
  }

  void _mostrarEstadoDialog(Map cliente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Estado de ${cliente['nombre']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
             title: const Text('Pagó'),
             value: 'Pagó',
             groupValue: cliente['estadoCorte'] as String?,
             onChanged: (value) => _guardarEstado(cliente['id'], value ?? 'Pendiente'),
            ),
            RadioListTile<String>(
             title: const Text('Inactivo'),
             value: 'Inactivo',
             groupValue: cliente['estadoCorte'] as String?,
             onChanged: (value) => _guardarEstado(cliente['id'], value ?? 'Pendiente'),
            ),
            RadioListTile<String>(
             title: const Text('Pendiente'),
             value: 'Pendiente',
             groupValue: cliente['estadoCorte'] as String?,
             onChanged: (value) => _guardarEstado(cliente['id'], value ?? 'Pendiente'),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _guardarEstado(int clienteId, String estado) async {
    await db.guardarEstadoCliente(
        clienteId, widget.regionId, estado, fechaCorteActual);
    Navigator.pop(context);
    _cargarDatos(); // Recargar para actualizar totales
  }

  void _agregarServicioAdicional() {
    final nombreController = TextEditingController();
    final montoController = TextEditingController();
    final comentarioController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Servicio Adicional'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del servicio',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: montoController,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: comentarioController,
                decoration: const InputDecoration(
                  labelText: 'Comentario',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nombreController.text.isNotEmpty &&
                  montoController.text.isNotEmpty) {
                setState(() {
                  servicios.add({
                    'nombre': nombreController.text,
                    'monto': double.parse(montoController.text),
                    'comentario': comentarioController.text,
                  });
                  totalDinero += double.parse(montoController.text);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _realizarCorte() {
    final nombreController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nombre del Corte'),
        content: TextField(
          controller: nombreController,
          decoration: const InputDecoration(
            hintText: 'Ej: Corte Octubre 2024',
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
              if (nombreController.text.isNotEmpty) {
                // Crear el texto del reporte
                final textoReporte = '''
╔════════════════════════════════╗
║      CORTE DE COBRO - ISP       ║
╚════════════════════════════════╝

📋 NOMBRE: ${nombreController.text}
📍 REGIÓN: ${widget.regionNombre}
📅 FECHA: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

👥 CLIENTES:
  • Total: ${clientes.length}
  • Pagaron: $clientesPagaron
  
💰 INGRESOS:
  • Por planes: \$${totalDinero.toStringAsFixed(2)}
  • Servicios adicionales: ${servicios.length}
${servicios.map((s) => '    - ${s['nombre']}: \$${s['monto']}').join('\n')}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💵 TOTAL: \$${(totalDinero + servicios.fold(0, (sum, s) => sum + (s['monto'] as num))).toStringAsFixed(2)}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                ''';

                // Compartir por WhatsApp
                Share.share(textoReporte);

                // Guardar en DB
                final corteId = await db.guardarCorte(
                  nombre: nombreController.text,
                  regionId: widget.regionId,
                  totalClientes: clientes.length,
                  clientesPagaron: clientesPagaron,
                  totalDinero: totalDinero,
                  serviciosAdicionales: servicios.length,
                  totalFinal: totalDinero +
                      servicios.fold(0, (sum, s) => sum + (s['monto'] as num)),
                );

                // Guardar servicios adicionales
                for (var servicio in servicios) {
                  await db.agregarServicioAdicional(
                    corteId,
                    servicio['nombre'],
                    servicio['monto'],
                    servicio['comentario'],
                  );
                }

                // Marcar región como corte finalizado
                await db.marcarCorteRegion(widget.regionId);

                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: const Text('Compartir por WhatsApp'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Corte - ${widget.regionNombre}')),
      body: Column(
        children: [
          Expanded(
            child: clientes.isEmpty
                ? const Center(child: Text('No hay clientes'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: clientes.length,
                    itemBuilder: (context, index) {
                      final cliente = clientes[index];
                      final estado = cliente['estadoCorte'] ?? 'Sin marcar';
                      Color colorEstado = Colors.grey;
                      if (estado == 'Pagó') colorEstado = Colors.green;
                      if (estado == 'Inactivo') colorEstado = Colors.orange;
                      if (estado == 'Pendiente') colorEstado = Colors.red;

                      return Card(
                        child: ListTile(
                          title: Text(cliente['nombre']),
                          subtitle: Text(
                              '${cliente['nombrePlan']} - \$${cliente['precio']}'),
                          trailing: GestureDetector(
                            onTap: () => _mostrarEstadoDialog(cliente),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: colorEstado,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                estado,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total: \$${(totalDinero + servicios.fold(0, (sum, s) => sum + (s['monto'] as num))).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (servicios.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Servicios adicionales:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...servicios
                          .map((s) =>
                              Text('• ${s['nombre']}: \$${s['monto']}'))
                          .toList(),
                      const SizedBox(height: 12),
                    ],
                  ),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _agregarServicioAdicional,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text('Agregar Servicio'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _realizarCorte,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Realizar Corte'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
