import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_icons.dart';

class AppAvatar extends StatelessWidget {
  final String? imageSource;
  final double radius;
  final String? fallbackText;
  final IconData fallbackIcon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isEditable;
  final VoidCallback? onTap;

  const AppAvatar({
    super.key,
    this.imageSource,
    this.radius = 22,
    this.fallbackText,
    this.fallbackIcon = AppIcons.users,
    this.backgroundColor,
    this.foregroundColor,
    this.isEditable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final bg = backgroundColor ?? AppColors.primarySoft;
    final fg = foregroundColor ?? AppColors.primary;

    Widget content;
    final src = imageSource?.trim() ?? '';

    if (src.isNotEmpty) {
      if (src.startsWith('data:image') || src.contains('base64,')) {
        try {
          final base64Data = src.contains('base64,') ? src.split('base64,').last : src;
          final Uint8List bytes = base64Decode(base64Data);
          content = ClipOval(
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildFallback(fg),
            ),
          );
        } catch (_) {
          content = _buildFallback(fg);
        }
      } else if (src.startsWith('http://') || src.startsWith('https://')) {
        content = ClipOval(
          child: Image.network(
            src,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallback(fg),
          ),
        );
      } else {
        content = _buildFallback(fg);
      }
    } else {
      content = _buildFallback(fg);
    }

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: content,
    );

    if (isEditable) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(4.5),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 11,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildFallback(Color fg) {
    if (fallbackText != null && fallbackText!.trim().isNotEmpty) {
      final cleanText = fallbackText!.trim();
      final initial = cleanText.length >= 2
          ? cleanText.substring(0, 2).toUpperCase()
          : cleanText.substring(0, 1).toUpperCase();
      return Center(
        child: Text(
          initial,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.75,
          ),
        ),
      );
    }

    return Center(
      child: Icon(fallbackIcon, size: radius * 0.95, color: fg),
    );
  }
}
