export 'package:flutter/material.dart';
export 'package:flutter/widgets.dart';

export 'pages/home.dart';

import 'package:flutter/material.dart';

class AppStyles {
  static TextStyle mediumText = const TextStyle();

  static void initStyles(ThemeData theme) {
    mediumText = theme.textTheme.bodyMedium!.copyWith(
      color: theme.colorScheme.onPrimary
    );
  }
}
