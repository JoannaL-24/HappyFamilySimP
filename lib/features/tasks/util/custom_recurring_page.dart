import 'package:flutter/material.dart';

class CustomRecurrencePage extends StatefulWidget {
  const CustomRecurrencePage({super.key});

  @override
  State<CustomRecurrencePage> createState() => _CustomRecurrencePageState();
}

class _CustomRecurrencePageState extends State<CustomRecurrencePage> {
  String _pattern = 'Daily'; // Daily, Weekly, Monthly
  int _interval = 1;
  List<int> _selectedDays = []; // Weekdays (1-7) or Month days (1-31)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Custom Recurrence")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Frequency", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Daily', label: Text('Daily')),
              ButtonSegment(value: 'Weekly', label: Text('Weekly')),
              ButtonSegment(value: 'Monthly', label: Text('Monthly')),
            ],
            selected: {_pattern},
            onSelectionChanged: (val) => setState(() {
              _pattern = val.first;
              _selectedDays.clear();
            }),
          ),
          const SizedBox(height: 20),
          
          ListTile(
            title: Text("Every $_interval ${_pattern == 'Daily' ? 'day' : _pattern == 'Weekly' ? 'week' : _pattern == 'Monthly' ? 'month' : ''}(s)"),
            trailing: SizedBox(
              width: 60,
              child: TextFormField(
                initialValue: '1',
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (v) => _interval = int.tryParse(v) ?? 1,
              ),
            ),
          ),
          const Divider(),

          if (_pattern == 'Weekly') ...[
            const Text("On these weekdays:"),
            const SizedBox(height: 10),
            _buildWeeklyPicker(),
          ],

          if (_pattern == 'Monthly') ...[
            const Text("On these dates:"),
            const SizedBox(height: 10),
            _buildMonthlyPicker(),
          ],

          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            onPressed: () {
              Navigator.pop(context, {
                'pattern': _pattern,
                'interval': _interval,
                'selectedDays': _selectedDays,
              });
            },
            child: const Text("Apply Custom Rule"),
          ),
        ],
      ),
    );
  }
Widget _buildWeeklyPicker() {
  final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  
  return Column(
    children: List.generate(7, (i) {
      final day = i + 1;
      return Container(
        width: double.infinity, // Forces the chip to stretch
        margin: const EdgeInsets.symmetric(vertical: 0.5),
        child: FilterChip(
          label: Center(child: Text(labels[i])),
          selected: _selectedDays.contains(day),
          showCheckmark: false, // Prevents size fluctuation
          onSelected: (sel) => setState(() => 
            sel ? _selectedDays.add(day) : _selectedDays.remove(day)
          ),
        ),
      );
    }),
  );
}

Widget _buildMonthlyPicker() {
  return GridView.builder(
    shrinkWrap: true,
    padding: const EdgeInsets.symmetric(horizontal: 16), // Matching your weekly margins
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 7, 
      mainAxisSpacing: 4, 
      crossAxisSpacing: 4,
      childAspectRatio: 1.0, // This ensures they are perfect squares
    ),
    itemCount: 31,
    itemBuilder: (context, i) {
      final day = i + 1;
      return FilterChip(
        // Forces the chip to fill the square grid cell entirely
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.zero,
        labelPadding: EdgeInsets.zero,
        
        // Aesthetic matching your weekly version
        label: SizedBox.expand(
          child: Center(
            child: Text(
              "$day",
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
        
        showCheckmark: false,
        selected: _selectedDays.contains(day),
        onSelected: (sel) => setState(() => 
          sel ? _selectedDays.add(day) : _selectedDays.remove(day)
        ),
      );
    },
  );
}
}