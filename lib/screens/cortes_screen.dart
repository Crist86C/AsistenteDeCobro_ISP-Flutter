import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'region_corte_screen.dart';

class CortesScreen extends StatefulWidget {
  const CortesScreen({Key? key}) : super(key: key);

  @override
  State<CortesScreen> createState() => _CortesScreenState();
}

class _CortesScreenState extends State<CortesScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cortes')),
      body: regiones.isEmpty
          ? const Center(child: Text('No hay regiones'))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: regiones.length,
              itemBuilder: (context, index) {
                final region = regiones[index];
                final corteFinalizado = region['isCorteFinalizado'] == 1;
                return GestureDetector(
                  onTap: corteFinalizado
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RegionCorteScreen(
                                regionId: region['id'],
                                regionNombre: region['nombre'],
                              ),
                            ),
                          );
                        },
                  child: Card(
                    color: corteFinalizado ? Colors.grey : Colors.blue,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 48,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            region['nombre'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (corteFinalizado)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'Corte finalizado',
                                style: TextStyle(
                                  color: Colors.yellow,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}