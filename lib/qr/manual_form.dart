import 'package:flutter/material.dart';
import 'package:hlvm_mobileapp/prepare/prepare_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';


class UserDataForm extends StatefulWidget {
  @override
  _UserDataFormState createState() => _UserDataFormState();
}

class _UserDataFormState extends State<UserDataForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  DateTime? dateTime;
  TextEditingController _sumController = TextEditingController();
  TextEditingController _fnController = TextEditingController();
  TextEditingController _fdController = TextEditingController();
  TextEditingController _fpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _sumController.text = prefs.getString('sum') ?? '';
      _fnController.text = prefs.getString('fn') ?? '';
      _fdController.text = prefs.getString('fd') ?? '';
      _fpController.text = prefs.getString('fp') ?? '';
      String? savedDate = prefs.getString('selectedDate');
      String? savedTime = prefs.getString('selectedTime');
      if (savedDate != null) {
        _selectedDate = DateTime.parse(savedDate);
      }
      if (savedTime != null) {
        _selectedTime = TimeOfDay(
          hour: int.parse(savedTime.split(":")[0]),
          minute: int.parse(savedTime.split(":")[1]),
        );
      }
    });
  }

  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('sum', _sumController.text);
    prefs.setString('fn', _fnController.text);
    prefs.setString('fd', _fdController.text);
    prefs.setString('fp', _fpController.text);
    if (_selectedDate != null) {
      prefs.setString('selectedDate', _selectedDate!.toIso8601String());
    }
    if (_selectedTime != null) {
      prefs.setString('selectedTime', "${_selectedTime!.hour}:${_selectedTime!.minute}");
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Введите данные'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(20.0),
          children: [
            _buildDateTimeField(),
            _buildSumField(),
            _buildFnField(),
            _buildFdField(),
            _buildFpField(),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await _saveData();
                  // Данные прошли валидацию
                  // Здесь можно обработать данные, например, отправить их на сервер
                  if (_selectedDate != null && _selectedTime != null) {
                    dateTime = DateTime(
                      _selectedDate!.year,
                      _selectedDate!.month,
                      _selectedDate!.day,
                      _selectedTime!.hour,
                      _selectedTime!.minute,
                    );
                  }
                  String formattedDateTime = DateFormat('yyyyMMddTHHmm').format(dateTime!);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PrepareDataQRCode(data: 't=$formattedDateTime&s=${_sumController.text}&fn=${_fnController.text}&i=${_fdController.text}&fp=${_fpController.text}&n=1'),
                    ),
                  );
                }
              },
              child: Text('Отправить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Дата и время'),
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: Text('Дата'),
                trailing: IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null && pickedDate != _selectedDate) {
                      setState(() {
                        _selectedDate = pickedDate;
                      });
                      await _saveData();
                    }
                  },
                ),
                subtitle: _selectedDate != null
                    ? Text("${_selectedDate?.toLocal()}".split(' ')[0])
                    : Text("Выберите дату"),
              ),
            ),
            Expanded(
              child: ListTile(
                title: Text('Время'),
                trailing: IconButton(
                  icon: Icon(Icons.access_time),
                  onPressed: () async {
                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime ?? TimeOfDay.now(),
                    );
                    if (pickedTime != null && pickedTime != _selectedTime) {
                      setState(() {
                        _selectedTime = pickedTime;
                      });
                      await _saveData();
                    }
                  },
                ),
                subtitle: _selectedTime != null
                    ? Text("${_selectedTime?.format(context)}")
                    : Text("Выберите время"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSumField() {
    return TextFormField(
      controller: _sumController,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: 'Сумма чека'),
      validator: (value) {
        if (value!.isEmpty) {
          return 'Пожалуйста, введите сумму чека';
        }
        return null;
      },
      onChanged: (value) async {
        await _saveData();
      },
    );
  }

  Widget _buildFnField() {
    return TextFormField(
      controller: _fnController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: 'Номер ФН'),
      validator: (value) {
        if (value!.isEmpty) {
          return 'Пожалуйста, введите номер ФН';
        }
        return null;
      },
      onChanged: (value) async {
        await _saveData();
      },
    );
  }

  Widget _buildFdField() {
    return TextFormField(
      controller: _fdController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: 'Номер ФД'),
      validator: (value) {
        if (value!.isEmpty) {
          return 'Пожалуйста, введите номер ФД';
        }
        return null;
      },
      onChanged: (value) async {
        await _saveData();
      },
    );
  }

  Widget _buildFpField() {
    return TextFormField(
      controller: _fpController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: 'Номер ФП'),
      validator: (value) {
        if (value!.isEmpty) {
          return 'Пожалуйста, введите номер ФП';
        }
        return null;
      },
      onChanged: (value) async {
        await _saveData();
      },
    );
  }
}