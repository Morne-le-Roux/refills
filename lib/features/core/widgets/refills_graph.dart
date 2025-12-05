import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:refills/features/core/user_preferences.dart';

class RefillsGraph extends StatefulWidget {
  final List<FlSpot> spots;
  final bool showKmPerLiter;
  final ValueChanged<bool> onSwitch;
  // Optional mask of which bars should be shown (true = show).
  // Use when only consecutive 100% refills should be visualized.
  final List<bool>? validBars;

  const RefillsGraph({
    super.key,
    required this.spots,
    required this.showKmPerLiter,
    required this.onSwitch,
    this.validBars,
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
    final validBars = widget.validBars;
    final showKmPerLiter = widget.showKmPerLiter;
    final onSwitch = widget.onSwitch;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boxColor = isDark ? Colors.black : Colors.white;
    final borderColor = isDark ? Colors.white : Colors.grey.shade300;
    final textColor = isDark ? Colors.white : Colors.black;
    final fadedTextColor = isDark
        ? Colors.white.withOpacity(0.7)
        : Colors.black38;
    final gridLineColor = isDark
        ? Colors.white.withOpacity(0.18)
        : Colors.black.withOpacity(0.08);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.12 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(width: 1.2, color: borderColor),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      getDrawingHorizontalLine: (value) =>
                          FlLine(color: gridLineColor, strokeWidth: 1),
                      getDrawingVerticalLine: (value) =>
                          FlLine(color: gridLineColor, strokeWidth: 1),
                    ),
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
                    barGroups: [
                      for (int i = 0; i < spots.length; i++)
                        if (validBars == null ||
                            (i < validBars.length && validBars[i]))
                          BarChartGroupData(
                            x: spots[i].x.toInt(),
                            barRods: [
                              BarChartRodData(
                                toY: spots[i].y,
                                color: textColor,
                                width: 8,
                                borderRadius: BorderRadius.circular(4),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: 0,
                                  color: textColor.withOpacity(0.08),
                                ),
                              ),
                            ],
                          ),
                    ],
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
                            TextStyle(color: textColor, fontSize: 12),
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
                      color: !showKmPerLiter ? textColor : fadedTextColor,
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
                          color: boxColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 1),
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
                                    color: textColor,
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
                      color: showKmPerLiter ? textColor : fadedTextColor,
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
