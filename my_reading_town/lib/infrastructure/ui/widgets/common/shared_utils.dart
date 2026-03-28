import 'package:flutter/material.dart';

bool isLandscape(BuildContext context) =>
    MediaQuery.of(context).orientation == Orientation.landscape;

BoxConstraints sheetConstraints(BuildContext context,
    {double portraitFrac = 0.75}) {
  final size = MediaQuery.of(context).size;
  final landscape = isLandscape(context);
  return BoxConstraints(
    maxHeight: landscape ? size.height * 0.92 : size.height * portraitFrac,
    maxWidth: landscape ? 480 : double.infinity,
  );
}

String formatMinutes(int minutes) {
  if (minutes >= 60) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }
  return '${minutes}m';
}

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h > 0) return '${h}h ${m}m';
  return '${m}m';
}

const ColorFilter grayscaleFilter = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
]);

Widget buildAssetPreview(String type, double size, bool enabled) {
  final image = Image.asset(
    'assets/images/$type.png',
    width: size,
    height: size,
    filterQuality: FilterQuality.medium,
    errorBuilder: (_, __, ___) =>
        Icon(Icons.park, size: size, color: const Color(0xFFB8E6C8)),
  );
  if (enabled) return image;
  return ColorFiltered(
    colorFilter: grayscaleFilter,
    child: Opacity(opacity: 0.7, child: image),
  );
}
