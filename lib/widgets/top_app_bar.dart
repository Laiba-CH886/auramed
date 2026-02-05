import 'package:flutter/material.dart';

class TopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showProfile;
  final VoidCallback? onProfileTap;

  const TopAppBar({super.key, required this.title, this.showProfile = false, this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: false,
      backgroundColor: Colors.white,
      elevation: 0,
       actions: [
        if (showProfile)
          IconButton(
            onPressed: onProfileTap,
            icon: const CircleAvatar(child: Icon(Icons.person, size: 18, color: Colors.white), backgroundColor: Color(0xFF9A6BFF)),
          )
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
