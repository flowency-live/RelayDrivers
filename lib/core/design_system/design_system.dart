/// Relay Drivers Design System
///
/// Premium chauffeur console visual design tokens and components.
///
/// Usage:
/// ```dart
/// import 'package:relay_drivers/core/design_system/design_system.dart';
///
/// // Use tokens
/// color: DesignColors.accent,
/// style: DesignTypography.headlineMedium,
/// borderRadius: DesignRadii.card,
/// boxShadow: DesignShadows.glass,
/// padding: EdgeInsets.all(DesignSpacing.md),
///
/// // Use components
/// PremiumBackground(child: ...),
/// GlassContainer(child: ...),
/// ```
library design_system;

// Tokens
export 'tokens/colors.dart';
export 'tokens/typography.dart';
export 'tokens/spacing.dart';
export 'tokens/radii.dart';
export 'tokens/shadows.dart';

// Foundations
export 'foundations/backgrounds.dart';
export 'foundations/glass.dart';

// Theme
export 'theme.dart';
