import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../constants/app_icons.dart';

class AppImagePicker {
  static final ImagePicker _picker = ImagePicker();

  /// Prompts user to pick image from Camera or Gallery, compresses it, and returns base64 Data URI
  static Future<String?> showImageSourceDialog(
    BuildContext context, {
    String title = 'Upload Photo',
    bool allowRemove = true,
  }) async {
    final result = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(AppIcons.sparkles, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Camera Option
            InkWell(
              onTap: () async {
                Navigator.pop(sheetCtx, 'CAMERA');
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 22),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Take Photo from Camera', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                          Text('Capture live document or portrait', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    Icon(AppIcons.chevronRight, size: 16, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Gallery Option
            InkWell(
              onTap: () async {
                Navigator.pop(sheetCtx, 'GALLERY');
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.photo_library_outlined, color: AppColors.accentCyan, size: 22),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                          Text('Select JPEG or PNG from phone storage', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    Icon(AppIcons.chevronRight, size: 16, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),

            if (allowRemove) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () => Navigator.pop(sheetCtx, 'REMOVE'),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(AppIcons.trash, color: AppColors.danger, size: 20),
                      SizedBox(width: 14),
                      Text('Remove / Clear Current Photo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.danger)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (result == 'REMOVE') {
      return '';
    }

    if (result == 'CAMERA' || result == 'GALLERY') {
      try {
        final source = result == 'CAMERA' ? ImageSource.camera : ImageSource.gallery;
        final xfile = await _picker.pickImage(
          source: source,
          maxWidth: 600,
          maxHeight: 600,
          imageQuality: 85,
        );

        if (xfile != null) {
          final bytes = await xfile.readAsBytes();
          final base64String = base64Encode(bytes);
          return 'data:image/jpeg;base64,$base64String';
        }
      } catch (e) {
        debugPrint('Error picking image: $e');
      }
    }

    return null;
  }
}
