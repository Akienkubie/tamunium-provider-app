import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TamuniumAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final bool verified;

  const TamuniumAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 72,
    this.verified = false,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'T';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: AppTheme.navy,
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: size * .28),
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.gold, width: 2),
          ),
          child: ClipOval(
            child: imageUrl == null || imageUrl!.isEmpty
                ? fallback
                : CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => fallback,
                    errorWidget: (_, __, ___) => fallback,
                  ),
          ),
        ),
        if (verified)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: size * .28,
              height: size * .28,
              decoration: const BoxDecoration(color: AppTheme.gold, shape: BoxShape.circle),
              child: Icon(Icons.check, size: size * .18, color: AppTheme.navy),
            ),
          ),
      ],
    );
  }
}
