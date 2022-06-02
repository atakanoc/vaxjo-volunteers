import 'dart:io';
import '/pages/profilePage.dart';
import 'package:hello_world/widgets/appBarTitle.dart';
import '../utils.dart';
import '../widgets/category_dropdown.dart';
import 'package:flutter/material.dart';
import '../model/post.dart';
import '../widgets/new_submission.dart';
import '../widgets/posts_feed.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Post> _postPreviews = List<Post>.empty(
      growable: true); // this list can be changed depending on category
  late List<Post> allPosts; // this list represents all posts and is not changed
  final Set<int> _favorites = {};
  final List<String> _categories = List<String>.empty(growable: true);
  var currentItem = 'All';
  bool viewFavorites = false;

//fetches data depending on the passed command
// saves datadepending on the passed function
  _fetchData(String command, Function function) async {
    String token = Utils.token;

    final uri = Uri.http(Utils.IP, command);
    final response =
        await http.get(uri, headers: {HttpHeaders.authorizationHeader: token});

    if (response.statusCode == 200) {
      setState(() {
        List<dynamic> dataList = jsonDecode(utf8.decode(
            response.bodyBytes)); // consider this process for other responses
        function(dataList);
      });
    } else {
      throw Exception("Failed to load data");
    }
  }

// passed into the _fetchData
  _populatePosts(List<dynamic> dataList) {
    _postPreviews.clear();
    for (var value in dataList) {
      Post post = Post.fromJson(value);
      _postPreviews.add(post);
    }
    allPosts = [..._postPreviews];
    currentItem = 'All';
  }

// passed into the _fetchDat
  _populateCategories(List<dynamic> dataList) {
    _categories.add(currentItem);
    for (var value in dataList) {
      _categories.add(value);
    }
  }

  // passed into _fetchData
  _updateFavorites(List<dynamic> dataList) {
    _favorites.clear();
    for (int entry in dataList) {
      _favorites.add(entry);
    }
  }

  _getFavorites() async {
    final token = Utils.token;
    const command = "/get-favorites";

    final uri = Uri.http(Utils.IP, command);
    final response =
        await http.post(uri, headers: {HttpHeaders.authorizationHeader: token});

    if (response.statusCode == 200) {
      List<dynamic> newFavorites = jsonDecode(response.body);
      _favorites.clear();
      for (int entry in newFavorites) {
        _favorites.add(entry);
      }
    } else {
      debugPrint("server didn't like us");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchData('/get-posts', _populatePosts);
    _fetchData('/get-category', _populateCategories);
    _getFavorites();
  }

  // show submission form when pressing on floating + button
  // pops up from the bottom of the page
  void _showSubmissionForm(BuildContext context) {
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: NewSubmission(_categories.sublist(1), false),
          );
        });
  }

  // redraw posts depending on the category choice
  void _showFilteredPosts(String selectedItem) {
    setState(() {
      if (selectedItem != 'Favorites') {
        // this way I don't have to figure out how to read the dropdown menu from _showFavorites
        // if 'Favorites' is sent, the current filter is simply kept
        // the method knows if favorites should also be filtered or not based on the field viewFavorites
        currentItem = selectedItem;
      }

      if (viewFavorites) {
        _postPreviews.clear();
        if (currentItem == 'All') {
          for (Post p in allPosts) {
            if (_favorites.contains(p.postID)) {
              _postPreviews.add(p);
            }
          }
        } else {
          for (Post p in allPosts) {
            if (_favorites.contains(p.postID) && p.category == currentItem) {
              _postPreviews.add(p);
            }
          }
        }
      } else {
        if (currentItem == 'All') {
          _postPreviews = [...allPosts];
        } else {
          _postPreviews.clear();
          for (Post p in allPosts) {
            if (p.category == currentItem) {
              _postPreviews.add(p);
            }
          }
        }
      }
    });
  }

  void _showFavorites() async {
    viewFavorites = !viewFavorites; // the most beautiful toggle

    if (viewFavorites) {
      await _getFavorites();
      // await _fetchData("/get-favorites", _updateFavorites); // i have no idea why this doesn't work
    }

    _showFilteredPosts('Favorites');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(),
        leading: IconButton(
          onPressed: () {
            // TODO: Make it come from the left, not right.
            Navigator.pushNamed(context, '/settings');
          },
          icon: const Icon(Icons.settings),
        ),
      ),
      body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
                child: CategoryDropDown(_categories, _showFilteredPosts, currentItem),
            ),
            Expanded(
                child: PostsFeed(
                    _postPreviews,
                    () => {_fetchData('/get-posts', _populatePosts)},
                    _favorites)),
          ]),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        elevation: 10,
        onPressed: () => _showSubmissionForm(context),
      ),
      bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 5.0,
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                IconButton(
                  icon: viewFavorites
                      ? const Icon(Icons.bookmark)
                      : const Icon(Icons.bookmark_outline_rounded),
                  padding: const EdgeInsets.only(right: 20),
                  iconSize: 40,
                  onPressed: () {
                    _showFavorites();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.account_box),
                  padding: const EdgeInsets.only(left: 20),
                  iconSize: 40,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) => ProfilePage(
                          posts: allPosts,
                          categories: _categories,
                        ),
                      ),
                    );
                  },
                ),
              ])),
    );
  }
}
