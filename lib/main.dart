import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firestore_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:table_calendar/table_calendar.dart';
// import 'data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Обязательно для инициализации Firebase
  await Firebase.initializeApp(); // Инициализация Firebase
  // await populateDatabase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FirestoreProvider(),
      child: MaterialApp(
        title: 'Firestore App',
        theme: ThemeData(primarySwatch: Colors.blue),
        initialRoute: '/',
        routes: {
          '/': (context) => LoginScreen(),
          '/main': (context) => MainScreen(),
        },
      ),
    );
  }
}


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';

  Future<void> _checkPassword() async {
    if (_passwordController.text == '1111') {  // Оставим статический пароль для примера
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    } else {
      setState(() {
        _errorMessage = 'Неверный пароль.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Авторизация')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _passwordController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(labelText: 'Введите PIN-код'),
            ),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkPassword,
              child: const Text('Войти'),
            ),
          ],
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isEditing = false;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    Provider.of<FirestoreProvider>(context, listen: false).loadCars();
  }

  void _toggleEditingMode() {
    setState(() {
      _isEditing = !_isEditing;
      _selectedIndex = null;
    });
  }

Future<void> _editCarName(int index) async {
  final provider = Provider.of<FirestoreProvider>(context, listen: false);
  final car = provider.cars[index];
  final carName = provider.cars[index]['name'] as String;
  final editedCarName = await _showEditCarDialog(context, carName);

  if (editedCarName != null && editedCarName.isNotEmpty) {
    int editedStatus = await _showStatusEditDialog(context, car['status'] as int);
    await provider.updateCarName(index, editedCarName, editedStatus);
    setState(() {
      _selectedIndex = null;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Renta'),
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.done : Icons.edit),
            onPressed: _toggleEditingMode,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await _showAddCarDialog(context);
              if (result != null) {
                String carName = result['name'];
                int selectedStatus = result['status'];
                await Provider.of<FirestoreProvider>(context, listen: false).addCar(carName, selectedStatus);
              }
            },
          ),
        ],
      ),
      body: Consumer<FirestoreProvider>(
        builder: (context, provider, child) {
          return ListView.builder(
            itemCount: provider.cars.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: _isEditing && _selectedIndex == index
                    ? TextField(
                        controller: TextEditingController(text: provider.cars[index]['name'] as String),
                        onSubmitted: (newName) {
                          provider.updateCarName(index, newName, provider.cars[index]['status']);
                          setState(() {
                            _selectedIndex = null;
                            _isEditing = false;
                          });
                        },
                      )
                    : Text(provider.cars[index]['name'] as String),
// Text(provider.cars[index] as String),
                onLongPress: () async {
                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Удалить автомобиль?'),
                        content: const Text('Вы уверены, что хотите удалить автомобиль?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить')),
                        ],
                      );
                    },
                  );
                  
                  if (shouldDelete == true) {
                    await Provider.of<FirestoreProvider>(context, listen: false).deleteCar(index);
                  }
                },
                trailing: _isEditing
                    ? IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editCarName(index),
                      )
                    : const Icon(Icons.arrow_forward_ios),
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(provider.cars[index]['status']),
                ),
                onTap: !_isEditing
                    ? () {
                        final car = provider.cars[index];
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CarDetailScreen(
                              carId: car['id'],
                              carName: car['name'] as String,
                            ),
                          ),
                        );
                      }
                    : () => setState(() => _selectedIndex = index),

                // onTap: !_isEditing
                //     ? () {
                //         final car = provider.cars[index];
                //         Navigator.push(
                //           context,
                //           MaterialPageRoute(
                //             builder: (context) => CarDetailScreen(carName: car['name'] as String),
                //           ),
                //         );

                //       }
                //     : () => setState(() => _selectedIndex = index),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<Map<String, dynamic>?> _showAddCarDialog(BuildContext context) {
    TextEditingController controller = TextEditingController();
    int selectedStatus = 1;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Введите название автомобиля и выберите статус'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Название автомобиля'),
              ),
              DropdownButton<int>(
                value: selectedStatus,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Красный (1)')),
                  DropdownMenuItem(value: 2, child: Text('Оранжевый (2)')),
                  DropdownMenuItem(value: 3, child: Text('Зеленый (3)')),
                ],
                onChanged: (value) {
                  if (value != null) selectedStatus = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, {'name': controller.text, 'status': selectedStatus});
              },
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );
  }
}

