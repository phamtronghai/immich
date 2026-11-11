import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_ui/immich_ui.dart';

const double _pillThickness = 64;
const double _searchButtonSize = 60;
const double _selectedLabelHeight = 32;
const double _tabInset = 6;
const double _pillRadius = _pillThickness / 2;
const double _tabRadius = _pillRadius - _tabInset;

class FloatingNavigationDestination {
  final int tabIndex;
  final String label;
  final IconData icon;
  final bool enabled;

  const FloatingNavigationDestination({
    required this.tabIndex,
    required this.label,
    required this.icon,
    this.enabled = true,
  });
}

class FloatingNavigationBar extends StatelessWidget {
  final List<FloatingNavigationDestination> destinations;
  final int activeTabIndex;
  final int searchTabIndex;
  final String searchLabel;
  final bool isSearchEnabled;
  final Axis axis;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onSearchSelected;

  const FloatingNavigationBar({
    super.key,
    required this.destinations,
    required this.activeTabIndex,
    required this.searchTabIndex,
    required this.searchLabel,
    required this.onDestinationSelected,
    required this.onSearchSelected,
    this.isSearchEnabled = true,
    this.axis = Axis.horizontal,
  });

  static double verticalOverlayWidth(EdgeInsets safePadding) =>
      math.max(safePadding.right, ImmichSpacing.sm) + _pillThickness + ImmichSpacing.sm * 2;

  @override
  Widget build(BuildContext context) {
    final pill = _NavigationPill(
      destinations: destinations,
      activeTabIndex: activeTabIndex,
      axis: axis,
      onDestinationSelected: onDestinationSelected,
    );
    final searchButton = _SearchButton(
      label: searchLabel,
      isSelected: activeTabIndex == searchTabIndex,
      isEnabled: isSearchEnabled,
      onSelected: onSearchSelected,
    );

    return switch (axis) {
      Axis.horizontal => SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: ImmichSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ImmichSpacing.md),
          child: Row(
            children: [
              Expanded(child: pill),
              const SizedBox(width: ImmichSpacing.sm),
              searchButton,
            ],
          ),
        ),
      ),
      Axis.vertical => SafeArea(
        left: false,
        minimum: const EdgeInsets.only(right: ImmichSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: ImmichSpacing.md, horizontal: ImmichSpacing.sm),
          child: Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    pill,
                    const SizedBox(height: ImmichSpacing.sm),
                    searchButton,
                  ],
                ),
                _buildSelectedLabel(),
              ],
            ),
          ),
        ),
      ),
    };
  }

  Widget _buildSelectedLabel() {
    final destinationPosition = destinations.indexWhere((destination) => destination.tabIndex == activeTabIndex);
    final isSearchSelected = activeTabIndex == searchTabIndex;
    final label = isSearchSelected ? searchLabel : destinations.elementAtOrNull(destinationPosition)?.label;
    final itemCenter = isSearchSelected
        ? destinations.length * _pillThickness + ImmichSpacing.sm + _searchButtonSize / 2
        : destinationPosition * _pillThickness + _pillThickness / 2;

    return AnimatedPositioned(
      duration: ImmichDuration.normal,
      curve: Curves.easeOutCubic,
      top: itemCenter - _selectedLabelHeight / 2,
      right: _pillThickness + ImmichSpacing.sm,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: AnimatedOpacity(
            duration: ImmichDuration.normal,
            opacity: label == null ? 0 : 1,
            child: _SelectedLabel(label: label ?? ''),
          ),
        ),
      ),
    );
  }
}

class _SelectedLabel extends StatelessWidget {
  final String label;

