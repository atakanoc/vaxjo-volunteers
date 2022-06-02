import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../utils.dart';
import '../model/post.dart';
import 'ownPostActions.dart';
import 'new_submission.dart';

class PostsFeed extends StatefulWidget {
  final List<Post> posts;
  final Function refreshPosts;
  final Set<int> favorites;
  bool isOwnFeed = false;
  List<String> categories = [];

  PostsFeed(this.posts, this.refreshPosts, this.favorites, {Key? key})
      : super(key: key);
  PostsFeed.ownPostFeed(
      this.posts, this.refreshPosts, this.isOwnFeed, this.categories,
      {Key? key})
      : favorites = {},
        super(key: key);

  @override
  State<PostsFeed> createState() => _PostsFeedState();
}

// view will be updated with filled/empty hearts when faving/unfaving
// this does not involve requesting the new list from the server
// but it's only done if the server returns 200
// new list is still fetched when the faves filter is used in the footer
class _PostsFeedState extends State<PostsFeed> {
  // get response code depending on the command to the server
  Future<int> getResponseCode(String command, int toEncode) async {
    final token = Utils.token;
    final json = jsonEncode(toEncode);
    final uri = Uri.http(Utils.IP, command);
    final response = await http.post(uri,
        headers: {HttpHeaders.authorizationHeader: token}, body: json);
    return response.statusCode;
  }

  // delete own post
  voidDeleteOwnPost(Post post) async {
    final statusCode = await getResponseCode("/delete-post", post.postID);
    setState(() {
      if (statusCode == 200) {
        widget.posts.remove(post);
      }
      Utils.showOperationStatus('Deletion state', statusCode, context);
    });
  }

  // update own edited post in the own posts list
  updateOwnEditedPostView(Post post) {
    for (Post p in widget.posts) {
      if (p.postID == post.postID) {
        setState(() {
          int index = widget.posts.indexOf(p);
          widget.posts[index] = post;
        });
        return;
      }
    }
  }

  // show edit post bottom sheet form
  void showEditPostForm(BuildContext context, Post post) {
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: NewSubmission.editOwnPost(widget.categories.sublist(1), true,
                post, updateOwnEditedPostView),
          );
        });
  }

  // request manual moderation of rejected post
  void contestFilter(int postID) async {
    final statusCode = await getResponseCode("/pending-post", postID);
    if (statusCode == 200) {
      debugPrint("Contest filter: Server liked us");
    } else if (statusCode == 412) {
      debugPrint("Contest filter: Already a pending post, says server");
    } else {
      debugPrint("Contest filter: Server didn't like us");
    }
  }

  // add favorite
  void addFavorite(int postID) async {
    final statusCode = await getResponseCode("/add-favorite", postID);
    if (statusCode == 200) {
      debugPrint("Add favorite: Server liked us");
      widget.favorites.add(postID);
      setState(() {});
    } else if (statusCode == 412) {
      debugPrint("Add favorite: Already a favorite, says server");
    } else {
      debugPrint("Add favorite: Server didn't like us");
    }
  }

// remove favorite
  void removeFavorite(int postID) async {
    final statusCode = await getResponseCode("/remove-favorite", postID);
    // TODO
    if (statusCode == 200) {
      debugPrint("Remove favorite: Server liked us");
      widget.favorites.remove(postID);
      setState(() {});
    } else if (statusCode == 412) {
      debugPrint("Remove favorite: Already not a favorite, says server");
    } else {
      debugPrint("Remove favorite: Server didn't like us");
    }
  }

// approve post
  void approvePost(int postID) async {
    final statusCode = await getResponseCode("/approve-post", postID);
    // TODO
    if (statusCode == 200) {
      debugPrint("Approve post: Server liked us");
    } else if (statusCode == 412) {
      debugPrint("Approve post: Already approved, says server");
    } else {
      debugPrint("Approve post: Server didn't like us");
    }
  }

