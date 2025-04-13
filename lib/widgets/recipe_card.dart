// lib/widgets/recipe_card.dart
import 'package:flutter/material.dart';
import '../models/recipe_model.dart';

class RecipeCard extends StatelessWidget {
  final RecipeModel recipe;
  final VoidCallback onTap;
  final Widget? trailing;

  const RecipeCard({
    Key? key,
    required this.recipe,
    required this.onTap,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color accentColor = Theme.of(context).colorScheme.secondary;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 110,
              height: 110,
              child: Image.network(
                recipe.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (ctx, child, progress) => progress == null
                    ? child
                    : Center(
                        child: Padding(
                            padding: const EdgeInsets.all(30.0),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: accentColor))),
                errorBuilder: (ctx, err, st) => Container(
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: Icon(Icons.restaurant_menu,
                        color: Colors.grey[400], size: 40)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 12.0, right: 4.0, top: 10.0, bottom: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      recipe.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      recipe.category,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              recipe.isLikedByCurrentUser
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 16,
                              color: recipe.isLikedByCurrentUser
                                  ? Colors.red
                                  : Colors.red[400],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              recipe.likeCount.toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        if (trailing != null)
                          Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: trailing!),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