Future<int> _showStatusEditDialog(BuildContext context, int currentStatus) async {
  int newStatus = currentStatus;

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Выберите новый статус'),
        content: DropdownButton<int>(
          value: newStatus,
          items: const [
            DropdownMenuItem(value: 1, child: Text('Красный (1)')),
            DropdownMenuItem(value: 2, child: Text('Оранжевый (2)')),
            DropdownMenuItem(value: 3, child: Text('Зеленый (3)')),
          ],
          onChanged: (value) {
            newStatus = value!;
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Сохранить')),
        ],
      );
    },
  );

  return newStatus;
}


  Future<String?> _showEditCarDialog(BuildContext context, String currentName) {
    TextEditingController controller = TextEditingController(text: currentName);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Car Name'),
          content: TextField(controller: controller),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
}

class CarDetailScreen extends StatelessWidget {
  final String carId;
  final String carName;
  const CarDetailScreen({Key? key, required this.carId, required this.carName}) : super(key: key);
  // const CarDetailScreen({super.key, required this.carName});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FirestoreProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(carName),
        backgroundColor: Colors.redAccent,
      ),
      body: StreamBuilder<double>(
        stream: provider.getTotalIncomeStream(carId),
        builder: (context, incomeSnapshot) {
          return StreamBuilder<double>(
            stream: provider.getTotalMaintenanceCostStream(carId),
            builder: (context, expenseSnapshot) {
              if (incomeSnapshot.connectionState == ConnectionState.waiting ||
                  expenseSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (incomeSnapshot.hasError || expenseSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Ошибка: ${incomeSnapshot.error ?? expenseSnapshot.error}',
                  ),
                );
              } else {
                final income = incomeSnapshot.data ?? 0.0;
                final expense = expenseSnapshot.data ?? 0.0;
                final netProfit = income - expense;
          return Column(
            children: [
              ListTile(
                title: const Text('Доход', style: TextStyle(fontSize: 18)),
                trailing: Text(income.toString(), style: const TextStyle(fontSize: 18, color: Colors.orange)),
              ),
              ListTile(
                title: const Text('Расход', style: TextStyle(fontSize: 18)),
                trailing: Text(expense.toString(), style: const TextStyle(fontSize: 18, color: Colors.redAccent)),
              ),
              ListTile(
                title: const Text('Чистая прибыль', style: TextStyle(fontSize: 18)),
                trailing: Text(netProfit.toString(), style: const TextStyle(fontSize: 18, color: Colors.green)),
              ),
              ListTile(
                title: const Text('ТО авто'),
                trailing: const Icon(Icons.build),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CarMaintenanceScreen(carName: carName),
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text('Календарь занятости авто'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EmploymentCalendarScreen(
                        carId: carId,
                        carName: carName,
                      ),
                    ),
                  );
                },
              ),

              // ListTile(
              //   title: const Text('Календарь занятости авто'),
              //   onTap: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (context) => EmploymentCalendarScreen()),
              //     );
              //   },
              // ),
                   ],
                );
              }
            },
          );
        },
      ),
    );
  }
}

class CarMaintenanceScreen extends StatefulWidget {
  final String carName;

  const CarMaintenanceScreen({super.key, required this.carName});

  @override
  _CarMaintenanceScreenState createState() => _CarMaintenanceScreenState();
}

