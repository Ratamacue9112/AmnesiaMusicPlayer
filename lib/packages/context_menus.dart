import 'package:flutter/material.dart';

import 'context-menus/context_menu_overlay.dart';

export 'context-menus/menus/context_menu_state_mixin.dart';
export 'context-menus/menus/link_context_menu.dart';
export 'context-menus/menus/text_context_menu.dart';
export 'context-menus/menus/generic_context_menu.dart';

export 'context-menus/widgets/context_menu_button.dart';
export 'context-menus/widgets/context_menu_card.dart';
export 'context-menus/widgets/context_menu_divider.dart';

export 'context-menus/context_menu_overlay.dart';
export 'context-menus/context_menu_region.dart';

extension ContextMenuExtensions on BuildContext {
  ContextMenuOverlayState get contextMenuOverlay => ContextMenuOverlay.of(this);
}
