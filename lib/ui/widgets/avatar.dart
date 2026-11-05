import 'package:flutter/material.dart';

import '../../auth/app_user.dart';
import '../../core/theme.dart';

/// A square profile picture with an ink outline: the photo if there is one,
/// otherwise the user's initials.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.user, this.size = 72});
  final AppUser user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = user.photoUrl;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Snag.paperDeep,
        border: Border.all(color: Snag.ink, width: Snag.outline),
        borderRadius: BorderRadius.circular(Snag.radius),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: url == null
          ? Text(user.initials, style: Snag.label(size: size / 3))
          : Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  Text(user.initials, style: Snag.label(size: size / 3)),
            ),
    );
  }
}
