// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../model/userPost.dart';
import '../utils.dart';
import 'category_dropdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../model/post.dart';

class NewSubmission extends StatefulWidget {
  final List<String> categories;
  final bool isEditingOwnPost;
  late Post ownPost;
  late Function updateEditedPostView;

  NewSubmission(this.categories, this.isEditingOwnPost, {Key? key})
      : super(key: key);

  NewSubmission.editOwnPost(this.categories, this.isEditingOwnPost,
      this.ownPost, this.updateEditedPostView,
      {Key? key})
      : super(key: key);

  @override
  State<NewSubmission> createState() => _NewSubmissionState();
}

class _NewSubmissionState extends State<NewSubmission> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  late String currentItem =
      widget.isEditingOwnPost ? widget.ownPost.category : widget.categories[0];
  bool isLoading = false;
  late Post editedPost;

  @override
  void initState() {
    super.initState();
    if (widget.isEditingOwnPost) {
      titleController.text = widget.ownPost.title;
      descriptionController.text = widget.ownPost.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Card(
        margin: const EdgeInsets.only(left: 10, right: 10, bottom: 20),
        shadowColor: Theme.of(context).primaryColor,
        elevation: 60,
        child: isLoading
            ? const LinearProgressIndicator()
            : Container(
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 5),
                child:
                    Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                  CategoryDropDown(
                      widget.categories, _updateCurrentItem, currentItem),
                  const SizedBox(
                    height: 10,
                  ),
                  _createField(titleController, 2, 50, 'Title'),
                  const SizedBox(
                    height: 10,
                  ),
                  _createField(descriptionController, 10, 1000, 'Description'),
                  FlatButton(
                    onPressed: () {
                      setState(() {
                        isLoading = true;
                      });
                      _submitPost(context);
                    },
                    child: const Text(
                      'Submit',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    textColor: Theme.of(context).primaryColor,
                  ),
                ]),
              ),
      ),
    );
  }

// returns an input field for title or description
  TextFormField _createField(
      TextEditingController controller, int lines, int length, String title) {
    return TextFormField(
      validator: (text) {
        if (text == null || text.isEmpty) {
          return 'This field cannot be empty';
        }
        return null;
      },
      controller: controller,
      keyboardType: TextInputType.multiline,
      maxLines: lines,
      decoration: InputDecoration(
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        hintText: title,
      ),
      maxLength: length,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
    );
  }

// updates the value of the chosen category
  _updateCurrentItem(String newItem) {
    setState(() {
      currentItem = newItem;
    });
  }

// creates the instance of the Post if user input has passed the local flutter validation.
// then calls method _postToServer
  _submitPost(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    postToServer(encodePost(), commandToServer(), header());
  }

// encode post depending on if it is a new post or editing of already existing post
  String encodePost() {
    if (widget.isEditingOwnPost) {
      editedPost = Post(
          widget.ownPost.postID,
          widget.ownPost.authorID,
          widget.ownPost.authorName,
          titleController.text,
          descriptionController.text,
          widget.ownPost.date,
          currentItem,
          widget.ownPost.status,
          widget.ownPost.modComment);
      return jsonEncode(editedPost);
    }
    return jsonEncode(UserPost(
        titleController.text, descriptionController.text, currentItem));
  }

  // send post entity to the server
  postToServer(String json, String command, String header) async {
    final uri = Uri.http(Utils.IP, command);
    final headers = {HttpHeaders.authorizationHeader: Utils.token};
    final response = await http.post(uri, headers: headers, body: json);

    setState(() {
      isLoading = false;
      Navigator.of(context).pop();
      Utils.showOperationStatus(header, response.statusCode, context);
    });
    if (widget.isEditingOwnPost) {
      if (response.statusCode == 200 || response.statusCode == 400) {
        Post post = Post.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
        widget.updateEditedPostView(post);
      }
    }
  }

// return command to the post request whether it is
// the submission of the new post or editing of hte existing post
  String commandToServer() {
    if (widget.isEditingOwnPost) {
      return '/edit-post';
    }
    return '/post-submission';
  }

// choose the header for the notification dialog whether it is
// the submission of the new post or editing of the existing post
  String header() {
    if (widget.isEditingOwnPost) {
      return 'Editing status';
    }
    return 'Submission status';
  }
}
