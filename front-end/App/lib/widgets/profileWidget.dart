import 'package:flutter/material.dart';

class ProfileWidget extends StatelessWidget {
  final String profileImage;
  final VoidCallback onClicked;
  final Widget iconOverlay;
  const ProfileWidget({
    Key? key,
    required this.profileImage,
    required this.onClicked,
    required this.iconOverlay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          buildImage(),
          Positioned(
            bottom: 0,
            right: -5,
            child: iconOverlay,
          ),
        ],
      ),
    );
  }

  Widget buildImage() {
    final image = NetworkImage(profileImage);
    return ClipOval(
      child: Material(
        color: Colors.transparent,
        child: Ink.image(
            image: image,
            fit: BoxFit.cover,
            width: 128,
            height: 128,
            child: InkWell(onTap: onClicked)),
      ),
    );
  }
}
