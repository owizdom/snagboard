import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// The 1 WHAT / 2 WHERE / 3 DETAILS / 4 REVIEW rail at the top of filing.
class StepRail extends StatelessWidget {
  const StepRail({super.key, required this.step});
  final int step;

  static const _names = ['WHAT', 'WHERE', 'DETAILS', 'REVIEW'];

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Step ${step + 1} of ${_names.length}: ${_names[step]}',
        excludeSemantics: true,
        child: Row(
          children: [
            for (var n = 0; n < _names.length; n++)
              Expanded(
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: n == step ? Snag.ink : (n < step ? Snag.paperDeep : null),
                    border: Border(
                      top: Snag.border,
                      bottom: Snag.border,
                      left: Snag.border,
                      right: n == _names.length - 1 ? Snag.border : BorderSide.none,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('${n + 1} ${_names[n]}',
                        style: Snag.label(size: 11, color: n == step ? Snag.paper : Snag.ink)),
                  ),
                ),
              ),
          ],
        ),
      );
}
