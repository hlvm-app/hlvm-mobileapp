import 'package:flutter/material.dart';

class UserDataForm extends StatefulWidget {
  @override
  _UserDataFormState createState() => _UserDataFormState();
}

class _UserDataFormState extends State<UserDataForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate = null;
  TimeOfDay? _selectedTime = null;
  TextEditingController _sumController = TextEditingController();
  TextEditingController _fnController = TextEditingController();
  TextEditingController _fdController = TextEditingController();
  TextEditingController _fpController = TextEditingController();

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
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Данные прошли валидацию
                  // Здесь можно обработать данные, например, отправить их на сервер
                  // Или вывести их в консоль
                  if (_selectedDate != null && _selectedTime != null) {
                    DateTime dateTime = DateTime(
                      _selectedDate!.year,
                      _selectedDate!.month,
                      _selectedDate!.day,
                      _selectedTime!.hour,
                      _selectedTime!.minute,
                    );
                    print('Дата и время: $dateTime');
                  }
                  print('Сумма чека: ${_sumController.text}');
                  print('Номер ФН: ${_fnController.text}');
                  print('Номер ФД: ${_fdController.text}');
                  print('Номер ФП: ${_fpController.text}');
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
    );
  }
}