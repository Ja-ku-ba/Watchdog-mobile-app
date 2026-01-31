import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../layouts/base/loged_in_layout.dart';
import '../../utils/request.dart';
import 'package:watchdog/components/snackBars.dart';


class AddVerifiedUser extends StatefulWidget {
  const AddVerifiedUser({Key? key}) : super(key: key);

  @override
  State<AddVerifiedUser> createState() => _AddVerifiedUserState();
}

class _AddVerifiedUserState extends State<AddVerifiedUser> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedPhotos = [];
  bool _isUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndCropImage() async {
    if (_selectedPhotos.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Możesz dodać maksymalnie 3 zdjęcia'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final croppedFile = await _cropImage(File(pickedFile.path));

      if (croppedFile != null) {
        setState(() {
          _selectedPhotos.add(croppedFile);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd: $e')));
      }
    }
  }

  Future<File?> _cropImage(File imageFile) async {
    try {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Przytnij zdjęcie',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Przytnij zdjęcie'),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  Future<void> _submitUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPhotos.isEmpty) {
      showSnackBar(context, "Dodaj przynajmniej jedno zdjęcie", color: Colors.orange);
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      List<MultipartFile> photoFiles = [];
      for (var file in _selectedPhotos) {
        photoFiles.add(
            await MultipartFile.fromFile(
              file.path,
              filename: file.path
                  .split('/')
                  .last,
            )
        );
      }

      final client = RequestClient();
      await client.initialize();
      final formData = FormData.fromMap({
        'verified_user': jsonEncode({
          'name': _nameController.text,
        }),
        'files': photoFiles,
      });

      // final response = await client.post('/users/add-verified-user', data: formData);
      await client.post('/users/add-verified-user', data: formData);
      showSnackBar(context, "Użytkownik został dodany", color: Colors.green);
      Navigator.pushNamed(context, '/verified_users');
    } on DioException catch (e) {
      String? errorMessage = e.response?.data["detail"];
      if (errorMessage != null) {
        showSnackBar(context, "$errorMessage", color: Colors.red);
      } else {
        rethrow;
      }
    } catch (e) {
      showSnackBar(context, "Nieznany błąd", color: Colors.red);
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nazwa użytkownika',
                        hintText: 'Wpisz nazwę',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nazwa jest wymagana';
                        }
                        if (value.trim().length < 3) {
                          return 'Nazwa musi mieć minimum 3 znaki';
                        }
                        return null;
                      },
                      enabled: !_isUploading,
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Zdjęcia (${_selectedPhotos.length}/3)',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_selectedPhotos.length < 3)
                          ElevatedButton.icon(
                            onPressed: _isUploading ? null : _pickAndCropImage,
                            icon: const Icon(
                              Icons.add_photo_alternate,
                              size: 20,
                            ),
                            label: const Text('Dodaj'),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (_selectedPhotos.isEmpty)
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.photo_library,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Brak zdjęć',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: _selectedPhotos.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedPhotos[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.red,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.close, size: 16),
                                    color: Colors.white,
                                    onPressed: () => _removePhoto(index),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                  ],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _isUploading ? null : _submitUser,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isUploading
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text('Dodaj', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