class _CarMaintenanceScreenState extends State<CarMaintenanceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.carName),
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddMaintenanceDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditMaintenanceDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteMaintenanceDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Provider.of<FirestoreProvider>(context, listen: false)
            .getMaintenanceForCarStream(widget.carName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text('Данных о ТО нет'));
          }

          final maintenanceData = snapshot.data!;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20.0,
              columns: const [
                DataColumn(label: Text('Дата')),
                DataColumn(label: Text('ТО')),
                DataColumn(label: Text('Стоимость')),
              ],
              rows: maintenanceData.map((data) {
                return DataRow(cells: [
                  DataCell(Text(data['Дата'] ?? 'Не указано')),
                  DataCell(Text(data['ТО'] ?? 'Не указано')),
                  DataCell(Text(data['Стоимость'] ?? 'Не указано')),
                ]);
              }).toList(),
            ),
          );
        },
      ),
    );
  }


  // Открыть диалоговое окно для добавления новой записи ТО
  Future<void> _showAddMaintenanceDialog(BuildContext context) async {
    final provider = Provider.of<FirestoreProvider>(context, listen: false);
    final newRecord = await _showMaintenanceDialog(context);

    if (newRecord != null) {
      await provider.addMaintenanceRecord(widget.carName, newRecord);
    }
  }

  // Открыть диалоговое окно для изменения существующей записи ТО
  Future<void> _showEditMaintenanceDialog(BuildContext context) async {
    final provider = Provider.of<FirestoreProvider>(context, listen: false);
    final maintenanceData = await provider.getMaintenanceForCar(widget.carName);

    if (maintenanceData.isEmpty) return;

    final selectedRecord = await _showSelectMaintenanceDialog(context, maintenanceData);

    if (selectedRecord != null) {
      final editedRecord = await _showMaintenanceDialog(context, record: selectedRecord);
      if (editedRecord != null) {
        await provider.updateMaintenanceRecord(widget.carName, selectedRecord['id'], editedRecord);
      }
    }

  }

  // Открыть диалоговое окно для удаления записи ТО
  Future<void> _showDeleteMaintenanceDialog(BuildContext context) async {
    final provider = Provider.of<FirestoreProvider>(context, listen: false);
    final maintenanceData = await provider.getMaintenanceForCar(widget.carName);

    if (maintenanceData.isEmpty) return;

    final selectedRecord = await _showSelectMaintenanceDialog(context, maintenanceData);

    if (selectedRecord != null) {
      await provider.deleteMaintenanceRecord(widget.carName, selectedRecord['id']);
    }
  }

  // Диалоговое окно для ввода или редактирования записи ТО
  Future<Map<String, dynamic>?> _showMaintenanceDialog(BuildContext context, {Map<String, dynamic>? record}){

  // Future<Map<String, String>?> _showMaintenanceDialog(BuildContext context, {Map<String, String>? record}) {
    final dateController = TextEditingController(text: record?['Дата'] ?? '');
    final serviceController = TextEditingController(text: record?['ТО'] ?? '');
    final costController = TextEditingController(text: record?['Стоимость'] ?? '');

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(record == null ? 'Добавить запись ТО' : 'Изменить запись ТО'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateController,
                decoration: const InputDecoration(labelText: 'Дата'),
              ),
              TextField(
                controller: serviceController,
                decoration: const InputDecoration(labelText: 'ТО'),
              ),
              TextField(
                controller: costController,
                decoration: const InputDecoration(labelText: 'Стоимость'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                final newRecord = {
                  'Дата': dateController.text,
                  'ТО': serviceController.text,
                  'Стоимость': costController.text,
                };
                Navigator.pop(context, newRecord);
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  // Диалоговое окно для выбора записи ТО (редактирование или удаление)
Future<Map<String, dynamic>?> _showSelectMaintenanceDialog(BuildContext context, List<Map<String, dynamic>> maintenanceData) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Выберите запись для редактирования или удаления'),
        content: SizedBox(
          width: double.minPositive,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: maintenanceData.length,
            itemBuilder: (context, index) {
              final record = maintenanceData[index];
              return ListTile(
                title: Text('${record['Дата']}: ${record['ТО']}'),
                onTap: () => Navigator.pop(context, record),
              );
            },
          ),
        ),
      );
    },
  );
}

}


