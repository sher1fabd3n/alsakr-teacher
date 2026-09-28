import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Cached student photo with optional Hero transition support.
class StudentAvatar extends StatelessWidget {
  const StudentAvatar({
    super.key,
    required this.studentId,
    required this.name,
    this.photoUrl,
    this.radius = 28,
    this.enableHero = false,
    this.parallaxOffset = 0,
  });

  final int studentId;
  final String name;
  final String? photoUrl;
  final double radius;
  final bool enableHero;
  final double parallaxOffset;

  @override
  Widget build(BuildContext context) {
    final avatar = Transform.translate(
      offset: Offset(parallaxOffset, parallaxOffset * 0.15),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        child: ClipOval(
          child: photoUrl != null && photoUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: photoUrl!,
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                  memCacheWidth: (radius * 2 * MediaQuery.devicePixelRatioOf(context)).round(),
                  placeholder: (context, url) => _Initials(name: name, radius: radius),
                  errorWidget: (context, url, error) => _Initials(name: name, radius: radius),
                )
              : _Initials(name: name, radius: radius),
        ),
      ),
    );

    if (!enableHero) return avatar;

    return Hero(
      tag: 'child-photo-$studentId',
      child: Material(
        color: Colors.transparent,
        child: avatar,
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name, required this.radius});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0] : '?',
          style: TextStyle(
            fontSize: radius * 0.85,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
