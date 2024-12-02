import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirestoreProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Пример метода для авторизации
  /// В Firestore авторизация выполняется на уровне Firebase и для этого метода 
  /// вам не потребуется ничего специфического
  Future<void> initialize() async {
    // Здесь можно добавить любую начальную логику и, например, проверить доступ к Firestore
    notifyListeners();
  }

  /// Чтение данных
  Future<List<Map<String, dynamic>>> getData(String collectionName) async {
    try {
      // Получение документов из Firestore коллекции
      QuerySnapshot querySnapshot = await _firestore.collection(collectionName).get();

      // Преобразование данных в список карт для удобства
      List<Map<String, dynamic>> dataList = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      return dataList;
    } catch (e) {
      print("Ошибка чтения данных: $e");
      return [];
    }
  }

  /// Запись данных
  Future<void> addData(String collectionName, Map<String, dynamic> data) async {
    try {
      // Добавляем новый документ в коллекцию
      await _firestore.collection(collectionName).add(data);
      notifyListeners();
    } catch (e) {
      print("Ошибка добавления данных: $e");
    }
  }

  /// Обновление данных
  Future<void> updateData(String collectionName, String documentId, Map<String, dynamic> data) async {
    try {
      // Обновляем документ по его ID
      await _firestore.collection(collectionName).doc(documentId).update(data);
      notifyListeners();
    } catch (e) {
      print("Ошибка обновления данных: $e");
    }
  }

  /// Удаление данных
  Future<void> deleteData(String collectionName, String documentId) async {
    try {
      await _firestore.collection(collectionName).doc(documentId).delete();
      notifyListeners();
    } catch (e) {
      print("Ошибка удаления данных: $e");
    }
  }
}
