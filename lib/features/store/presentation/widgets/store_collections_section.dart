import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class CollectionModel {
  final String id;
  final String title;
  final String emoji;
  final Color color;

  const CollectionModel({
    required this.id,
    required this.title,
    required this.emoji,
    required this.color,
  });
}

class StoreCollectionsSection extends StatelessWidget {
  final List<String> categories;

  const StoreCollectionsSection({
    super.key,
    required this.categories,
  });

  // Maps category names to visual styles
  static final _collectionStyles = [
    const _CollStyle(emoji: '🏆', color: Color(0xFFFFD700)),
    const _CollStyle(emoji: '✨', color: Color(0xFF5B8DEF)),
    const _CollStyle(emoji: '🌿', color: Color(0xFF4CAF82)),
    const _CollStyle(emoji: '🎉', color: Color(0xFFE8896B)),
    const _CollStyle(emoji: '❤️', color: Color(0xFFEF5B8D)),
    const _CollStyle(emoji: '🍃', color: Color(0xFF81C784)),
    const _CollStyle(emoji: '🛍️', color: Color(0xFFAA78D4)),
    const _CollStyle(emoji: '🌶️', color: Color(0xFFE53935)),
  ];

  @override
  Widget build(BuildContext context) {
    // Combine fixed collections with dynamic categories
    final allCollections = <String>['Best Sellers', 'New Arrivals', ...categories]
        .toSet()
        .take(8)
        .toList();

    if (allCollections.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                'Collections',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: allCollections.length,
            itemBuilder: (context, index) {
              final style = _collectionStyles[index % _collectionStyles.length];
              final title = allCollections[index];
              return _CollectionCard(title: title, style: style);
            },
          ),
        ),
      ],
    );
  }
}

class _CollStyle {
  final String emoji;
  final Color color;
  const _CollStyle({required this.emoji, required this.color});
}

class _CollectionCard extends StatelessWidget {
  final String title;
  final _CollStyle style;

  const _CollectionCard({required this.title, required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 110,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: style.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: style.color.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  style.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: style.color.withOpacity(0.85),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
