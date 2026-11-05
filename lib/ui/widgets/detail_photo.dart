import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../keys.dart';

/// The snag's photo. Tap to open it full screen and zoom.
class DetailPhoto extends StatelessWidget {
  const DetailPhoto({super.key, required this.url});
  final String url;

  Widget _image(BoxFit fit) => Image.network(
        url,
        fit: fit,
        errorBuilder: (_, _, _) => const SizedBox(
          height: 120,
          child: Center(child: Text('The photo could not be loaded.')),
        ),
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
      );

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Photo of the problem. Tap to enlarge.',
        child: GestureDetector(
          key: K.detailPhoto,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              fullscreenDialog: true,
              builder: (_) => Scaffold(
                backgroundColor: Snag.ink,
                appBar: AppBar(backgroundColor: Snag.ink, foregroundColor: Snag.paper),
                body: Center(child: InteractiveViewer(child: _image(BoxFit.contain))),
              ),
            ),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 280),
            width: double.infinity,
            decoration: BoxDecoration(border: Border.all(color: Snag.ink, width: Snag.outline)),
            child: _image(BoxFit.cover),
          ),
        ),
      );
}
