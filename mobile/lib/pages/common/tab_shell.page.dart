import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/constants/constants.dart';
import 'package:immich_mobile/domain/models/events.model.dart';
import 'package:immich_mobile/domain/utils/event_stream.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/presentation/pages/search/paginated_search.provider.dart';
import 'package:immich_mobile/presentation/widgets/navigation/floating_navigation_bar.widget.dart';
import 'package:immich_mobile/providers/haptic_feedback.provider.dart';
import 'package:immich_mobile/providers/infrastructure/album.provider.dart';
import 'package:immich_mobile/providers/infrastructure/memory.provider.dart';
import 'package:immich_mobile/providers/infrastructure/readonly_mode.provider.dart';
import 'package:immich_mobile/providers/search/search_input_focus.provider.dart';
import 'package:immich_mobile/providers/tab.provider.dart';
import 'package:immich_mobile/routing/router.dart';

@RoutePage()
class TabShellPage extends ConsumerStatefulWidget {
  const TabShellPage({super.key});

  @override
  ConsumerState<TabShellPage> createState() => _TabShellPageState();
}

class _TabShellPageState extends ConsumerState<TabShellPage> {
  bool _isNavigationBarHidden = false;
  StreamSubscription? _multiSelectSubscription;

  @override
  void initState() {
    super.initState();
    _multiSelectSubscription = EventStream.shared.listen<MultiSelectToggleEvent>(
      (event) => setState(() => _isNavigationBarHidden = event.isEnabled),
    );
  }

  @override
  void dispose() {
    unawaited(_multiSelectSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isScreenLandscape = context.orientation == Orientation.landscape;
    final isReadonlyModeEnabled = ref.watch(readonlyModeProvider);

    final destinations = [
      FloatingNavigationDestination(
        tabIndex: kPhotoTabIndex,
        label: context.t.photos,
        icon: Icons.photo_library_rounded,
      ),
      FloatingNavigationDestination(
        tabIndex: kAlbumTabIndex,
        label: context.t.albums,
        icon: Icons.photo_album_rounded,
        enabled: !isReadonlyModeEnabled,
      ),
      FloatingNavigationDestination(
        tabIndex: kLibraryTabIndex,
        label: context.t.library$,
        icon: Icons.space_dashboard_rounded,
        enabled: !isReadonlyModeEnabled,
      ),
    ];

    Widget navigationBar(TabsRouter tabsRouter, Axis axis) {
      if (_isNavigationBarHidden) {
        return const SizedBox.shrink();
      }

      return _NavigationBar(
        tabsRouter: tabsRouter,
        destinations: destinations,
        searchLabel: context.t.search,
        isSearchEnabled: !isReadonlyModeEnabled,
        axis: axis,
      );
    }

    return AutoTabsRouter(
      routes: const [MainTimelineRoute(), SearchRoute(), AlbumsRoute(), LibraryRoute()],
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (context, child, animation) => FadeTransition(opacity: animation, child: child),
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);
        return PopScope(
          canPop: tabsRouter.activeIndex == 0,
          onPopInvokedWithResult: (didPop, _) => !didPop ? tabsRouter.setActiveIndex(0) : null,
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            extendBody: true,
            body: isScreenLandscape
                ? _LandscapeNavigationOverlay(
                    navigationBar: navigationBar(tabsRouter, Axis.vertical),
                    isHidden: _isNavigationBarHidden,
                    child: child,
                  )
                : child,
            bottomNavigationBar: isScreenLandscape ? null : navigationBar(tabsRouter, Axis.horizontal),
          ),
        );
      },
    );
  }
}

void _onNavigationSelected(TabsRouter router, int index, WidgetRef ref) {
  // On Photos page menu tapped
  if (router.activeIndex == kPhotoTabIndex && index == kPhotoTabIndex) {
    EventStream.shared.emit(const ScrollToTopEvent());
  }

  if (index == kPhotoTabIndex) {
    ref.invalidate(memoryLaneProvider);
  }

  if (router.activeIndex != kSearchTabIndex && index == kSearchTabIndex) {
    ref.read(searchPreFilterProvider.notifier).clear();
  }

  // On Search page tapped
  if (router.activeIndex == kSearchTabIndex && index == kSearchTabIndex) {
    ref.read(searchInputFocusProvider).requestFocus();
  }

  // Album page
  if (index == kAlbumTabIndex) {
    unawaited(ref.read(remoteAlbumProvider.notifier).refresh());
  }

  ref.read(hapticFeedbackProvider.notifier).selectionClick();
  router.setActiveIndex(index);
  ref.read(tabProvider.notifier).state = TabEnum.values[index];
}

class _LandscapeNavigationOverlay extends StatelessWidget {
  const _LandscapeNavigationOverlay({required this.navigationBar, required this.isHidden, required this.child});

  final Widget navigationBar;
  final bool isHidden;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final overlayWidth = isHidden
        ? mediaQuery.padding.right
        : FloatingNavigationBar.verticalOverlayWidth(mediaQuery.padding);

    return Stack(
      children: [
        MediaQuery(
          data: mediaQuery.copyWith(padding: mediaQuery.padding.copyWith(right: overlayWidth)),
          child: child,
        ),
        Positioned(top: 0, right: 0, bottom: 0, child: navigationBar),
      ],
    );
  }
}

class _NavigationBar extends ConsumerWidget {
  const _NavigationBar({
    required this.tabsRouter,
    required this.destinations,
    required this.searchLabel,
    required this.isSearchEnabled,
    required this.axis,
  });

  final List<FloatingNavigationDestination> destinations;
  final String searchLabel;
  final bool isSearchEnabled;
  final Axis axis;
  final TabsRouter tabsRouter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingNavigationBar(
      destinations: destinations,
      activeTabIndex: tabsRouter.activeIndex,
      searchTabIndex: kSearchTabIndex,
      searchLabel: searchLabel,
      isSearchEnabled: isSearchEnabled,
      axis: axis,
      onDestinationSelected: (index) => _onNavigationSelected(tabsRouter, index, ref),
      onSearchSelected: () => _onNavigationSelected(tabsRouter, kSearchTabIndex, ref),
    );
  }
}