// pending post
  void pendingPost(int postID) async {
    final statusCode = await getResponseCode("/pending-post", postID);
    // TODO
    if (statusCode == 200) {
      debugPrint("Pending post: Server liked us");
    } else if (statusCode == 412) {
      debugPrint("Pending post: Already pending, says server");
    } else {
      debugPrint("Pending post: Server didn't like us");
    }
  }

  void hidePost(int postID) async {
    final statusCode = await getResponseCode("/hide-post", postID);
    // TODO
    if (statusCode == 200) {
      debugPrint("Hide post: Server liked us");
    } else if (statusCode == 412) {
      debugPrint("Hide post: Already hidden, says server");
    } else {
      debugPrint("Hide post: Server didn't like us");
    }
  }

  // TODO: make this incorporate the theme
  Color getColor(Post post, BuildContext context) {
    String status = post.status!;
    if (status == "Hidden") {
      return Colors.red.shade500;
    } else if (status == "Pending") {
      return Colors.yellow.shade700;
    } else {
      return Theme.of(context).cardColor;
    }
  }

  List<Post> visiblePostsOnly() {
    List<Post> visiblePosts = [];

    for (Post post in widget.posts) {
      if (post.status == "Approved") {
        visiblePosts.add(post);
      }
    }

    return visiblePosts;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOwnFeed) {
      return RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(seconds: 1));
            widget.refreshPosts();
          },
          triggerMode: RefreshIndicatorTriggerMode.anywhere,
          child: buildListView());
    }
    return buildListView();
  }

  // build the posts feed view
  buildListView() {
    List<Post> postList = !widget.isOwnFeed && !Utils.currentUser!.is_moderator
        ? visiblePostsOnly()
        : widget.posts;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(5),
      itemCount: postList.length,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        return Card(
          elevation: 10,
          color: getColor(postList[index], context),
          shadowColor: Theme.of(context).primaryColor,
          child: ExpansionTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                widget.isOwnFeed
                    ? postList[index].status == "Hidden"
                        ? OwnPostActions.rejectedPost(() {
                            voidDeleteOwnPost(postList[index]);
                          }, () {
                            showEditPostForm(context, postList[index]);
                          }, () {
                            contestFilter(postList[index].postID);
                          })
                        : OwnPostActions(() {
                            voidDeleteOwnPost(postList[index]);
                          }, () {
                            showEditPostForm(context, postList[index]);
                          })
                    : buildFavoriteButton(postList[index]),
                showPostTitle(postList[index]),
                SizedBox(
                  width: 120,
                  child: showDateCatAuthor(postList[index]),
                )
              ],
            ),
            children: <Widget>[
              ListTile(
                  title: Text(postList[index].description),
                  subtitle: postList[index].status == "Hidden"
                      ? Text("Reason(s) for rejection: " +
                          postList[index].modComment!)
                      : null),
              if (Utils.currentUser!.is_moderator)
                buildModerationOptions(postList[index]),
            ],
          ),
        );
      },
    );
  }

// display date, category and author of the post
  Widget showDateCatAuthor(Post post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          DateFormat.yMMMd().format(post.date),
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        Text(
          '#' + post.category,
          style: const TextStyle(
            fontSize: 13,
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
        Text(
          post.authorName.toString(),
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  // show post title
  Widget showPostTitle(Post post) {
    return Expanded(
      child: Text(
        post.title,
        textAlign: TextAlign.left,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
        softWrap: true,
        maxLines: 5,
        overflow: TextOverflow.fade,
      ),
    );
  }

  // build favorite button
  Widget buildFavoriteButton(Post post) {
    return IconButton(
      icon: widget.favorites.contains(post.postID)
          ? const Icon(Icons.favorite)
          : const Icon(Icons.favorite_border),
      padding: EdgeInsets.only(right: 10),
      constraints: BoxConstraints(),
      onPressed: () {
        if (widget.favorites.contains(post.postID)) {
          debugPrint("This is favorited. Unfavoriting.");
          removeFavorite(post.postID);
        } else {
          debugPrint("This is not favorited. Favoriting.");
          addFavorite(post.postID);
        }
      },
    );
  }

  // build moderation button
  Widget buildModerationButton(
      String tooltip, Function foo, Post post, Icon icon) {
    return IconButton(
        tooltip: tooltip,
        onPressed: () {
          foo(post.postID);
        },
        icon: icon);
  }

  // build moderation options from moderation buttons
  Widget buildModerationOptions(Post post) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        buildModerationButton(
            "Approve post", approvePost, post, const Icon(Icons.thumb_up)),
        buildModerationButton(
            "Set post to Pending", pendingPost, post, const Icon(Icons.policy)),
        buildModerationButton(
            "Hide post", hidePost, post, const Icon(Icons.thumb_down)),
      ],
    );
  }
}
