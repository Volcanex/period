import 'package:flutter/material.dart';

import '../../../data/models.dart';
import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';
import 'sheet_scaffold.dart';

/// Bottom sheet for picking severity and adding an optional note for a symptom.
class SymptomSheet extends StatefulWidget {
  final String symptom;
  final Severity? current;
  final String currentNote;
  final void Function(Severity? severity, String note) onSet;

  const SymptomSheet({
    super.key,
    required this.symptom,
    required this.current,
    this.currentNote = '',
    required this.onSet,
  });

  @override
  State<SymptomSheet> createState() => _SymptomSheetState();
}

class _SymptomSheetState extends State<SymptomSheet> {
  Severity? sev;
  String note = '';
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    sev = widget.current;
    note = widget.currentNote;
    _noteCtrl = TextEditingController(text: widget.currentNote);
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      title: widget.symptom,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('SEVERITY', style: Type.eyebrow()),
          const SizedBox(height: 10),
          _SeverityRow(value: sev, onChanged: (v) => setState(() => sev = v)),
          const SizedBox(height: 14),
          Text('NOTE · OPTIONAL', style: Type.eyebrow()),
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(minHeight: 48),
            decoration: BoxDecoration(
              color: Tokens.base,
              borderRadius: BorderRadius.circular(Tokens.r2),
              border: Border.all(color: Tokens.borderSoft, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: TextField(
              controller: _noteCtrl,
              minLines: 2,
              maxLines: null,
              onChanged: (v) => note = v,
              cursorColor: Tokens.ink,
              style: Type.body(size: 14, height: 1.55),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                hintText: 'add context…',
                hintStyle: Type.body(
                  size: 14,
                  color: Tokens.graphite2,
                  height: 1.55,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SheetPrimaryButton(
            label: 'save',
            onPressed: () {
              widget.onSet(sev, note);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

class _SeverityRow extends StatelessWidget {
  final Severity? value;
  final ValueChanged<Severity?> onChanged;
  const _SeverityRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cells = <_SevCell>[
      _SevCell(null, 'none', const []),
      _SevCell(Severity.mild, 'mild', const [4]),
      _SevCell(Severity.moderate, 'moderate', const [4, 7]),
      _SevCell(Severity.severe, 'severe', const [4, 7, 10]),
    ];
    return Row(
      children: [
        for (var i = 0; i < cells.length; i++) ...[
          Expanded(
            child: _SevStep(
              cell: cells[i],
              active: cells[i].value == value,
              onTap: () => onChanged(cells[i].value),
            ),
          ),
          if (i != cells.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _SevCell {
  final Severity? value;
  final String label;
  final List<int> bars;
  _SevCell(this.value, this.label, this.bars);
}

class _SevStep extends StatelessWidget {
  final _SevCell cell;
  final bool active;
  final VoidCallback onTap;
  const _SevStep({
    required this.cell,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = active ? Tokens.paper : Tokens.graphite2;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          decoration: BoxDecoration(
            color: active ? Tokens.ink : Tokens.bg,
            border: Border.all(color: Tokens.graphite, width: 1),
            borderRadius: BorderRadius.circular(Tokens.r1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 12,
                child: cell.bars.isEmpty
                    ? Container(
                        width: 4,
                        height: 1,
                        color: active ? Tokens.paper : Tokens.graphite2,
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var i = 0; i < cell.bars.length; i++) ...[
                            Container(
                              width: 4,
                              height: cell.bars[i].toDouble(),
                              color:
                                  cell.value == Severity.severe &&
                                      active &&
                                      i == cell.bars.length - 1
                                  ? Tokens.oxide
                                  : (active ? Tokens.paper : Tokens.graphite2),
                            ),
                            if (i != cell.bars.length - 1)
                              const SizedBox(width: 2),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 6),
              Text(
                cell.label,
                style: Type.mono(
                  size: 10,
                  color: activeColor,
                  letterSpacingEm: 0.02,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
