import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  static Database? _database;

  factory DBHelper() {
    return _instance;
  }

  DBHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'asistente_cobro.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Tabla de regiones
        await db.execute('''
          CREATE TABLE regiones (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            isCorteFinalizado INTEGER DEFAULT 0,
            fechaCorte TEXT
          )
        ''');

        // Tabla de planes
        await db.execute('''
          CREATE TABLE planes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            regionId INTEGER NOT NULL,
            nombre TEXT NOT NULL,
            precio REAL NOT NULL,
            FOREIGN KEY(regionId) REFERENCES regiones(id)
          )
        ''');

        // Tabla de clientes
        await db.execute('''
          CREATE TABLE clientes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            regionId INTEGER NOT NULL,
            nombre TEXT NOT NULL,
            nombreUsuario TEXT NOT NULL,
            ip TEXT NOT NULL,
            planId INTEGER NOT NULL,
            antena TEXT NOT NULL,
            FOREIGN KEY(regionId) REFERENCES regiones(id),
            FOREIGN KEY(planId) REFERENCES planes(id),
            UNIQUE(ip),
            UNIQUE(nombreUsuario)
          )
        ''');

        // Tabla de estados de corte (registro de pagos)
        await db.execute('''
          CREATE TABLE estadosCorte (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            clienteId INTEGER NOT NULL,
            regionId INTEGER NOT NULL,
            estado TEXT NOT NULL,
            fechaCorte TEXT NOT NULL,
            FOREIGN KEY(clienteId) REFERENCES clientes(id),
            FOREIGN KEY(regionId) REFERENCES regiones(id)
          )
        ''');

        // Tabla de servicios adicionales
        await db.execute('''
          CREATE TABLE serviciosAdicionales (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            corteId INTEGER NOT NULL,
            nombre TEXT NOT NULL,
            monto REAL NOT NULL,
            comentario TEXT,
            FOREIGN KEY(corteId) REFERENCES cortes(id)
          )
        ''');

        // Tabla de cortes finalizados
        await db.execute('''
          CREATE TABLE cortes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            regionId INTEGER NOT NULL,
            totalClientes INTEGER NOT NULL,
            clientesPagaron INTEGER NOT NULL,
            totalDinero REAL NOT NULL,
            serviciosAdicionales INTEGER NOT NULL,
            totalFinal REAL NOT NULL,
            fecha TEXT NOT NULL,
            FOREIGN KEY(regionId) REFERENCES regiones(id)
          )
        ''');

        // Tabla de anotaciones
        await db.execute('''
          CREATE TABLE anotaciones (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            titulo TEXT NOT NULL,
            contenido TEXT NOT NULL,
            esRecordatorio INTEGER DEFAULT 0,
            fecha TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // ========== REGIONES ==========
  Future<int> agregarRegion(String nombre) async {
    final db = await database;
    return await db.insert('regiones', {'nombre': nombre});
  }

  Future<List<Map>> obtenerRegiones() async {
    final db = await database;
    return await db.query('regiones');
  }

  Future<void> marcarCorteRegion(int regionId) async {
    final db = await database;
    await db.update(
      'regiones',
      {
        'isCorteFinalizado': 1,
        'fechaCorte': DateTime.now().toIso8601String()
      },
      where: 'id = ?',
      whereArgs: [regionId],
    );
  }

  Future<void> reiniciarCorteRegion(int regionId) async {
    final db = await database;
    await db.update(
      'regiones',
      {'isCorteFinalizado': 0, 'fechaCorte': null},
      where: 'id = ?',
      whereArgs: [regionId],
    );
  }

  // ========== PLANES ==========
  Future<int> agregarPlan(int regionId, String nombre, double precio) async {
    final db = await database;
    return await db.insert('planes', {
      'regionId': regionId,
      'nombre': nombre,
      'precio': precio,
    });
  }

  Future<List<Map>> obtenerPlanesPorRegion(int regionId) async {
    final db = await database;
    return await db.query(
      'planes',
      where: 'regionId = ?',
      whereArgs: [regionId],
    );
  }

  // ========== CLIENTES ==========
  Future<int> agregarCliente({
    required int regionId,
    required String nombre,
    required String nombreUsuario,
    required String ip,
    required int planId,
    required String antena,
  }) async {
    final db = await database;
    try {
      return await db.insert('clientes', {
        'regionId': regionId,
        'nombre': nombre,
        'nombreUsuario': nombreUsuario,
        'ip': ip,
        'planId': planId,
        'antena': antena,
      });
    } catch (e) {
      throw Exception('Error al agregar cliente: $e');
    }
  }

  Future<List<Map>> obtenerClientesPorRegion(int regionId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT c.*, p.precio, p.nombre as nombrePlan
      FROM clientes c
      JOIN planes p ON c.planId = p.id
      WHERE c.regionId = ?
    ''', [regionId]);
  }

  Future<void> actualizarCliente({
    required int clienteId,
    required String nombre,
    required String nombreUsuario,
    required String ip,
    required int planId,
    required String antena,
  }) async {
    final db = await database;
    await db.update(
      'clientes',
      {
        'nombre': nombre,
        'nombreUsuario': nombreUsuario,
        'ip': ip,
        'planId': planId,
        'antena': antena,
      },
      where: 'id = ?',
      whereArgs: [clienteId],
    );
  }

  Future<void> eliminarCliente(int clienteId) async {
    final db = await database;
    await db.delete('clientes', where: 'id = ?', whereArgs: [clienteId]);
  }

  // ========== ESTADOS DE CORTE ==========
  Future<void> guardarEstadoCliente(
      int clienteId, int regionId, String estado, String fechaCorte) async {
    final db = await database;
    
    // Eliminar estado anterior si existe
    await db.delete(
      'estadosCorte',
      where: 'clienteId = ? AND fechaCorte = ?',
      whereArgs: [clienteId, fechaCorte],
    );

    await db.insert('estadosCorte', {
      'clienteId': clienteId,
      'regionId': regionId,
      'estado': estado,
      'fechaCorte': fechaCorte,
    });
  }

  Future<String?> obtenerEstadoCliente(
      int clienteId, String fechaCorte) async {
    final db = await database;
    final result = await db.query(
      'estadosCorte',
      where: 'clienteId = ? AND fechaCorte = ?',
      whereArgs: [clienteId, fechaCorte],
    );
    return result.isNotEmpty ? result.first['estado'] as String? : null;
  }

  Future<List<Map>> obtenerEstadosCorteRegion(
      int regionId, String fechaCorte) async {
    final db = await database;
    return await db.query(
      'estadosCorte',
      where: 'regionId = ? AND fechaCorte = ?',
      whereArgs: [regionId, fechaCorte],
    );
  }

  // ========== SERVICIOS ADICIONALES ==========
  Future<int> agregarServicioAdicional(
      int corteId, String nombre, double monto, String? comentario) async {
    final db = await database;
    return await db.insert('serviciosAdicionales', {
      'corteId': corteId,
      'nombre': nombre,
      'monto': monto,
      'comentario': comentario,
    });
  }

  Future<List<Map>> obtenerServiciosCorte(int corteId) async {
    final db = await database;
    return await db.query(
      'serviciosAdicionales',
      where: 'corteId = ?',
      whereArgs: [corteId],
    );
  }

  // ========== CORTES ==========
  Future<int> guardarCorte({
    required String nombre,
    required int regionId,
    required int totalClientes,
    required int clientesPagaron,
    required double totalDinero,
    required int serviciosAdicionales,
    required double totalFinal,
  }) async {
    final db = await database;
    return await db.insert('cortes', {
      'nombre': nombre,
      'regionId': regionId,
      'totalClientes': totalClientes,
      'clientesPagaron': clientesPagaron,
      'totalDinero': totalDinero,
      'serviciosAdicionales': serviciosAdicionales,
      'totalFinal': totalFinal,
      'fecha': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map>> obtenerCortes() async {
    final db = await database;
    return await db.query('cortes', orderBy: 'fecha DESC');
  }

  Future<List<Map>> obtenerCortesPorRegion(int regionId) async {
    final db = await database;
    return await db.query(
      'cortes',
      where: 'regionId = ?',
      whereArgs: [regionId],
      orderBy: 'fecha DESC',
    );
  }

  // ========== ANOTACIONES ==========
  Future<int> agregarAnotacion(String titulo, String contenido,
      {bool esRecordatorio = false}) async {
    final db = await database;
    return await db.insert('anotaciones', {
      'titulo': titulo,
      'contenido': contenido,
      'esRecordatorio': esRecordatorio ? 1 : 0,
      'fecha': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map>> obtenerAnotaciones() async {
    final db = await database;
    return await db.query('anotaciones', orderBy: 'fecha DESC');
  }

  Future<void> eliminarAnotacion(int id) async {
    final db = await database;
    await db.delete('anotaciones', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> limpiarBD() async {
    final db = await database;
    await db.delete('anotaciones');
    await db.delete('cortes');
    await db.delete('serviciosAdicionales');
    await db.delete('estadosCorte');
    await db.delete('clientes');
    await db.delete('planes');
    await db.delete('regiones');
  }
}
