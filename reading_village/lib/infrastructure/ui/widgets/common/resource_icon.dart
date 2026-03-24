import 'package:flutter/material.dart';

class ResourceIcon extends StatelessWidget {
  final String assetName;
  final double size;

  const ResourceIcon({
    super.key,
    required this.assetName,
    this.size = 24,
  });

  const ResourceIcon.coin({super.key, this.size = 24}) : assetName = 'coin';
  const ResourceIcon.gem({super.key, this.size = 24}) : assetName = 'gem';
  const ResourceIcon.wood({super.key, this.size = 24}) : assetName = 'wood';
  const ResourceIcon.metal({super.key, this.size = 24}) : assetName = 'metal';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/$assetName.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
    );
  }
}
