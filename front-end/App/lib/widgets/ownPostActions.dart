import 'package:flutter/material.dart';

class OwnPostActions extends StatelessWidget {
  Function deletePost;
  Function editPost;
  Function? contestFilter;
  bool isRejected = false;

  OwnPostActions(this.deletePost, this.editPost, {Key? key}) : super(key: key);
  OwnPostActions.rejectedPost(
      this.deletePost, this.editPost, this.contestFilter, {Key? key}) : super(key: key) {
    isRejected = true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz),
          onSelected: (String selected) {
            switch (selected) {
              case 'Delete':
                deletePost();
                break;
              case 'Edit':
                editPost();
                break;
              case 'Contest':
                contestFilter!();
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'Delete',
              child: Text('Delete'),
            ),
            const PopupMenuItem<String>(
              value: 'Edit',
              child: Text('Edit'),
            ),
            if (isRejected)
              const PopupMenuItem<String>(
                value: 'Contest',
                child: Text('Request manual moderation'),
              ),
          ],
        ),
        const SizedBox(
          height: 40,
        ),
      ],
    );
  }
}
