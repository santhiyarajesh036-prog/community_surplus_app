import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../models/item_model.dart';
import '../data/item_repository.dart';
import 'full_image_view.dart';

class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  String selectedCategory = 'Food';
  String selectedCondition = 'Good';
  bool isFree = true;
  bool isLoading = false;

  DateTime? _expiryAt;

  File? selectedImage;
  final ImagePicker _picker = ImagePicker();

  final categories = [
    'Food',
    'Education',
    'Electronics',
    'Furniture',
    'Clothing',
    'Other',
  ];

  final conditions = ['New', 'Good', 'Fair', 'Poor'];

  /// 📸 PICK IMAGE (FULL QUALITY)
  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100, // ✅ Full clarity
    );

    if (picked == null) return;

    setState(() {
      selectedImage = File(picked.path);
    });
  }

  /// 📅 PICK EXPIRY DATE + TIME
  Future<void> _pickExpiryDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now(),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      _expiryAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  /// 🚀 SUBMIT ITEM
  Future<void> submitItem() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_nameController.text.trim().isEmpty) {
      _showMessage('Enter item name');
      return;
    }

    if (selectedCategory == 'Food' && _expiryAt == null) {
      _showMessage('Select expiry date & time');
      return;
    }

    setState(() => isLoading = true);

    final item = ItemModel(
      id: '',
      name: _nameController.text.trim(),
      category: selectedCategory,
      isFree: isFree,
      price: isFree ? 0 : double.tryParse(_priceController.text) ?? 0,
      donorEmail: user.email!,
      condition: selectedCondition,
      status: 'available',
      expiryAt: selectedCategory == 'Food' ? _expiryAt : null,
      imagePath: selectedImage?.path,
    );

    await ItemRepository.addItem(item);

    if (!mounted) return;
    Navigator.pop(context);
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donate Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// ITEM NAME
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            /// CATEGORY
            DropdownButtonFormField(
              value: selectedCategory,
              items: categories
                  .map(
                    (c) => DropdownMenuItem(
                  value: c,
                  child: Text(c),
                ),
              )
                  .toList(),
              onChanged: (v) => setState(() => selectedCategory = v!),
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),

            /// EXPIRY DATE + TIME
            if (selectedCategory == 'Food') ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text(
                  _expiryAt == null
                      ? 'Select Expiry Date & Time'
                      : 'Expiry: ${_expiryAt!.day}/${_expiryAt!.month}/${_expiryAt!.year} '
                      '${_expiryAt!.hour.toString().padLeft(2, '0')}:'
                      '${_expiryAt!.minute.toString().padLeft(2, '0')}',
                ),
                onPressed: _pickExpiryDateTime,
              ),
            ],

            const SizedBox(height: 16),

            /// CONDITION
            DropdownButtonFormField(
              value: selectedCondition,
              items: conditions
                  .map(
                    (c) => DropdownMenuItem(
                  value: c,
                  child: Text(c),
                ),
              )
                  .toList(),
              onChanged: (v) => setState(() => selectedCondition = v!),
              decoration: const InputDecoration(
                labelText: 'Condition',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            /// FREE SWITCH
            SwitchListTile(
              title: const Text('Free Item'),
              value: isFree,
              onChanged: (v) => setState(() => isFree = v),
            ),

            if (!isFree)
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
              ),

            const SizedBox(height: 16),

            /// IMAGE PICKER
            OutlinedButton.icon(
              icon: const Icon(Icons.image),
              label: const Text('Pick Image'),
              onPressed: _pickImage,
            ),

            /// IMAGE PREVIEW (FULL VIEW + TAP)
            if (selectedImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                FullImageView(imageFile: selectedImage!),
                          ),
                        );
                      },
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            selectedImage!,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          selectedImage = null;
                        });
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text(
                        'Remove Image',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            /// SUBMIT BUTTON
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: submitItem,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
