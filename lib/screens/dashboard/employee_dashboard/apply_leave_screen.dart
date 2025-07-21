import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({Key? key}) : super(key: key);

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen>
    with SingleTickerProviderStateMixin {
  /* ─── form controllers ─── */
  final _formKey            = GlobalKey<FormState>();
  final _reasonController   = TextEditingController();
  DateTime? _startDate, _endDate;
  String? _selectedLeaveType;
  bool _isSubmitting        = false;

  final _leaveTypes = [
    'Casual Leave',
    'Sick Leave',
    'Earned Leave',
    'Maternity Leave',
    'Others',
  ];

  /* ─── animation ─── */
  late final AnimationController _ctl;
  late final Animation<double>  _scaleAnim;
  late final List<Interval>     _stagger;   // one per form field

  @override
  void initState() {
    super.initState();
    _ctl       = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnim = CurvedAnimation(parent: _ctl, curve: Curves.easeOutBack);
    _stagger   = List.generate(5, (i) => Interval(0.1 * i, 0.6 + 0.1 * i, curve: Curves.easeIn));
    _ctl.forward();
  }

  @override
  void dispose() {
    _ctl.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  /* ─── pick date ─── */
  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate : DateTime(2024),
      lastDate  : DateTime(2030),
    );
    if (picked != null) setState(() {
      if (isStart) _startDate = picked; else _endDate = picked;
    });
  }

  /* ─── firestore submit ─── */
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select dates')),
      );
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      const email = 'mani@gmail.com';               // TODO: replace with FirebaseAuth email
      final userSnap = await FirebaseFirestore.instance
          .collection('users').where('email', isEqualTo: email).limit(1).get();
      if (userSnap.docs.isEmpty) throw Exception('User not found');

      final userId = userSnap.docs.first.id;
      final now    = DateTime.now();

      await FirebaseFirestore.instance.collection('leaves').add({
        'leaveType' : _selectedLeaveType,
        'startDate' : _startDate,
        'endDate'   : _endDate,
        'reason'    : _reasonController.text.trim(),
        'status'    : 'Pending',
        'appliedOn' : now,
        'createdOn' : now,
        'updatedOn' : now,
        'createdBy' : userId,
        'updatedBy' : userId,
        'email'     : email,
        'name'      : 'Mani',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave request submitted')),
      );

      _formKey.currentState?.reset();
      _reasonController.clear();
      setState(() {
        _selectedLeaveType = null;
        _startDate = _endDate = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  /* ─── animated field wrapper ─── */
  Widget _animated(int index, Widget child) => AnimatedBuilder(
    animation: _ctl,
    builder: (_, __) => Transform.translate(
      offset: Offset(0, 40 * (1 - _stagger[index].transform(_ctl.value))),
      child : Opacity(
        opacity: _stagger[index].transform(_ctl.value),
        child  : child,
      ),
    ),
  );

  /* ─── build ─── */
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title          : const Text('Apply Leave'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      body: ScaleTransition(
        scale: _scaleAnim,                 // whole card pops in
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // 0️⃣ Leave type
                    _animated(
                      0,
                      DropdownButtonFormField<String>(
                        value: _selectedLeaveType,
                        decoration: const InputDecoration(
                          labelText: 'Leave Type',
                          border: OutlineInputBorder(),
                        ),
                        items: _leaveTypes
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedLeaveType = v),
                        validator: (v) =>
                        v == null ? 'Select leave type' : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 1️⃣ Start date
                    _animated(
                      1,
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.grey),
                        ),
                        title: Text(_startDate == null
                            ? 'Select Start Date'
                            : 'Start: ${DateFormat('dd MMM yyyy').format(_startDate!)}'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => _pickDate(true),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 2️⃣ End date
                    _animated(
                      2,
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.grey),
                        ),
                        title: Text(_endDate == null
                            ? 'Select End Date'
                            : 'End: ${DateFormat('dd MMM yyyy').format(_endDate!)}'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => _pickDate(false),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3️⃣ Reason
                    _animated(
                      3,
                      TextFormField(
                        controller: _reasonController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Reason',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter reason' : null,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // 4️⃣ Submit button
                    _animated(
                      4,
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                            : const Text('Submit Leave'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
