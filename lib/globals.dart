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

export 'widgets/audio_player_widget.dart';

export 'package:file_picker/file_picker.dart';
export 'package:context_menus/context_menus.dart';
export 'package:dart_vlc/dart_vlc.dart';
export 'package:just_audio/just_audio.dart';

import 'dart:io';
import 'package:amnesia_music_player/classes.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:context_menus/context_menus.dart';

class AppStyles {
  static TextStyle mediumText = const TextStyle();
  static TextStyle mediumTextSecondary = const TextStyle();
  static TextStyle largeText = const TextStyle();
  static TextStyle largeTextSecondary = const TextStyle();
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
    largeTextSecondary = theme.textTheme.bodyLarge!.copyWith(
      color: theme.colorScheme.onSecondary,
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

class FileCategories {
  static List<String> audio = [
    'aac', 'midi', 'mp3', 'ogg', 'wav'
  ];

  static List<String> images = [
    'bmp', 'gif', 'jpeg', 'jpg', 'png'
  ];

  static List<String> videos = [
    'avi', 'flv', 'mkv', 'mov', 'mp4', 'mpeg', 'webm', 'wmv'
  ];
}