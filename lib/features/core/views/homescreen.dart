import 'package:flutter/material.dart';
import 'package:refills/features/core/models/refill.dart';
import 'package:refills/features/core/data/refill_database.dart';
import 'package:refills/features/core/views/add_refill.dart';
import 'package:refills/features/core/setup_screen.dart';
import 'package:refills/features/core/widgets/refill_card.dart';
import 'package:refills/nav.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:refills/features/core/widgets/refills_graph.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:refills/features/core/widgets/custom_app_bar.dart';
import 'package:refills/features/core/views/_custom_app_bar_delegate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Refill> refills = [];
  bool showKmPerLiter = true;
  static const int pageSize = 30;
  static const double scrollThreshold = 200;
  int _currentOffset = 0;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  /// Loads the initial page of refills and sorts them.
  Future<void> _loadInitialRefills() async {
    _currentOffset = 0;
    _hasMore = true;
    final page = await RefillDatabase.instance.getRefillsPage(
      limit: pageSize,
      offset: _currentOffset,
    );
    setState(() {
      refills = List<Refill>.from(page)
        ..sort((a, b) => b.odometer.compareTo(a.odometer));
      _currentOffset = page.length;
      _hasMore = page.length == pageSize;
    });
  }

  /// Loads more refills for infinite scroll and keeps the list sorted.
  Future<void> _loadMoreRefills() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
    });
    final page = await RefillDatabase.instance.getRefillsPage(
      limit: pageSize,
      offset: _currentOffset,
    );
    setState(() {
      refills.addAll(page);
      refills.sort((a, b) => b.odometer.compareTo(a.odometer));
      _currentOffset += page.length;
      _hasMore = page.length == pageSize;
      _isLoadingMore = false;
    });
  }

  /// Handles scroll event for infinite loading.
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - scrollThreshold) {
      _loadMoreRefills();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Returns chart data points for the graph.
  List<FlSpot> getChartSpots() {
    final latestRefills = refills.length > pageSize
        ? refills.sublist(0, pageSize)
        : refills;
    List<FlSpot> spots = [];
    for (int i = latestRefills.length - 2; i >= 0; i--) {
      spots.add(
        FlSpot(
          (latestRefills.length - 2 - i).toDouble(),
          _calculateChartValue(latestRefills[i], latestRefills[i + 1]),
        ),
      );
    }
    return spots;
  }

  /// Helper for chart value calculation.
  double _calculateChartValue(Refill curr, Refill next) {
    final distance = curr.odometer - next.odometer;
    final liters = curr.amount;
    double kmPerLiter = (liters > 0) ? distance / liters : 0;
    if (showKmPerLiter) {
      return kmPerLiter;
    } else {
      return (kmPerLiter > 0) ? 100 / kmPerLiter : 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSwitchSetting();
    _seedDebugData();
    _loadInitialRefills();
    _scrollController.addListener(_onScroll);
  }

  /// Loads the saved switch setting for km/l or l/100km.
  Future<void> _loadSwitchSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      showKmPerLiter = prefs.getBool('showKmPerLiter') ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : colorScheme.primary,
        elevation: 2,
        onPressed: _onAddRefill,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Icon(
          Icons.add,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : colorScheme.onPrimary,
        ),
      ),
      body: refills.isEmpty
          ? SafeArea(child: _emptyState())
          : SafeArea(
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverPersistentHeader(
                    floating: true,
                    delegate: CustomAppBarDelegate(
                      minExtent: kToolbarHeight,
                      maxExtent: kToolbarHeight,
                      child: CustomAppBar(
                        title: Text(
                          'Refills',
                          style: textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 22,
                            letterSpacing: -0.5,
                          ),
                        ),
                        actions: [
                          IconButton(
                            icon: Icon(
                              Icons.settings,
                              color: colorScheme.onSurface,
                            ),
                            tooltip: 'Setup',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SetupScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                        centerTitle: true,
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.black
                            : Colors.white,
                        elevation: 2.0,
                        iconTheme: IconThemeData(color: colorScheme.onSurface),
                      ),
                    ),
                  ),
                  if (refills.length >= 2)
                    SliverToBoxAdapter(child: _graphSection()),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index >= refills.length) {
                        if (_hasMore) {
                          return _loadingIndicator();
                        } else {
                          return null;
                        }
                      }
                      final refill = refills[index];
                      final nextRefill = (index + 1 < refills.length)
                          ? refills[index + 1]
                          : null;
                      return _refillListItem(
                        refill: refill,
                        nextRefill: nextRefill,
                        onDelete: () => _onDeleteRefill(refill),
                      );
                    }, childCount: refills.length + (_hasMore ? 1 : 0)),
                  ),
                ],
              ),
            ),
    );
  }

  /// Handles adding a new refill.
  void _onAddRefill() {
    Nav.push(
      context,
      AddRefill(
        onAdd: (refill) async {
          await RefillDatabase.instance.insertRefill(refill);
          setState(() {
            refills.add(refill);
            refills.sort((a, b) => b.odometer.compareTo(a.odometer));
          });
          // Prompt for review after more than 3 entries, only if not already prompted 'never'
          if (refills.length > 3) {
            final prefs = await SharedPreferences.getInstance();
            final hasPromptedReview =
                prefs.getBool('hasPromptedReview') ?? false;
            final neverPromptReview =
                prefs.getBool('neverPromptReview') ?? false;
            if (!hasPromptedReview && !neverPromptReview) {
              final result = await showDialog<String>(
                context: context,
                barrierDismissible: true,
                builder: (context) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 28,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.07),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(18),
                          child: Icon(
                            Icons.star_rounded,
                            color: Theme.of(context).colorScheme.secondary,
                            size: 38,
                          ),
                        ),
                        SizedBox(height: 18),
                        Text(
                          'Enjoying Refills?',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                                letterSpacing: -0.5,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "If you're finding Refills helpful, would you mind rating us on the app store? Your feedback helps us improve!",
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontSize: 15,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.87),
                              ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () =>
                                    Navigator.of(context).pop('rate'),
                                child: Text(
                                  'Rate Now',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  side: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.12),
                                    width: 1.2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                onPressed: () =>
                                    Navigator.of(context).pop('later'),
                                child: Text(
                                  'Maybe Later',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop('never'),
                          child: Text(
                            'Never',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.38),
                                  fontSize: 14,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
              if (result == 'rate') {
                final inAppReview = InAppReview.instance;
                if (await inAppReview.isAvailable()) {
                  inAppReview.requestReview();
                  await prefs.setBool('hasPromptedReview', true);
                }
              } else if (result == 'never') {
                await prefs.setBool('neverPromptReview', true);
              }
              // If 'later', do nothing, will prompt again next time
            }
          }
        },
      ),
    );
  }

  /// Handles deleting a refill with confirmation dialog.
  Future<void> _onDeleteRefill(Refill refill) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Refill'),
        content: const Text('Are you sure you want to delete this refill?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await RefillDatabase.instance.deleteRefill(refill.id);
      setState(() {
        refills.remove(refill);
        refills.sort((a, b) => b.odometer.compareTo(a.odometer));
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Refill deleted')));
    }
  }

  // --- Extracted Widgets ---

  /// Graph section widget
  static Widget _graphSection() {
    // This context is only available in build, so pass required data via InheritedWidget or refactor as needed
    // For now, this is a placeholder for extraction
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Builder(
        builder: (context) {
          final state = context.findAncestorStateOfType<_HomeScreenState>();
          if (state == null) return const SizedBox.shrink();
          return RefillsGraph(
            spots: state.getChartSpots(),
            showKmPerLiter: state.showKmPerLiter,
            onSwitch: (value) async {
              state.setState(() {
                state.showKmPerLiter = value;
              });
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('showKmPerLiter', value);
            },
          );
        },
      ),
    );
  }

  /// Loading indicator widget
  static Widget _loadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  /// Empty state widget
  static Widget _emptyState() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_gas_station, size: 40),
          SizedBox(height: 20),
          Text(
            "No readings yet!\nTap the + button in the bottom right to get started.",
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Refill list item widget
  static Widget _refillListItem({
    required Refill refill,
    required Refill? nextRefill,
    required VoidCallback onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Dismissible(
        key: Key(refill.id),
        direction: DismissDirection.endToStart,
        background: Builder(
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              color: Colors.transparent,
              child: Icon(
                Icons.delete_outline,
                color: isDark ? Colors.white : Colors.black38,
                size: 28,
              ),
            );
          },
        ),
        confirmDismiss: (direction) async {
          onDelete();
          // Dismissible expects a bool: true to dismiss, false to keep
          // We show the dialog and handle deletion in _onDeleteRefill, which only deletes if confirmed
          // So always return false here to prevent auto-dismiss
          return false;
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: SizedBox(
            width: double.infinity,
            child: RefillCard(refill: refill, previousRefill: nextRefill),
          ),
        ),
      ),
    );
  }

  /// Seeds debug data (only in debug mode).
  Future<void> _seedDebugData() async {
    bool isDebug = false;
    assert(() {
      isDebug = true;
      return true;
    }());
    if (!isDebug) return;

    final allRefills = await RefillDatabase.instance.getRefillsPage(
      limit: 10000,
      offset: 0,
    );
    for (final refill in allRefills) {
      await RefillDatabase.instance.deleteRefill(refill.id);
    }

    final now = DateTime.now();
    final random = DateTime.now().microsecond;
    List<Refill> debugRefills = List.generate(20, (i) {
      final randOffset = (i * random) % 1000;
      final odometerIncrement = 120 + (randOffset % 30);
      final amount = 6.0 + (randOffset % 4);
      return Refill(
        id: 'debug_${i}_$randOffset',
        odometer: 10000 + i * odometerIncrement,
        amount: amount,
        cost: 18.0 + (randOffset % 7) + (i % 5),
        fillPercentage: 0.3 + ((randOffset % 7) * 0.09) + ((i % 5) * 0.05),
        date: now.subtract(Duration(days: 30 - i + (randOffset % 5))),
      );
    });
    for (final refill in debugRefills) {
      await RefillDatabase.instance.insertRefill(refill);
    }
    await _loadInitialRefills();
  }
}
