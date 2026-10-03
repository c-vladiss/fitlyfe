import 'package:flutter/material.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';

class MealIconMapping {
  static const Map<String, IconData> icons = {
    'coffee': Icons.coffee,
    'soup_kitchen': Icons.soup_kitchen,
    'dinner': Icons.dinner_dining,
    'cookie': Icons.cookie,
    'lunch_dining': Icons.lunch_dining,
    'pizza': Icons.local_pizza,
    'cake': Icons.cake,
    'meat': Icons.set_meal,
    'egg': Icons.egg,
    'drink': Icons.local_drink,
    'restaurant': Icons.restaurant,
    'flatware': Icons.flatware,
    'apple': Icons.cookie,
    'icecream': Icons.icecream,
    'kebab': Icons.kebab_dining,
  };
  
  static const Map<String, Color> colors = {
    'coffee': AppTheme.accentOrange,
    'soup_kitchen': AppTheme.accentGreen,
    'dinner': AppTheme.accentBlue,
    'cookie': AppTheme.accentRed,
    'lunch_dining': AppTheme.accentYellow,
    'pizza': AppTheme.accentOrange,
    'cake': AppTheme.accentPurple,
    'meat': AppTheme.accentRed,
    'egg': AppTheme.accentYellow,
    'drink': AppTheme.accentBlue,
    'restaurant': AppTheme.secondaryText,
    'flatware': AppTheme.secondaryText,
    'apple': AppTheme.accentRed,
    'icecream': AppTheme.accentPurple,
    'kebab': AppTheme.accentOrange,
  };

  static String mapEmojiToKey(String emoji) {
    switch (emoji) {
      case '☕': return 'coffee';
      case '🍲': return 'soup_kitchen';
      case '🥗': return 'dinner';
      case '🍎': return 'cookie';
      case '🥪': return 'lunch_dining';
      case '🍕': return 'pizza';
      case '🍰': return 'cake';
      case '🥩': return 'meat';
      case '🥚': return 'egg';
      case '🥛': return 'drink';
      case '🍽️': return 'restaurant';
      case '🍦': return 'icecream';
      case '🍢': return 'kebab';
      default: return 'flatware';
    }
  }

  static Widget buildIcon(String iconKey, {double size = 24, Color? overrideColor}) {
    // If it's an emoji from old data, successfully remap it to the new identifier
    String internalKey = icons.containsKey(iconKey) ? iconKey : mapEmojiToKey(iconKey);
    
    return Icon(
      icons[internalKey] ?? Icons.flatware,
      color: overrideColor ?? colors[internalKey] ?? AppTheme.secondaryText,
      size: size,
    );
  }
}
