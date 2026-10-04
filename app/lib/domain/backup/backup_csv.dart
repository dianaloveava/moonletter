import '../../data/db/database.dart';

/// Excel 需要 BOM 才能识别 UTF-8 中文。
const String kCsvBom = '\uFEFF';

/// 表头（导出/导入共用）。
const List<String> kCsvHeader = <String>['成员', '开始日期', '结束日期'];

/// CSV 里的一行经期记录。
class CsvPeriodRow {
  const CsvPeriodRow({required this.member, required this.start, this.end});

  final String member;
  final String start;
  final String? end;
}

/// 导出经期记录为 CSV（成员,开始日期,结束日期）。
String encodePeriodsCsv(List<Period> periods, Map<String, String> memberNames) {
  final StringBuffer buffer = StringBuffer()..write(kCsvBom);
  buffer.write(kCsvHeader.map(_escape).join(','));
  buffer.write('\r\n');
  for (final Period period in periods) {
    final String name = memberNames[period.memberId] ?? '';
    buffer.write(
      <String>[
        _escape(name),
        _escape(period.startDate),
        _escape(period.endDate ?? ''),
      ].join(','),
    );
    buffer.write('\r\n');
  }
  return buffer.toString();
}

/// 解析 CSV：第一行是表头，列顺序固定「成员,开始日期,结束日期」，空行与注释行忽略。
List<CsvPeriodRow> decodePeriodsCsv(String text) {
  final String body = text.startsWith(kCsvBom) ? text.substring(1) : text;
  final List<List<String>> rows = _parse(body);
  final List<CsvPeriodRow> result = <CsvPeriodRow>[];
  for (int i = 0; i < rows.length; i++) {
    final List<String> row = rows[i];
    if (row.isEmpty || row.every((String cell) => cell.trim().isEmpty)) {
      continue;
    }
    if (i == 0 && row.first.trim() == kCsvHeader.first) {
      continue; // 表头
    }
    final String member = row.isNotEmpty ? row[0].trim() : '';
    final String start = row.length > 1 ? row[1].trim() : '';
    final String end = row.length > 2 ? row[2].trim() : '';
    if (member.isEmpty || start.isEmpty) {
      continue;
    }
    result.add(
      CsvPeriodRow(member: member, start: start, end: end.isEmpty ? null : end),
    );
  }
  return result;
}

String _escape(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

/// 极简 CSV 解析（支持双引号包裹与转义）。
List<List<String>> _parse(String text) {
  final List<List<String>> rows = <List<String>>[];
  List<String> row = <String>[];
  final StringBuffer field = StringBuffer();
  bool inQuotes = false;

  void endField() {
    row.add(field.toString());
    field.clear();
  }

  void endRow() {
    endField();
    rows.add(row);
    row = <String>[];
  }

  for (int i = 0; i < text.length; i++) {
    final String char = text[i];
    if (inQuotes) {
      if (char == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(char);
      }
      continue;
    }
    switch (char) {
      case '"':
        inQuotes = true;
      case ',':
        endField();
      case '\r':
        break;
      case '\n':
        endRow();
      default:
        field.write(char);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    endRow();
  }
  return rows;
}
