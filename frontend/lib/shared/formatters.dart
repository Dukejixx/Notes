String _two(int n) => n.toString().padLeft(2, '0');

/// `10/10/2026 17:05`
String formatDateTime(DateTime value) =>
    '${_two(value.day)}/${_two(value.month)}/${value.year} ${_two(value.hour)}:${_two(value.minute)}';

/// `10/10/2026`
String formatDate(DateTime value) =>
    '${_two(value.day)}/${_two(value.month)}/${value.year}';

/// `10/10`
String formatShortDate(DateTime value) =>
    '${_two(value.day)}/${_two(value.month)}';

/// `58,33 %`
String formatPercentage(double value) =>
    '${value.toStringAsFixed(2).replaceAll('.', ',')} %';
