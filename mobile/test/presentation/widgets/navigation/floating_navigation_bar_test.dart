import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/constants/colors.dart';
import 'package:immich_mobile/presentation/widgets/navigation/floating_navigation_bar.widget.dart';

void main() {
  const destinations = [
    FloatingNavigationDestination(tabIndex: 0, label: 'Photos', icon: Icons.photo_library_rounded),
    FloatingNavigationDestination(tabIndex: 2, label: 'Albums', icon: Icons.photo_album_rounded),
    FloatingNavigationDestination(tabIndex: 3, label: 'Library', icon: Icons.space_dashboard_rounded, enabled: false),
  ];

  Future<void> pumpBar(
    WidgetTester tester, {
    int activeTabIndex = 0,
    bool isSearchEnabled = true,
    Axis axis = Axis.horizontal,
    List<FloatingNavigationDestination> items = destinations,
    ValueChanged<int>? onDestinationSelected,
    VoidCallback? onSearchSelected,
  }) {
    final bar = FloatingNavigationBar(
      destinations: items,
      activeTabIndex: activeTabIndex,
      searchTabIndex: 1,
      searchLabel: 'Search',
      isSearchEnabled: isSearchEnabled,
      axis: axis,
      onDestinationSelected: onDestinationSelected ?? (_) {},
      onSearchSelected: onSearchSelected ?? () {},
    );

    return tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: immichBrandColorLight)),
        home: Scaffold(
          body: axis == Axis.vertical ? Row(children: [const Spacer(), bar]) : null,
          bottomNavigationBar: axis == Axis.horizontal ? bar : null,
        ),
      ),
    );
  }

  testWidgets('renders every destination label and the search button', (tester) async {
    await pumpBar(tester);

    expect(find.text('Photos'), findsOneWidget);
    expect(find.text('Albums'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
  });

  testWidgets('shows the badge icon only for the active destination', (tester) async {
    await pumpBar(tester);

    expect(find.byIcon(Icons.photo_library_rounded), findsOneWidget);
    expect(find.byIcon(Icons.photo_album_rounded), findsNothing);
    expect(find.byIcon(Icons.space_dashboard_rounded), findsNothing);
  });

  testWidgets('moves the badge to the newly active destination', (tester) async {
    await pumpBar(tester, activeTabIndex: 2);

    expect(find.byIcon(Icons.photo_album_rounded), findsOneWidget);
    expect(find.byIcon(Icons.photo_library_rounded), findsNothing);
  });

  testWidgets('hides every badge while the search tab is active', (tester) async {
    await pumpBar(tester, activeTabIndex: 1);

    expect(find.byIcon(Icons.photo_library_rounded), findsNothing);
    expect(find.byIcon(Icons.photo_album_rounded), findsNothing);
    expect(find.byIcon(Icons.space_dashboard_rounded), findsNothing);

    final search = tester.getSemantics(find.bySemanticsLabel('Search'));
    expect(search.flagsCollection.isSelected, Tristate.isTrue);
  });

  testWidgets('reports the tab index of the tapped destination', (tester) async {
    int? selected;
    await pumpBar(tester, onDestinationSelected: (index) => selected = index);

    await tester.tap(find.text('Albums'));
    await tester.pumpAndSettle();

    expect(selected, 2);
  });

  testWidgets('opens search from the circular button', (tester) async {
    var opened = false;
    await pumpBar(tester, onSearchSelected: () => opened = true);

    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
  });

  testWidgets('ignores taps on disabled destinations and a disabled search button', (tester) async {
    var destinationTapped = false;
    var searchTapped = false;
    await pumpBar(
      tester,
      isSearchEnabled: false,
      onDestinationSelected: (_) => destinationTapped = true,
      onSearchSelected: () => searchTapped = true,
    );

    await tester.tap(find.text('Library'));
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();

    expect(destinationTapped, isFalse);
    expect(searchTapped, isFalse);
  });

  group('vertical', () {
    Future<void> pumpVertical(
      WidgetTester tester, {
      int activeTabIndex = 0,
      ValueChanged<int>? onDestinationSelected,
    }) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpBar(
        tester,
        axis: Axis.vertical,
        activeTabIndex: activeTabIndex,
        onDestinationSelected: onDestinationSelected,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('stacks every destination icon above the search button on the right', (tester) async {
      int? selected;
      await pumpVertical(tester, onDestinationSelected: (index) => selected = index);

      final photos = tester.getCenter(find.byIcon(Icons.photo_library_rounded));
      final albums = tester.getCenter(find.byIcon(Icons.photo_album_rounded));
      final library = tester.getCenter(find.byIcon(Icons.space_dashboard_rounded));
      final search = tester.getCenter(find.byIcon(Icons.search_rounded));

      expect(photos.dy, lessThan(albums.dy));
      expect(albums.dy, lessThan(library.dy));
      expect(library.dy, lessThan(search.dy));
      expect(photos.dx, greaterThan(844 / 2));
      expect(tester.takeException(), isNull);

      await tester.tap(find.byIcon(Icons.photo_album_rounded));
      expect(selected, 2);
    });

    testWidgets('shows only the selected label, beside and level with its icon', (tester) async {
      await pumpVertical(tester, activeTabIndex: 2);

      expect(find.text('Albums'), findsOneWidget);
      expect(find.text('Photos'), findsNothing);
      expect(find.text('Library'), findsNothing);

      final label = tester.getRect(find.text('Albums'));
      final icon = tester.getRect(find.byIcon(Icons.photo_album_rounded));
      expect(label.right, lessThan(icon.left));
      expect(label.center.dy, moreOrLessEquals(icon.center.dy, epsilon: 1));
    });

    testWidgets('labels the search button when search is selected', (tester) async {
      await pumpVertical(tester, activeTabIndex: 1);

      final label = tester.getRect(find.text('Search'));
      final icon = tester.getRect(find.byIcon(Icons.search_rounded));
      expect(label.right, lessThan(icon.left));
      expect(label.center.dy, moreOrLessEquals(icon.center.dy, epsilon: 1));
    });

    testWidgets('keeps destinations announced by name', (tester) async {
      await pumpVertical(tester);

      expect(find.bySemanticsLabel('Albums'), findsOneWidget);
      expect(find.bySemanticsLabel('Library'), findsOneWidget);
    });
  });

  testWidgets('marks the active destination as selected for accessibility', (tester) async {
    await pumpBar(tester);

    final photos = tester.getSemantics(find.bySemanticsLabel('Photos'));
    final albums = tester.getSemantics(find.bySemanticsLabel('Albums'));

    expect(photos.flagsCollection.isSelected, Tristate.isTrue);
    expect(albums.flagsCollection.isSelected, Tristate.isFalse);
  });
}
