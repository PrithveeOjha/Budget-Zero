import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumericKeypad extends StatelessWidget {
  final String value;
  final ValueChanged<String> onValueChanged;
  final VoidCallback? onDone;
  final String currency;

  const NumericKeypad({
    super.key,
    required this.value,
    required this.onValueChanged,
    this.onDone,
    this.currency = '\$',
  });

  void _onKeyPressed(String key) {
    HapticFeedback.lightImpact();

    String newValue = value;

    if (key == 'backspace') {
      if (newValue.isNotEmpty) {
        newValue = newValue.substring(0, newValue.length - 1);
      }
    } else if (key == '.') {
      if (!newValue.contains('.')) {
        newValue = newValue.isEmpty ? '0.' : '$newValue.';
      }
    } else if (key == 'clear') {
      newValue = '';
    } else {
      // Limit decimal places to 2
      if (newValue.contains('.')) {
        final parts = newValue.split('.');
        if (parts.length > 1 && parts[1].length >= 2) {
          return;
        }
      }
      // Prevent leading zeros (except for decimals)
      if (newValue == '0' && key != '.') {
        newValue = key;
      } else {
        newValue = '$newValue$key';
      }
    }

    onValueChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayValue = value.isEmpty ? '0' : value;
    final amount = double.tryParse(displayValue) ?? 0;

    return Column(
      children: [
        // Amount display
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$currency${amount.toStringAsFixed(value.contains('.') ? (value.split('.').last.length.clamp(0, 2)) : 0)}',
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        // Keypad
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            childAspectRatio: 1.5,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildKey(context, '1'),
              _buildKey(context, '2'),
              _buildKey(context, '3'),
              _buildKey(context, '4'),
              _buildKey(context, '5'),
              _buildKey(context, '6'),
              _buildKey(context, '7'),
              _buildKey(context, '8'),
              _buildKey(context, '9'),
              _buildKey(context, '.'),
              _buildKey(context, '0'),
              _buildKey(context, 'backspace', icon: Icons.backspace_outlined),
            ],
          ),
        ),
        // Done button
        if (onDone != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  onDone!();
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Done'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildKey(BuildContext context, String key, {IconData? icon}) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _onKeyPressed(key),
      borderRadius: BorderRadius.circular(16),
      child: Center(
        child: icon != null
            ? Icon(icon, size: 28)
            : Text(
                key,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }
}
