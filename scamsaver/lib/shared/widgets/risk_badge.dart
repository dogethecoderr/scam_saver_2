import 'package:flutter/material.dart';
import '../services/claude_service.dart';

class RiskBadge extends StatelessWidget {
  final RiskLevel riskLevel;
  final bool showLabel;

  const RiskBadge({
    super.key,
    required this.riskLevel,
    this.showLabel = true,
  });

  Color get _color {
    switch (riskLevel) {
      case RiskLevel.low:
        return const Color(0xFF22C55E);
      case RiskLevel.medium:
        return const Color(0xFFF59E0B);
      case RiskLevel.high:
        return const Color(0xFFEF4444);
      case RiskLevel.critical:
        return const Color(0xFF991B1B);
      case RiskLevel.unknown:
        return Colors.grey;
    }
  }

  String get _label {
    switch (riskLevel) {
      case RiskLevel.low:
        return 'Low Risk';
      case RiskLevel.medium:
        return 'Medium Risk';
      case RiskLevel.high:
        return 'High Risk';
      case RiskLevel.critical:
        return 'Critical Risk';
      case RiskLevel.unknown:
        return 'Unknown';
    }
  }

  IconData get _icon {
    switch (riskLevel) {
      case RiskLevel.low:
        return Icons.check_circle;
      case RiskLevel.medium:
        return Icons.warning;
      case RiskLevel.high:
      case RiskLevel.critical:
        return Icons.dangerous;
      case RiskLevel.unknown:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _color,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _icon,
            color: _color,
            size: 16,
          ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              _label,
              style: TextStyle(
                color: _color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
