import 'package:flutter/material.dart';
import 'package:refills/features/core/models/refill.dart';
import 'package:refills/features/core/user_preferences.dart';

class RefillCard extends StatefulWidget {
  const RefillCard({super.key, required this.refill, this.previousRefill});

  final Refill refill;
  final Refill? previousRefill;

  @override
  State<RefillCard> createState() => _RefillCardState();
}

class _RefillCardState extends State<RefillCard> {
  String volumeUnit = 'L';
  String distanceUnit = 'km';
  String currencySymbol = 'R';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final vUnit = await UserPreferences.getVolumeUnit();
    final dUnit = await UserPreferences.getDistanceUnit();
    final cSymbol = await UserPreferences.getCurrencySymbol();
    setState(() {
      volumeUnit = vUnit;
      distanceUnit = dUnit;
      currencySymbol = cSymbol;
    });
  }

  @override
  Widget build(BuildContext context) {
    final refill = widget.refill;
    final previousRefill = widget.previousRefill;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boxColor = isDark ? Colors.black : Colors.white;
    final borderColor = isDark ? Colors.white : Colors.grey.shade300;
    final mainTextColor = isDark ? Colors.white : Colors.black;
    final fadedTextColor = isDark ? Colors.white70 : Colors.black54;
    final fadedTextColor2 = isDark ? Colors.white38 : Colors.black38;
    final strongTextColor = isDark ? Colors.white : Colors.black87;
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$currencySymbol${refill.cost.toStringAsFixed(2)}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: mainTextColor,
                ),
              ),
              Text(
                "${refill.amount.toStringAsFixed(2)} $volumeUnit",
                style: TextStyle(color: fadedTextColor, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${refill.fillPercentage.toStringAsFixed(0)}% full",
                style: TextStyle(color: fadedTextColor, fontSize: 14),
              ),
              Text(
                "${refill.odometer} $distanceUnit",
                style: TextStyle(color: fadedTextColor, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${refill.date.day.toString().padLeft(2, '0')}/${refill.date.month.toString().padLeft(2, '0')}/${refill.date.year}",
                style: TextStyle(color: fadedTextColor2, fontSize: 13),
              ),
              Text(
                "$currencySymbol${getPricePerLiter(refill).toStringAsFixed(2)}/$volumeUnit",
                style: TextStyle(color: fadedTextColor2, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$volumeUnit/100$distanceUnit: ${previousRefill != null ? getLiterPerKilometer(refill, previousRefill).toStringAsFixed(2) : 'N/A'}",
                style: TextStyle(color: strongTextColor, fontSize: 13),
              ),
              Text(
                "$distanceUnit/$volumeUnit: ${previousRefill != null ? getKilometerPerLiter(refill, previousRefill).toStringAsFixed(2) : 'N/A'}",
                style: TextStyle(color: strongTextColor, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

double getLiterPerKilometer(Refill current, Refill? previous) {
  if (previous == null) return 0.0;
  double kmPerLiter = (current.amount > 0)
      ? (current.odometer - previous.odometer) / current.amount
      : 0;
  return (kmPerLiter > 0) ? 100 / kmPerLiter : 0;
}

double getKilometerPerLiter(Refill current, Refill? previous) {
  if (previous == null) return 0.0;
  return (current.odometer - previous.odometer) / current.amount;
}

double getPricePerLiter(Refill refill) {
  return refill.cost / refill.amount;
}
