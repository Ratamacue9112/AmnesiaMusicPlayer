export 'dart:io';

export 'package:flutter/material.dart';
export 'package:flutter/widgets.dart';
export 'package:provider/provider.dart';

export 'main.dart';
export 'classes.dart';
export 'pages/home.dart';
export 'pages/artists.dart';
export 'pages/collections.dart';
export 'pages/tracklist.dart';
export 'pages/song_content.dart';
export 'pages/content_player.dart';

export 'package:amnesia_music_player/packages/file_picker.dart';
export 'package:amnesia_music_player/packages/context_menus.dart';

import 'dart:io';
import 'package:amnesia_music_player/classes.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'packages/context_menus.dart';

class AppStyles {
  static TextStyle mediumText = const TextStyle();
  static TextStyle mediumTextSecondary = const TextStyle();
  static TextStyle largeText = const TextStyle();
  static TextStyle titleText = const TextStyle();
  static TextStyle titleTextSecondary = const TextStyle();
  
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
    titleTextSecondary = theme.textTheme.headlineLarge!.copyWith(
      color: theme.colorScheme.onSecondary,
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

class Utilities {
  static String listToString(List list) {
    String listString = '';
    for(int i = 0; i < list.length; i++) {
      if(list[i] is Track) {
        listString += '${(list[i] as Track).name}\n';
        continue;
      }
      listString += '${list[i]}\n';
    }
    return listString;
  }
}