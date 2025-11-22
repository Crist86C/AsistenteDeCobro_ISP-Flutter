import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class GraficasScreen extends StatefulWidget {
  const GraficasScreen({Key? key}) : super(key: key);

  @override
  State<GraficasScreen> createState() => _GraficasScreenState();
}

class _GraficasScreenState extends State<GraficasScreen> {
  final db = DBHelper();
  List<Map> cortes = [];

  @override
  void initState() {
    super.initState();
    _cargarCortes();
  }

  void _cargarCortes() async {
    final data = await db.obtenerCortes();
    setState(() => cortes = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gráficas')),
      body: cortes.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text('No hay cortes registrados'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: cortes.length,
              itemBuilder: (context, index) {
                final corte = cortes[index];
                final fecha =
                    DateTime.parse(corte['fecha']).toLocal();
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(corte['nombre']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Fecha: ${fecha.day}/${fecha.month}/${fecha.year}'),
                        Text(
                            'Clientes: ${corte['clientesPagaron']}/${corte['totalClientes']}'),
                        Text(
                            'Total: \$${corte['totalFinal'].toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
