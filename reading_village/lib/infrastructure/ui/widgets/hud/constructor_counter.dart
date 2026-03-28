import 'package:flutter/material.dart';
import 'package:reading_village/adapters/providers/village_provider.dart';

class ConstructorCounter extends StatelessWidget {
  final VillageProvider village;
  final bool landscape;

  const ConstructorCounter({
    super.key,
    required this.village,
    required this.landscape,
  });

  @override
  Widget build(BuildContext context) {
    final busy = village.busyConstructors;
    final max = village.maxConstructors;
    final iconSize = 36.0;

    return Container(
      width: landscape ? 110 : 120,
      padding: EdgeInsets.symmetric(
          horizontal: landscape ? 8 : 10, vertical: landscape ? 7 : 8),
      decoration: BoxDecoration(
        color: const Color(0xAA000000),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/cat_constructor.png',
            width: iconSize,
            height: iconSize,
            cacheWidth: (iconSize * 3).round(),
            cacheHeight: (iconSize * 3).round(),
            filterQuality: FilterQuality.medium,
          ),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              '$busy / $max',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: busy >= max ? Colors.red.shade300 : Colors.white,
                shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