class EmploymentCalendarScreen extends StatefulWidget {
  final String carId;
  final String carName;

  const EmploymentCalendarScreen({Key? key, required this.carId, required this.carName}) : super(key: key);

  @override
  _EmploymentCalendarScreenState createState() => _EmploymentCalendarScreenState();
}

class _EmploymentCalendarScreenState extends State<EmploymentCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, Map<String, dynamic>> _employmentData = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Календарь занятости - ${widget.carName}'),
        backgroundColor: Colors.redAccent,
      ),
      body: StreamBuilder<Map<DateTime, Map<String, dynamic>>>(
        stream: Provider.of<FirestoreProvider>(context, listen: false)
            .getEmploymentDataStream(widget.carId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          } else {
            _employmentData = snapshot.data ?? {};
            return TableCalendar(
              // locale: 'ru_RU',
              firstDay: DateTime(2020),
              lastDay: DateTime(2100),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  return Container(
                    margin: const EdgeInsets.all(4.0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _getDayColor(day),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                },
                todayBuilder: (context, day, focusedDay) {
                  return Container(
                    margin: const EdgeInsets.all(4.0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _getDayColor(day),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
              onDaySelected: _onDaySelected,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Месяц',
              },
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
              ),
            );
          }
        },
      ),
    );
  }

  Color _getDayColor(DateTime day) {
    final data = _employmentData[DateTime(day.year, day.month, day.day)];
    // final data = _employmentData[day];
    if (data != null) {
      switch (data['status']) {
        case 1:
          return Colors.green;
        case 2:
          return Colors.orange;
        case 3:
          return Colors.red;
        default:
          return Colors.grey;
      }
    }
    return Colors.grey;
  }
  bool _isLoading = true;

  Future<void> _loadEmploymentData() async {
    setState(() {
      _isLoading = true;
    });
    final provider = Provider.of<FirestoreProvider>(context, listen: false);
    final data = await provider.getEmploymentData(widget.carId);
    setState(() {
      _employmentData = data;
      _isLoading = false;
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    _showEmploymentDetails(context, selectedDay);
  }
  

  Future<void> _showEmploymentDetails(BuildContext context, DateTime date) async {
    final provider = Provider.of<FirestoreProvider>(context, listen: false);
    // final dateData = _employmentData[date] ?? {};
    final dateData = _employmentData[DateTime(date.year, date.month, date.day)] ?? {};

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        final driverController = TextEditingController(text: dateData['driverName'] ?? '');
        final incomeController = TextEditingController(text: (dateData['income'] ?? '').toString());
        final expenseController = TextEditingController(text: (dateData['expense'] ?? '').toString());
        final purposeController = TextEditingController(text: dateData['purpose'] ?? '');
        int status = dateData['status'] ?? 1;

        return AlertDialog(
          title: Text('Данные за ${date.day}.${date.month}.${date.year}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<int>(
                  value: status,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Работала')),
                    DropdownMenuItem(value: 2, child: Text('Стояла')),
                    DropdownMenuItem(value: 3, child: Text('Ремонтировалась')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        status = value;
                      });
                    }
                  },
                ),
                TextField(
                  controller: driverController,
                  decoration: const InputDecoration(labelText: 'ФИО водителя'),
                ),
                TextField(
                  controller: incomeController,
                  decoration: const InputDecoration(labelText: 'Доход'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: expenseController,
                  decoration: const InputDecoration(labelText: 'Расход'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: purposeController,
                  decoration: const InputDecoration(labelText: 'Цель аренды'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, {
                  'status': status,
                  'driverName': driverController.text,
                  'income': double.tryParse(incomeController.text) ?? 0.0,
                  'expense': double.tryParse(expenseController.text) ?? 0.0,
                  'purpose': purposeController.text,
                });
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      await provider.setEmploymentData(widget.carId, date, result);
      await _loadEmploymentData();
    }
  }
}

