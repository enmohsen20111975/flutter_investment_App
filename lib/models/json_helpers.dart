// JSON helper utilities for robust API parsing.

bool? parseBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes' || normalized == 'y') return true;
    if (normalized == 'false' || normalized == '0' || normalized == 'no' || normalized == 'n') return false;
  }
  return null;
}

int? parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final trimmed = value.trim();
    return int.tryParse(trimmed) ?? double.tryParse(trimmed)?.toInt();
  }
  return null;
}

double? parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.trim());
  }
  return null;
}

List<double>? parseDoubleList(dynamic value) {
  if (value is List) {
    return value
        .map((item) => parseDouble(item))
        .where((item) => item != null)
        .cast<double>()
        .toList();
  }
  return null;
}

String? parseString(dynamic value) {
  if (value == null) return null;
  return value.toString();
}

List<String> parseStringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item?.toString() ?? '').where((item) => item.isNotEmpty).toList();
  }
  if (value is String) {
    final items = value.split(RegExp(r'[,;\n]+')).map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
    return items;
  }
  return [];
}

Map<String, dynamic>? parseJsonMap(dynamic value) {
  if (value is Map) {
    return value.cast<String, dynamic>();
  }
  return null;
}
