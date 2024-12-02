import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirestoreProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> cars = [];

  Map<String, Map<String, dynamic>> carFinancialData = {};


  void loadCars() {
    _firestore.collection('cars').snapshots().listen((snapshot) {
      cars = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Сохраняем ID документа для будущих операций
        return data;
      }).toList();
      notifyListeners();
    });
  }

  /// Добавление автомобиля
  Future<void> addCar(String carName, int status) async {
    await _firestore.collection('cars').add({'name': carName, 'status': status});
    loadCars();
  }

  /// Обновление названия и статуса автомобиля
  Future<void> updateCarName(int index, String newName, int status) async {
    final docId = (await _firestore.collection('cars').get()).docs[index].id;
    await _firestore.collection('cars').doc(docId).update({'name': newName, 'status': status});
    loadCars();
  }

  /// Удаление автомобиля
  Future<void> deleteCar(int index) async {
    final docId = (await _firestore.collection('cars').get()).docs[index].id;
    await _firestore.collection('cars').doc(docId).delete();
    loadCars();
  }

  /// Получение данных по ТО автомобиля
  Future<List<Map<String, dynamic>>> getMaintenanceForCar(String carName) async {
    final carSnapshot = await _firestore
        .collection('cars')
        .where('name', isEqualTo: carName)
        .limit(1)
        .get();

    if (carSnapshot.docs.isNotEmpty) {
      final carId = carSnapshot.docs.first.id;
      final maintenanceSnapshot = await _firestore
          .collection('cars')
          .doc(carId)
          .collection('maintenance')
          .get();

      return maintenanceSnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Сохраняем идентификатор документа
        return data;
      }).toList();
    } else {
      return [];
    }
  }


  /// Добавление записи ТО
  Future<void> addMaintenanceRecord(String carName, Map<String, dynamic> newRecord) async {
    final carSnapshot = await _firestore
        .collection('cars')
        .where('name', isEqualTo: carName)
        .limit(1)
        .get();

    if (carSnapshot.docs.isNotEmpty) {
      final carId = carSnapshot.docs.first.id;
      await _firestore.collection('cars').doc(carId).collection('maintenance').add(newRecord);
      notifyListeners();
    }
  }

  /// Обновление записи ТО
  Future<void> updateMaintenanceRecord(String carName, String maintenanceId, Map<String, dynamic> updatedRecord) async {
    final carSnapshot = await _firestore
        .collection('cars')
        .where('name', isEqualTo: carName)
        .limit(1)
        .get();

    if (carSnapshot.docs.isNotEmpty) {
      final carId = carSnapshot.docs.first.id;
      await _firestore
          .collection('cars')
          .doc(carId)
          .collection('maintenance')
          .doc(maintenanceId)
          .update(updatedRecord);
      notifyListeners();
    }
  }


  /// Удаление записи ТО
 Future<void> deleteMaintenanceRecord(String carName, String maintenanceId) async {
  final carSnapshot = await _firestore
      .collection('cars')
      .where('name', isEqualTo: carName)
      .limit(1)
      .get();

  if (carSnapshot.docs.isNotEmpty) {
    final carId = carSnapshot.docs.first.id;
    await _firestore
        .collection('cars')
        .doc(carId)
        .collection('maintenance')
        .doc(maintenanceId)
        .delete();
    notifyListeners();
  }
}
  Stream<List<Map<String, dynamic>>> getMaintenanceForCarStream(String carName) {
  return _firestore
      .collection('cars')
      .where('name', isEqualTo: carName)
      .limit(1)
      .snapshots()
      .asyncExpand((carSnapshot) {
    if (carSnapshot.docs.isNotEmpty) {
      final carId = carSnapshot.docs.first.id;
      return _firestore
          .collection('cars')
          .doc(carId)
          .collection('maintenance')
          .snapshots()
          .map((maintenanceSnapshot) {
        return maintenanceSnapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } else {
      return Stream.value([]);
    }
  });
}

Stream<double> getTotalMaintenanceCostStream(String carId) {
  return _firestore
      .collection('cars')
      .doc(carId)
      .collection('maintenance')
      .snapshots()
      .map((snapshot) {
    double totalCost = 0.0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final cost = data['Стоимость'];
      if (cost is num) {
        totalCost += cost.toDouble();
      } else if (cost is String) {
        totalCost += double.tryParse(cost) ?? 0.0;
      }
    }
    return totalCost;
  });
}

Stream<double> getTotalIncomeStream(String carId) {
  return _firestore
      .collection('cars')
      .doc(carId)
      .collection('employment')
      .snapshots()
      .map((snapshot) {
    double totalIncome = 0.0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final income = data['income'];
      if (income is num) {
        totalIncome += income.toDouble();
      } else if (income is String) {
        totalIncome += double.tryParse(income) ?? 0.0;
      }
    }
    return totalIncome;
  });
}



Stream<Map<DateTime, Map<String, dynamic>>> getEmploymentDataStream(String carId) {
  return _firestore
      .collection('cars')
      .doc(carId)
      .collection('employment')
      .snapshots()
      .map((snapshot) {
    Map<DateTime, Map<String, dynamic>> employmentData = {};
    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data();
      DateTime date = DateTime.parse(doc.id);
      employmentData[date] = data;
    }
    return employmentData;
  });
}

  Future<Map<DateTime, Map<String, dynamic>>> getEmploymentData(String carId) async {
    final snapshot = await _firestore
        .collection('cars')
        .doc(carId)
        .collection('employment')
        .get();

    Map<DateTime, Map<String, dynamic>> employmentData = {};

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data();
      DateTime date = DateTime.parse(doc.id);
      employmentData[date] = data;
    }

    return employmentData;
  }

  /// Установка данных занятости для конкретной даты
  Future<void> setEmploymentData(String carId, DateTime date, Map<String, dynamic> data) async {
    String dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    await _firestore
        .collection('cars')
        .doc(carId)
        .collection('employment')
        .doc(dateString)
        .set(data);
    notifyListeners();
  }
}
