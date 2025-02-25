// lib/data/datasources/local/database_helper.dart
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart';
import 'dart:async';
import '../../../core/constants/db_constants.dart';
import '../../models/verb_model.dart';

/// Helper para gestionar operaciones con la base de datos SQLite.
///
/// Esta clase implementa el patrón Singleton para asegurar
/// una única instancia de la base de datos en toda la aplicación.
class DatabaseHelper {
  // Implementación singleton
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static sqflite.Database? _database;

  /// Obtiene la instancia de la base de datos, inicializándola si es necesario
  Future<sqflite.Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Inicializa la base de datos
  Future<sqflite.Database> _initDatabase() async {
    try {
      final dbPath = await sqflite.getDatabasesPath();
      final path = join(dbPath, DBConstants.dbName);

      return await sqflite.openDatabase(
        path,
        version: DBConstants.dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      throw CustomDatabaseException(
        'Failed to initialize database: ${e.toString()}',
        e,
      );
    }
  }

  /// Callback ejecutado cuando se crea la base de datos por primera vez
  Future<void> _onCreate(sqflite.Database db, int version) async {
    try {
      // Crear tabla principal de verbos
      await db.execute(DBConstants.createVerbsTableQuery);

      // Crear índices para búsqueda eficiente
      await db.execute(DBConstants.createSearchTermsIndexQuery);
      await db.execute(DBConstants.createVerbFormsIndexQuery);
    } catch (e) {
      throw CustomDatabaseException(
        'Failed to create database tables: ${e.toString()}',
        e,
      );
    }
  }

  /// Callback ejecutado cuando se actualiza la versión de la base de datos
  Future<void> _onUpgrade(
    sqflite.Database db,
    int oldVersion,
    int newVersion,
  ) async {
    try {
      // Manejar actualizaciones incrementales según la versión
      if (oldVersion < 2) {
        // Código para actualizar de versión 1 a 2
        // Por ejemplo, agregar una nueva columna
        // await db.execute('ALTER TABLE ${DBConstants.verbsTable} ADD COLUMN new_column TEXT');
      }

      // Más actualizaciones para futuras versiones
      // if (oldVersion < 3) { ... }
    } catch (e) {
      throw CustomDatabaseException(
        'Failed to upgrade database: ${e.toString()}',
        e,
      );
    }
  }

  /// Inserta un verbo en la base de datos
  ///
  /// Si el verbo ya existe (mismo ID), lo reemplaza
  Future<void> insertVerb(VerbModel verb) async {
    try {
      final db = await database;
      await db.insert(
        DBConstants.verbsTable,
        verb.toDatabase(),
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CustomDatabaseException(
        'Failed to insert verb: ${e.toString()}',
        e,
      );
    }
  }

  /// Inserta múltiples verbos en la base de datos
  ///
  /// Utiliza una transacción para mejorar el rendimiento
  Future<void> insertVerbs(List<VerbModel> verbs) async {
    try {
      final db = await database;
      await db.transaction((txn) async {
        for (final verb in verbs) {
          await txn.insert(
            DBConstants.verbsTable,
            verb.toDatabase(),
            conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e) {
      throw CustomDatabaseException(
        'Failed to insert multiple verbs: ${e.toString()}',
        e,
      );
    }
  }

  /// Obtiene un verbo por su ID
  Future<VerbModel?> getVerb(String id) async {
    try {
      final db = await database;
      final maps = await db.query(
        DBConstants.verbsTable,
        where: '${DBConstants.colId} = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) return null;
      return VerbModel.fromDatabase(maps.first);
    } catch (e) {
      throw CustomDatabaseException('Failed to get verb: ${e.toString()}', e);
    }
  }

  /// Busca verbos según la consulta proporcionada
  ///
  /// Implementa una estrategia de búsqueda en dos pasos:
  /// 1. Busca coincidencias exactas por forma base
  /// 2. Busca coincidencias parciales en cualquier forma
  Future<List<VerbModel>> searchVerbs(String query) async {
    if (query.isEmpty) return [];

    try {
      final db = await database;
      final normalizedQuery = query.toLowerCase().trim();

      // Primera consulta: Búsqueda exacta por base
      final exactBaseMatches = await db.rawQuery(
        DBConstants.exactBaseMatchQuery,
        [normalizedQuery],
      );

      // Segunda consulta: Búsqueda parcial excluyendo matches exactos
      final partialMatches = await db.rawQuery(DBConstants.partialMatchQuery, [
        '%$normalizedQuery%',
        normalizedQuery,
        '$normalizedQuery%',
        '$normalizedQuery%',
        '$normalizedQuery%',
      ]);

      final results = [
        ...exactBaseMatches.map((map) => VerbModel.fromDatabase(map)),
        ...partialMatches.map((map) => VerbModel.fromDatabase(map)),
      ];

      return results;
    } catch (e) {
      throw CustomDatabaseException(
        'Failed to search verbs: ${e.toString()}',
        e,
      );
    }
  }

  /// Obtiene el número total de verbos en la base de datos
  Future<int> getVerbCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery(DBConstants.countVerbsQuery);
      return sqflite.Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw CustomDatabaseException(
        'Failed to count verbs: ${e.toString()}',
        e,
      );
    }
  }

  /// Optimiza la base de datos
  ///
  /// Ejecuta VACUUM para liberar espacio y ANALYZE para actualizar estadísticas
  Future<void> optimize() async {
    try {
      final db = await database;
      await db.execute(DBConstants.vacuumQuery);
      await db.execute(DBConstants.analyzeQuery);
    } catch (e) {
      throw CustomDatabaseException(
        'Failed to optimize database: ${e.toString()}',
        e,
      );
    }
  }

  /// Cierra la conexión con la base de datos
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

/// Excepción personalizada para operaciones de base de datos
///
/// Usamos un nombre diferente para evitar conflictos con sqflite.DatabaseException
class CustomDatabaseException implements Exception {
  final String message;
  final dynamic originalError;

  CustomDatabaseException(this.message, [this.originalError]);

  @override
  String toString() =>
      'CustomDatabaseException: $message${originalError != null ? ' ($originalError)' : ''}';
}
