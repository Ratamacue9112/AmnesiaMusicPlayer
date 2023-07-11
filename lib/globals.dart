export 'dart:io';

export 'package:flutter/material.dart';
export 'package:flutter/widgets.dart';

export 'pages/home.dart';
export 'pages/artists.dart';
export 'pages/collections.dart';
export 'pages/tracklist.dart';
export 'pages/content_player.dart';

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'packages/context_menus.dart';

class AppStyles {
  static TextStyle mediumText = const TextStyle();
  static TextStyle mediumTextSecondary = const TextStyle();
  static TextStyle largeText = const TextStyle();
  static TextStyle titleText = const TextStyle();
  
  static ContextMenuButtonStyle contextMenuStyle = const ContextMenuButtonStyle();

  static void initStyles(ThemeData theme) {
    mediumText = theme.textTheme.bodyMedium!.copyWith(
      color: theme.colorScheme.onPrimary
    );
    mediumTextSecondary = theme.textTheme.bodyMedium!.copyWith(
      color: theme.colorScheme.onSecondary
    );
    largeText = theme.textTheme.bodyLarge!.copyWith(
      color: theme.colorScheme.onPrimary
    );
    titleText = theme.textTheme.headlineLarge!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    contextMenuStyle = ContextMenuButtonStyle(
      fgColor: theme.colorScheme.onSecondary,
      bgColor: theme.colorScheme.secondaryContainer,
      hoverFgColor: theme.colorScheme.onPrimary
    );
  }
}

class Globals {
  static String appDataPath = path.join('', Platform.environment['APPDATA'], 'AmnesiaMusicPlayer');
}
