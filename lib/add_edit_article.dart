import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class AddEditArticle extends StatefulWidget {
  final Map<String, dynamic>? article;

  const AddEditArticle({super.key, this.article});

  @override
  State<AddEditArticle> createState() => _AddEditArticleState();
}

class _AddEditArticleState extends State<AddEditArticle> {
  final _formkey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  File? _image;
  String _imageUrl = '';

  @override
  void initState() {
    super.initState();
    if (widget.article != null) {
      _titleController.text = widget.article!['title'];
      _contentController.text = widget.article!['content'];
      _authorController.text = widget.article!['author'];
      _imageUrl = widget.article!['imageUrl'];
    }
  }

  Future<void> _pickImage() async {
    if (await Permission.storage.request().isGranted) {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } else {
      debugPrint("Permission not granted");
    }
  }

  Future<void> _uploadImage() async {
    if (_image != null) {
      String fileName = _image!.path.split('/').last;
      Reference firebaseStorageRef =
          FirebaseStorage.instance.ref().child('news_image/$fileName');
      UploadTask uploadTask = firebaseStorageRef.putFile(_image!);
      TaskSnapshot taskSnapshot = await uploadTask;
      _imageUrl = await taskSnapshot.ref.getDownloadURL();
    }
  }

  Future<void> _saveArticle() async {
    if (_formkey.currentState!.validate()) {
      await _uploadImage();

      Map<String, dynamic> articleData = {
        'title': _titleController.text,
        'content': _contentController.text,
        'author': _authorController.text,
        'imageUrl': _imageUrl,
        'timestamp': Timestamp.now(),
      };

      if (widget.article == null) {
        // Add new article
        await FirebaseFirestore.instance.collection('news_articles').add(articleData);
      } else {
        // Update existing article
        await FirebaseFirestore.instance
            .collection('news_articles')
            .doc(widget.article!['id']) // Use document ID to update
            .update(articleData);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 106, 111, 67),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.article == null ? "Add News" : "Edit News",
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formkey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                _image == null && _imageUrl.isEmpty
                    ? InkWell(
                        onTap: _pickImage,
                        child: Container(
                          height: 250,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color.fromARGB(255, 158, 158, 158)),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.image,
                              size: 60,
                              color: Color.fromARGB(15, 249, 38, 94),
                            ),
                          ),
                        ),
                      )
                    : _image != null
                        ? InkWell(
                            onTap: _pickImage,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                _image!,
                                height: 250,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        : InkWell(
                            onTap: _pickImage,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                _imageUrl,
                                height: 250,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: "Title",
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Please enter a title";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _contentController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: "Content",
                    prefixIcon: Icon(Icons.article),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Please enter a content";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _authorController,
                  decoration: const InputDecoration(
                    labelText: "Author",
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Please enter an author";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: _saveArticle,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: 55,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9A826),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        widget.article == null ? "Add News" : "Update News",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
     ),
);
}
}
