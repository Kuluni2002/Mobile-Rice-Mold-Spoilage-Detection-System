import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/batch.dart';

class BatchCreateScreen extends StatefulWidget {
  const BatchCreateScreen({super.key});

  @override
  State<BatchCreateScreen> createState() => _BatchCreateScreenState();
}

class _BatchCreateScreenState extends State<BatchCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sourceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  
  String? _selectedVariety;
  DateTime _storageDate = DateTime.now();
  
  final List<String> _riceVarieties = [
    'Samba',
    'Nadu',
    'Basmati',
    'Red Rice',
    'White Raw',
    'Parboiled',
    'Other',
  ];
  
  @override
  void dispose() {
    _nameController.dispose();
    _sourceController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    super.dispose();
  }
  
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _storageDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _storageDate) {
      setState(() {
        _storageDate = picked;
      });
    }
  }
  
  Future<void> _saveBatch() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Create batch entity
    final batch = Batch(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      source: _sourceController.text.trim().isEmpty
? null
: _sourceController.text.trim(),
variety: _selectedVariety,
quantity: _quantityController.text.trim().isEmpty
? null
: double.tryParse(_quantityController.text.trim()),
storageDate: _storageDate,
location: _locationController.text.trim().isEmpty
? null
: _locationController.text.trim(),
createdAt: DateTime.now(),
updatedAt: DateTime.now(),
);
// TODO: Save to database using repository

if (!mounted) return;

// Show success message
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Batch created successfully!'),
    backgroundColor: AppColors.healthy,
  ),
);

// Navigate back
Navigator.of(context).pop(batch);
}
@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('Create New Batch'),
),
body: Form(
key: _formKey,
child: ListView(
padding: const EdgeInsets.all(16),
children: [
Text(
'Batch Information',
style: Theme.of(context).textTheme.titleLarge,
),
const SizedBox(height: 16),
        // Batch Name (Required)
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Batch Name *',
            hintText: 'e.g., Warehouse A - Row 3',
            prefixIcon: Icon(Icons.label),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a batch name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Rice Variety
        DropdownButtonFormField<String>(
          value: _selectedVariety,
          decoration: const InputDecoration(
            labelText: 'Rice Variety',
            prefixIcon: Icon(Icons.grain),
          ),
          items: _riceVarieties.map((variety) {
            return DropdownMenuItem(
              value: variety,
              child: Text(variety),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedVariety = value;
            });
          },
        ),
        const SizedBox(height: 16),
        
        // Source/Supplier
        TextFormField(
          controller: _sourceController,
          decoration: const InputDecoration(
            labelText: 'Source/Supplier',
            hintText: 'e.g., Farmer Name or Supplier',
            prefixIcon: Icon(Icons.store),
          ),
        ),
        const SizedBox(height: 16),
        
        // Quantity
        TextFormField(
          controller: _quantityController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Quantity (kg)',
            hintText: 'e.g., 500',
            prefixIcon: Icon(Icons.scale),
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final quantity = double.tryParse(value);
              if (quantity == null || quantity <= 0) {
                return 'Please enter a valid quantity';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Storage Date
        InkWell(
          onTap: _selectDate,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Storage Date',
              prefixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(
              '${_storageDate.day}/${_storageDate.month}/${_storageDate.year}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Location
        TextFormField(
          controller: _locationController,
          decoration: const InputDecoration(
            labelText: 'Storage Location',
            hintText: 'e.g., Warehouse A, Section 2',
            prefixIcon: Icon(Icons.location_on),
          ),
        ),
        const SizedBox(height: 32),
        
        // Save button
        ElevatedButton(
          onPressed: _saveBatch,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Create Batch'),
          ),
        ),
      ],
    ),
  ),
);
}
}




