import 'package:flutter/material.dart';
import 'package:refills/features/core/models/refill.dart';
import 'package:refills/features/core/data/refill_database.dart';
import 'package:refills/features/core/views/add_refill.dart';
import 'package:refills/features/core/widgets/refill_card.dart';
import 'package:refills/nav.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:refills/features/core/widgets/refills_graph.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          'Refills',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        elevation: 2,
        onPressed: _onAddRefill,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: refills.isEmpty
          ? SafeArea(child: _emptyState())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.zero,
                  itemCount: refills.isNotEmpty
                      ? refills.length + 2
                      : 0, // +1 for graph, +1 for loading
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      if (refills.length < 2) {
                        return const SizedBox.shrink();
                      }
                      return _graphSection();
                    }
                    if (index == refills.length + 1 && _hasMore) {
                      return _loadingIndicator();
                    }
                    if (index > 0 && index <= refills.length) {
                      final refill = refills[index - 1];
                      final nextRefill = (index < refills.length)
                          ? refills[index]
                          : null;
                      return _refillListItem(
                        refill: refill,
                        nextRefill: nextRefill,
                        onDelete: () => _onDeleteRefill(refill),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
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
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          color: Colors.transparent,
          child: const Icon(
            Icons.delete_outline,
            color: Colors.black38,
            size: 28,
          ),
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
