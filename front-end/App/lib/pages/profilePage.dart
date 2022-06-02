import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import '../model/user.dart';
import '../widgets/posts_feed.dart';
import '../utils.dart';
import '../widgets/appBarTitle.dart';
import '../widgets/textFieldWidget.dart';
import 'package:http/http.dart' as http;
import '../model/post.dart';
import '../widgets/profileWidget.dart';

class ProfilePage extends StatefulWidget {
  final List<Post> posts;
  final List<String> categories;

  ProfilePage({Key? key, required this.posts, required this.categories})
      : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<User> futureUser;
  late User user;
  List<Post> ownPosts = List<Post>.empty(growable: true);
  final textController = TextEditingController();
  bool isEditing = false;

  Future<User> _fetchUser() async {
    String token = Utils.token;

    final uri = Uri.http(Utils.IP, "/profile");
    final response =
        await http.get(uri, headers: {HttpHeaders.authorizationHeader: token});

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to load data");
  }

  List<Post> _getOwnPosts(List<Post> posts, User user) {
    List<Post> ownPosts = List<Post>.empty(growable: true);
    for (Post post in posts) {
      if (post.authorID == user.google_id) {
        ownPosts.add(post);
      }
    }
    return ownPosts;
  }

  @override
  void initState() {
    super.initState();
    futureUser = _fetchUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: AppBarTitle(),
        ),
        body: FutureBuilder<User>(
            future: futureUser,
            builder: (context, AsyncSnapshot<User> snapshot) {
              if (snapshot.hasData) {
                user = snapshot.data!;
                ownPosts = _getOwnPosts(widget.posts, user);

                return Column(
                  children: [
                    const SizedBox(height: 24),
                    ProfileWidget(
                      profileImage: user.profile_image,
                      onClicked: () {},
                      iconOverlay: isEditing
                          ? buildSaveButton(context)
                          : buildEditButton(context),
                    ),
                    const SizedBox(height: 24),
                    buildName(user),
                    const SizedBox(height: 24),
                    isEditing ? buildEditAboutMe() : buildAbout(user),
                    if (!isEditing)
                      Expanded(
                        child: PostsFeed.ownPostFeed(
                            ownPosts, () {}, true, widget.categories),
                      )
                  ],
                );
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }
              return const CircularProgressIndicator();
            }));
  }

  buildName(User user) => Column(
        children: [
          Text(
            user.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
          SizedBox(height: 4),
          Text(
            "Moderator status: " + user.is_moderator.toString(),
            style: TextStyle(color: Colors.grey),
          )
        ],
      );

  buildAbout(User user) => Container(
        padding: EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About me',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              user.about_me,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
          ],
        ),
      );

// edit button
  Widget buildEditButton(BuildContext context) => buildCircle(
      color: Theme.of(context).scaffoldBackgroundColor,
      all: 0,
      child: FloatingActionButton(
        onPressed: () => setState(() {
          isEditing = true;
        }),
        mini: true,
        child: const Icon(
          Icons.edit,
          size: 15,
          color: Colors.white,
        ),
      ));

  // save button
  Widget buildSaveButton(BuildContext context) => buildCircle(
        color: Theme.of(context).scaffoldBackgroundColor,
        all: 0,
        child: FloatingActionButton(
            onPressed: _updateUserAboutMe,
            mini: true,
            child: const Icon(
              Icons.save,
              size: 20,
              color: Colors.white,
            )),
      );

// circle for buttons
  buildCircle(
          {required Color color,
          required double all,
          required FloatingActionButton child}) =>
      ClipOval(
        child: Container(
          color: color,
          child: child,
        ),
      );

// text field in order to edit about me
  Widget buildEditAboutMe() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: TextFieldWidget(
        maxLines: 15,
        label: 'About me :',
        text: user.about_me,
        onChanged: (_) {},
        controller: textController,
        maxChar: 1000,
      ),
    );
  }

// send changes to the backend and rebuild the state
  _updateUserAboutMe() async {
    final uri = Uri.http(Utils.IP, '/update-aboutMe');
    final headers = {HttpHeaders.authorizationHeader: Utils.token};
    final json = jsonEncode(User(user.google_id, user.name, user.profile_image,
        textController.text, user.is_disabled, user.is_moderator));
    final response = await http.post(uri, headers: headers, body: json);
    print('Status code: ${response.statusCode}');
    setState(() {
      isEditing = false;
      futureUser = _fetchUser();
    });
  }
}
