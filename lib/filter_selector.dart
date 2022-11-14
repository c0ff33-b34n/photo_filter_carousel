import 'package:flutter/material.dart';

import 'filter_item.dart';

class FilterSelector extends StatefulWidget {
  const FilterSelector(
      {super.key,
      required this.filters,
      required this.onFilterChanged,
      this.padding = const EdgeInsets.symmetric(vertical: 24.0)});

  final List<Color> filters;
  final void Function(Color selectedColor) onFilterChanged;
  final EdgeInsets padding;
  @override
  State<FilterSelector> createState() => _FilterSelectorState();
}

class _FilterSelectorState extends State<FilterSelector> {
  static const _filtersPerScreen = 5;
  static const _viewportFractionPerItem = 1.0 / _filtersPerScreen;

  late final PageController _controller;
  Color itemColor(int index) => widget.filters[index % widget.filters.length];

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      viewportFraction: _viewportFractionPerItem,
    );
    _controller.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    final page = (_controller.page ?? 0).round();
    widget.onFilterChanged(widget.filters[page]);
  }

  void _onFilterTapped(int index) {
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 450),
      curve: Curves.ease,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemSize = constraints.maxWidth * _viewportFractionPerItem;

        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            _buildShadowGradient(itemSize),
            _buildCarousel(itemSize),
            _buildSelectionRing(itemSize),
          ],
        );
      },
    );
  }

  Widget _buildShadowGradient(double itemSize) {
    return SizedBox(
      height: itemSize * 2 + widget.padding.vertical,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black,
            ],
          ),
        ),
        child: SizedBox.expand(),
      ),
    );
  }

  Widget _buildCarousel(double itemSize) {
    return Container(
      height: itemSize,
      margin: widget.padding,
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.filters.length,
        itemBuilder: (context, index) {
          return Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                if (!_controller.hasClients ||
                    !_controller.position.hasContentDimensions) {
                  // The PageViewController isn’t connected to the
                  // PageView widget yet. Return an empty box.
                  return const SizedBox();
                }

                // The integer index of the current page,
                // 0, 1, 2, 3, and so on
                final selectedIndex = _controller.page!.roundToDouble();

                // The fractional amount that the current filter
                // is dragged to the left or right, for example, 0.25 when
                // the current filter is dragged 25% to the left.
                final pageScrollAmount = _controller.page! - selectedIndex;

                // The page-distance of a filter just before it
                // moves off-screen.
                const maxScrollDistance = _filtersPerScreen / 2;

                // The page-distance of this filter item from the
                // currently selected filter item.
                final pageDistanceFromSelected =
                    (selectedIndex - index + pageScrollAmount).abs();

                // The distance of this filter item from the
                // center of the carousel as a percentage, that is, where the selector
                // ring sits.
                final percentFromCenter =
                    1.0 - pageDistanceFromSelected / maxScrollDistance;

                final itemScale = 0.5 + (percentFromCenter * 0.5);
                final opacity = 0.25 + (percentFromCenter * 0.75);

                return Transform.scale(
                  scale: itemScale,
                  child: Opacity(
                    opacity: opacity,
                    child: FilterItem(
                      color: itemColor(index),
                      onFilterSelected: () => _onFilterTapped(index),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectionRing(double itemSize) {
    return IgnorePointer(
      child: Padding(
        padding: widget.padding,
        child: SizedBox(
          width: itemSize,
          height: itemSize,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.fromBorderSide(
                BorderSide(width: 6.0, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
