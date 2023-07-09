import 'package:flutter/material.dart';

class ArtistsPage extends StatelessWidget {
  const ArtistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium!.copyWith(
      color: theme.colorScheme.onPrimary
    );

    return Scaffold(
      body: Column(
        children: [
          Text('Artists Page', style: textStyle)
        ],
      )
    );
  }
  
}