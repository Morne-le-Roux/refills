import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:refills/features/core/user_preferences.dart';

class RefillsGraph extends StatefulWidget {
  final List<FlSpot> spots;
  final bool showKmPerLiter;
  final ValueChanged<bool> onSwitch;

  const RefillsGraph({
    super.key,
    required this.spots,
    required this.showKmPerLiter,
    required this.onSwitch,
  });

  @override
  State<RefillsGraph> createState() => _RefillsGraphState();
}

class _RefillsGraphState extends State<RefillsGraph> {
  String volumeUnit = 'L';
  String distanceUnit = 'km';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final vUnit = await UserPreferences.getVolumeUnit();
    final dUnit = await UserPreferences.getDistanceUnit();
    setState(() {
      volumeUnit = vUnit;
      distanceUnit = dUnit;
    });
  }

  @override
  Widget build(BuildContext context) {
    final spots = widget.spots;
    final showKmPerLiter = widget.showKmPerLiter;
    final onSwitch = widget.onSwitch;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(width: 0.15, color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    gridData: FlGridData(show: true, drawHorizontalLine: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 38,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: spots.map((spot) {
                      return BarChartGroupData(
                        x: spot.x.toInt(),
                        barRods: [
                          BarChartRodData(
                            toY: spot.y,
                            color: Colors.black,
                            width: 8,
                            borderRadius: BorderRadius.circular(4),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: 0,
                              color: Colors.black.withOpacity(0.08),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.black54,
                        tooltipMargin: 8,
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          String unitLabel = showKmPerLiter
                              ? "$distanceUnit/$volumeUnit"
                              : "$volumeUnit/100$distanceUnit";
                          return BarTooltipItem(
                            "${rod.toY.toStringAsFixed(1)} $unitLabel",
                            const TextStyle(color: Colors.white, fontSize: 12),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    '$volumeUnit/100$distanceUnit',
                    style: TextStyle(
                      color: !showKmPerLiter ? Colors.black : Colors.black38,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: GestureDetector(
                      onTap: () => onSwitch(!showKmPerLiter),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.bounceOut,
                        width: 38,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12, width: 1),
                        ),
                        child: Stack(
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.bounceOut,
                              left: showKmPerLiter ? 18 : 2,
                              top: 2,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Text(
                    '$distanceUnit/$volumeUnit',
                    style: TextStyle(
                      color: showKmPerLiter ? Colors.black : Colors.black38,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
