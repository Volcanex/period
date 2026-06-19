import 'package:flutter/material.dart';

import '../../../api/contracts/tracker_definition.dart';
import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';
import 'sheet_scaffold.dart';

class GenericTrackerSheet extends StatefulWidget {
  final TrackerDefinition definition;
  final double? numericValue;
  final String? enumValue;
  final bool? booleanValue;
  final String? textValue;
  final ValueChanged<double?> onNumericSet;
  final ValueChanged<String?> onEnumSet;
  final ValueChanged<bool?> onBooleanSet;
  final ValueChanged<String> onTextSet;

  const GenericTrackerSheet({
    super.key,
    required this.definition,
    required this.numericValue,
    required this.enumValue,
    required this.booleanValue,
    required this.textValue,
    required this.onNumericSet,
    required this.onEnumSet,
    required this.onBooleanSet,
    required this.onTextSet,
  });

  @override
  State<GenericTrackerSheet> createState() => _GenericTrackerSheetState();
}

class _GenericTrackerSheetState extends State<GenericTrackerSheet> {
  String? enumValue;
  bool? booleanValue;
  late final TextEditingController numericController;
  late final TextEditingController textController;
  String? numericError;

  @override
  void initState() {
    super.initState();
    enumValue = widget.enumValue;
    booleanValue = widget.booleanValue;
    numericController = TextEditingController(
      text: widget.numericValue == null
          ? ''
          : _formatNumber(widget.numericValue!),
    );
    textController = TextEditingController(text: widget.textValue ?? '');
  }

  @override
  void dispose() {
    numericController.dispose();
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.definition;
    return SheetScaffold(
      title: def.displayName.toLowerCase(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (def.isNumeric) _numericEditor(def),
          if (def.isEnum) _enumEditor(def),
          if (def.isBoolean) _booleanEditor(def),
          if (def.isText) _textEditor(def),
          const SizedBox(height: 14),
          SheetPrimaryButton(
            label: 'save',
            onPressed: () {
              if (def.isNumeric && !_saveNumeric(def)) return;
              if (def.isEnum) widget.onEnumSet(enumValue);
              if (def.isBoolean) widget.onBooleanSet(booleanValue);
              if (def.isText) widget.onTextSet(textController.text);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _numericEditor(TrackerDefinition def) {
    final min = _numberConstraint(def, 'minimum');
    final max = _numberConstraint(def, 'maximum');
    final unit = def.unit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('VALUE', style: Type.eyebrow()),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Tokens.base,
            borderRadius: BorderRadius.circular(Tokens.r2),
            border: Border.all(color: Tokens.borderSoft, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: numericController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false,
                  ),
                  cursorColor: Tokens.ink,
                  style: Type.display(
                    size: 24,
                    weight: Tokens.fwMedium,
                    height: 1.0,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'not logged',
                    hintStyle: Type.display(
                      size: 20,
                      color: Tokens.graphite2,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              if (unit != null && unit.isNotEmpty)
                Text(
                  unit,
                  style: Type.mono(
                    size: 11,
                    color: Tokens.graphite2,
                    letterSpacingEm: 0.04,
                  ),
                ),
            ],
          ),
        ),
        if (min != null || max != null || numericError != null) ...[
          const SizedBox(height: 8),
          Text(
            numericError ?? _rangeLabel(min, max),
            style: Type.mono(
              size: 10,
              color: numericError == null ? Tokens.graphite2 : Tokens.oxide,
              letterSpacingEm: 0.04,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: _ChoiceChip(
            label: 'not logged',
            active: numericController.text.trim().isEmpty,
            onTap: () => setState(() {
              numericController.clear();
              numericError = null;
            }),
          ),
        ),
      ],
    );
  }

  Widget _enumEditor(TrackerDefinition def) {
    final values = def.allowedValues ?? const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('VALUE', style: Type.eyebrow()),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _ChoiceChip(
              label: 'not logged',
              active: enumValue == null,
              onTap: () => setState(() => enumValue = null),
            ),
            for (final value in values)
              _ChoiceChip(
                label: _humanize(value),
                active: enumValue == value,
                onTap: () => setState(() => enumValue = value),
              ),
          ],
        ),
      ],
    );
  }

  Widget _booleanEditor(TrackerDefinition def) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('VALUE', style: Type.eyebrow()),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ChoiceChip(
                label: 'not logged',
                active: booleanValue == null,
                onTap: () => setState(() => booleanValue = null),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _ChoiceChip(
                label: 'yes',
                active: booleanValue == true,
                onTap: () => setState(() => booleanValue = true),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _ChoiceChip(
                label: 'no',
                active: booleanValue == false,
                onTap: () => setState(() => booleanValue = false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _textEditor(TrackerDefinition def) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('TEXT', style: Type.eyebrow()),
        const SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(minHeight: 74),
          decoration: BoxDecoration(
            color: Tokens.base,
            borderRadius: BorderRadius.circular(Tokens.r2),
            border: Border.all(color: Tokens.borderSoft, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: TextField(
            controller: textController,
            minLines: 3,
            maxLines: null,
            maxLength: _maxLength(def),
            cursorColor: Tokens.ink,
            style: Type.body(size: 14, height: 1.55),
            decoration: InputDecoration(
              isDense: true,
              counterStyle: Type.mono(
                size: 10,
                color: Tokens.graphite2,
                letterSpacingEm: 0.04,
              ),
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              hintText: 'add value...',
              hintStyle: Type.body(
                size: 14,
                color: Tokens.graphite2,
                height: 1.55,
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _saveNumeric(TrackerDefinition def) {
    final raw = numericController.text.trim();
    if (raw.isEmpty) {
      widget.onNumericSet(null);
      return true;
    }
    final parsed = double.tryParse(raw);
    if (parsed == null) {
      setState(() => numericError = 'enter a number');
      return false;
    }
    final min = _numberConstraint(def, 'minimum');
    final max = _numberConstraint(def, 'maximum');
    if (min != null && parsed < min) {
      setState(() => numericError = 'minimum ${_formatNumber(min)}');
      return false;
    }
    if (max != null && parsed > max) {
      setState(() => numericError = 'maximum ${_formatNumber(max)}');
      return false;
    }
    widget.onNumericSet(parsed);
    return true;
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: active ? Tokens.ink : Tokens.bg,
            borderRadius: BorderRadius.circular(Tokens.r2),
            border: Border.all(color: Tokens.graphite, width: Tokens.bwRule),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Type.body(
              size: 12,
              weight: Tokens.fwMedium,
              color: active ? Tokens.paper : Tokens.ink,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

int? _maxLength(TrackerDefinition def) {
  final raw = def.validationSchema?['maxLength'];
  if (raw is num) return raw.toInt();
  return null;
}

double? _numberConstraint(TrackerDefinition def, String key) {
  final raw = def.validationSchema?[key];
  if (raw is num) return raw.toDouble();
  return null;
}

String _rangeLabel(double? min, double? max) {
  if (min != null && max != null) {
    return 'range ${_formatNumber(min)}–${_formatNumber(max)}';
  }
  if (min != null) return 'minimum ${_formatNumber(min)}';
  if (max != null) return 'maximum ${_formatNumber(max)}';
  return '';
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _humanize(String value) => value.replaceAll('_', ' ');