  const _SelectedLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: const BorderRadius.all(Radius.circular(_selectedLabelHeight / 2)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: context.isDarkTheme ? 0.4 : 0.12),
            blurRadius: ImmichElevation.lg,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SizedBox(
        height: _selectedLabelHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ImmichSpacing.md),
          child: Center(
            widthFactor: 1,
            child: AnimatedSwitcher(
              duration: ImmichDuration.normal,
              child: Text(
                label,
                key: ValueKey(label),
                maxLines: 1,
                style: context.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationPill extends StatelessWidget {
  final List<FloatingNavigationDestination> destinations;
  final int activeTabIndex;
  final Axis axis;
  final ValueChanged<int> onDestinationSelected;

  const _NavigationPill({
    required this.destinations,
    required this.activeTabIndex,
    required this.axis,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final pillColor = context.isDarkTheme ? colorScheme.surfaceContainerHigh : colorScheme.surfaceContainerLowest;
    final tabs = [
      for (final destination in destinations)
        _NavigationPillTab(
          destination: destination,
          isActive: destination.tabIndex == activeTabIndex,
          axis: axis,
          onSelected: () => onDestinationSelected(destination.tabIndex),
        ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: pillColor,
        borderRadius: const BorderRadius.all(Radius.circular(_pillRadius)),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: context.isDarkTheme ? 0.4 : 0.08),
            blurRadius: ImmichElevation.xl + ImmichSpacing.sm,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: switch (axis) {
        Axis.horizontal => SizedBox(
          height: _pillThickness,
          child: Row(children: [for (final tab in tabs) Expanded(child: tab)]),
        ),
        Axis.vertical => SizedBox(
          width: _pillThickness,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [for (final tab in tabs) SizedBox(height: _pillThickness, child: tab)],
          ),
        ),
      },
    );
  }
}

class _NavigationPillTab extends StatelessWidget {
  final FloatingNavigationDestination destination;
  final bool isActive;
  final Axis axis;
  final VoidCallback onSelected;

  const _NavigationPillTab({
    required this.destination,
    required this.isActive,
    required this.axis,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final activeTextStyle = context.textTheme.labelLarge?.copyWith(
      color: colorScheme.onPrimaryContainer,
      fontWeight: FontWeight.w700,
    );
    final inactiveTextStyle = context.textTheme.labelLarge?.copyWith(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    );
    final content = switch (axis) {
      Axis.horizontal => Padding(
        padding: const EdgeInsets.symmetric(horizontal: ImmichSpacing.md),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                duration: ImmichDuration.normal,
                curve: Curves.easeOutCubic,
                child: isActive
                    ? Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _ActiveTabBadge(icon: destination.icon),
                      )
                    : const SizedBox.shrink(),
              ),
              AnimatedDefaultTextStyle(
                duration: ImmichDuration.normal,
                curve: Curves.easeOutCubic,
                style: (isActive ? activeTextStyle : inactiveTextStyle) ?? const TextStyle(),
                child: Text(destination.label, maxLines: 1),
              ),
            ],
          ),
        ),
      ),
      Axis.vertical => TweenAnimationBuilder<Color?>(
        duration: ImmichDuration.normal,
        curve: Curves.easeOutCubic,
        tween: ColorTween(end: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant),
        builder: (context, color, _) =>
            Icon(destination.icon, size: ImmichIconSize.md, color: color, semanticLabel: destination.label),
      ),
    };

    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: isActive,
        enabled: destination.enabled,
        child: Padding(
          padding: const EdgeInsets.all(_tabInset),
          child: AnimatedContainer(
            duration: ImmichDuration.normal,
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: isActive ? colorScheme.primaryContainer : Colors.transparent,
              borderRadius: const BorderRadius.all(Radius.circular(_tabRadius)),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: destination.enabled ? onSelected : null,
                customBorder: const StadiumBorder(),
                child: Center(child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveTabBadge extends StatelessWidget {
  final IconData icon;

  const _ActiveTabBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(ImmichRadius.sm)),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Icon(icon, size: ImmichIconSize.xs + 2, color: colorScheme.onPrimary),
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onSelected;

  const _SearchButton({
    required this.label,
    required this.isSelected,
    required this.isEnabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final buttonColor = context.isDarkTheme ? colorScheme.surfaceContainerHigh : colorScheme.surfaceContainerLowest;

    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: isSelected,
        enabled: isEnabled,
        label: label,
        child: Opacity(
          opacity: isEnabled ? 1 : 0.5,
          child: SizedBox.square(
            dimension: _searchButtonSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primaryContainer : buttonColor,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: context.isDarkTheme ? 0.4 : 0.08),
                    blurRadius: ImmichElevation.xl + ImmichSpacing.sm,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: isEnabled ? onSelected : null,
                  customBorder: const CircleBorder(),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: ImmichIconSize.md + 2,
                        color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                      ),
                      Positioned(
                        top: ImmichSpacing.lg,
                        right: ImmichSpacing.lg,
                        child: Icon(
                          Icons.auto_awesome,
                          size: ImmichTextSize.label,
                          color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
