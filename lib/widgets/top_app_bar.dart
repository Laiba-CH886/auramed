import 'package:flutter/material.dart';

class TopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showProfile;
  final VoidCallback? onProfileTap;

  // ✅ ADD THIS
  final List<Widget>? actions;

  const TopAppBar({
    super.key,
    required this.title,
    this.showProfile = false,
    this.onProfileTap,
    this.actions, // ✅ ADD HERE
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: false,
      backgroundColor: Colors.white,
      elevation: 0,

      // ✅ MERGE BOTH PROFILE + EXTRA ACTIONS
      actions: [
        if (showProfile)
          IconButton(
            onPressed: onProfileTap,
            icon: const CircleAvatar(
              backgroundColor: Color(0xFF9A6BFF),
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ),

        // ✅ ADD THIS LINE (VERY IMPORTANT)
        ...?actions,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}