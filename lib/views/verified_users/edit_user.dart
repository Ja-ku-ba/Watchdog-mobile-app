import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../layouts/base/loged_in_layout.dart';
import '../../models/verified_user.dart';
import '../../utils/request.dart';
import 'package:watchdog/components/snackBars.dart';

class EditVerifiedUser extends StatefulWidget {
  final VerifiedUserModel verifiedUser;

  const EditVerifiedUser({Key? key, required this.verifiedUser}): super(key: key);

  @override
  State<EditVerifiedUser> createState() => _EditVerifiedUserState();
}

class _EditVerifiedUserState extends State<EditVerifiedUser> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<File> _newPhotos = [];
  List<String> _existingPhotoHashes = [];
  bool _isUploading = false;
  bool _isDeleting = false;
  Set<String> _deletingPhotos = {};

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.verifiedUser.name;
    _existingPhotoHashes = widget.verifiedUser.imageHashes ?? [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndCropImage() async {
    final totalPhotos = _existingPhotoHashes.length + _newPhotos.length;

    if (totalPhotos >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Możesz mieć maksymalnie 3 zdjęcia'),
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
          _newPhotos.add(croppedFile);
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

  void _removeNewPhoto(int index) {
    setState(() {
      _newPhotos.removeAt(index);
    });
  }

  Future<void> _deleteExistingPhoto(String photoHash) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potwierdź usunięcie'),
        content: const Text('Czy na pewno chcesz usunąć to zdjęcie?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _deletingPhotos.add(photoHash);
    });

    try {
      final client = RequestClient();
      await client.initialize();

      await client.delete('/users/verified-user/photo/$photoHash');

      setState(() {
        _existingPhotoHashes.remove(photoHash);
        _deletingPhotos.remove(photoHash);
      });

      showSnackBar(context, "Zdjęcie zostało usunięte", color: Colors.green);
    } on DioException catch (e) {
      setState(() {
        _deletingPhotos.remove(photoHash);
      });
      String? errorMessage = e.response?.data["detail"];
      showSnackBar(
        context,
        errorMessage ?? "Błąd usuwania zdjęcia",
        color: Colors.red,
      );
    } catch (e) {
      setState(() {
        _deletingPhotos.remove(photoHash);
      });
      showSnackBar(context, "Nieznany błąd", color: Colors.red);
    }
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    final remainingPhotos = _existingPhotoHashes.length + _newPhotos.length;
    if (remainingPhotos == 0) {
      showSnackBar(
        context,
        "Użytkownik musi mieć przynajmniej jedno zdjęcie",
        color: Colors.orange,
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      List<MultipartFile> photoFiles = [];
      for (var file in _newPhotos) {
        photoFiles.add(
          await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        );
      }

      final client = RequestClient();
      await client.initialize();

      final formData = FormData.fromMap({
        'verified_user': jsonEncode({'name': _nameController.text}),
        if (photoFiles.isNotEmpty) 'files': photoFiles,
      });

      await client.put(
        '/users/verified-user/${widget.verifiedUser.hash}',
        data: formData,
      );

      if (mounted) {
        showSnackBar(
          context,
          "Użytkownik został zaktualizowany",
          color: Colors.green,
        );
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      String? errorMessage = e.response?.data["detail"];
      if (mounted) {
        showSnackBar(
          context,
          errorMessage ?? "Błąd aktualizacji",
          color: Colors.red,
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, "Nieznany błąd", color: Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _deleteUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potwierdź usunięcie'),
        content: Text(
          'Czy na pewno chcesz usunąć użytkownika "${widget.verifiedUser.name}"?\n\nTa operacja jest nieodwracalna.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final client = RequestClient();
      await client.initialize();

      await client.delete('/users/verified-user/${widget.verifiedUser.hash}');

      if (mounted) {
        showSnackBar(
          context,
          "Użytkownik został usunięty",
          color: Colors.green,
        );
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      String? errorMessage = e.response?.data["detail"];
      if (mounted) {
        showSnackBar(
          context,
          errorMessage ?? "Błąd usuwania",
          color: Colors.red,
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, "Nieznany błąd", color: Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isProcessing = _isUploading || _isDeleting;
    final int totalPhotos = _existingPhotoHashes.length + _newPhotos.length;

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
                      enabled: !isProcessing,
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Zdjęcia ($totalPhotos/3)',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (totalPhotos < 3)
                          ElevatedButton.icon(
                            onPressed: isProcessing ? null : _pickAndCropImage,
                            icon: const Icon(
                              Icons.add_photo_alternate,
                              size: 20,
                            ),
                            label: const Text('Dodaj'),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (_existingPhotoHashes.isNotEmpty) ...[
                      const Text(
                        'Obecne zdjęcia:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: _existingPhotoHashes.length,
                        itemBuilder: (context, index) {
                          final photoHash = _existingPhotoHashes[index];
                          final isDeleting = _deletingPhotos.contains(
                            photoHash,
                          );

                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Opacity(
                                  opacity: isDeleting ? 0.3 : 1.0,
                                  child: FutureBuilder<Uint8List>(
                                    future: () async {
                                      final client = RequestClient();
                                      await client.initialize();
                                      return client.getImage(
                                        '/users/verified-user/photo/$photoHash',
                                      );
                                    }(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      } else if (snapshot.hasError ||
                                          !snapshot.hasData) {
                                        return Container(
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.error),
                                        );
                                      } else {
                                        return Image.memory(
                                          snapshot.data!,
                                          fit: BoxFit.cover,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.red,
                                  child: isDeleting
                                      ? const Padding(
                                          padding: EdgeInsets.all(4.0),
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : IconButton(
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(
                                            Icons.close,
                                            size: 16,
                                          ),
                                          color: Colors.white,
                                          onPressed: isProcessing
                                              ? null
                                              : () => _deleteExistingPhoto(
                                                  photoHash,
                                                ),
                                        ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Nowe zdjęcia
                    if (_newPhotos.isNotEmpty) ...[
                      const Text(
                        'Nowe zdjęcia:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: _newPhotos.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _newPhotos[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'NOWE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
                                    onPressed: isProcessing
                                        ? null
                                        : () => _removeNewPhoto(index),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],

                    if (_existingPhotoHashes.isEmpty && _newPhotos.isEmpty)
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
                      ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: isProcessing ? null : _updateUser,
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
                        : const Text(
                            'Zaktualizuj',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: isProcessing ? null : _deleteUser,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: _isDeleting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.red,
                            ),
                          )
                        : const Text(
                            'Usuń użytkownika',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
