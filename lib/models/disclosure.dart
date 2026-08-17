// ============================================================================
// مساعد الاستثمار Flutter - Company Disclosure Model
// ============================================================================

class CompanyDisclosure {
  final String id;
  final String symbol;
  final String companyName;
  final String title;
  final String category;
  final DateTime date;
  final String? attachmentUrl;
  final String? summary;

  CompanyDisclosure({
    required this.id,
    required this.symbol,
    required this.companyName,
    required this.title,
    required this.category,
    required this.date,
    this.attachmentUrl,
    this.summary,
  });

  factory CompanyDisclosure.fromJson(Map<String, dynamic> json) {
    return CompanyDisclosure(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      symbol: json['symbol'] ?? json['ticker'] ?? '',
      companyName: json['company_name'] ?? json['companyName'] ?? json['symbol'] ?? '',
      title: json['title'] ?? json['headline'] ?? 'إفصاح جوهري',
      category: json['category'] ?? json['type'] ?? 'إفصاحات عامة',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      attachmentUrl: json['attachment_url'] ?? json['file_url'] ?? json['pdf_url'],
      summary: json['summary'] ?? json['content'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'company_name': companyName,
        'title': title,
        'category': category,
        'date': date.toIso8601String(),
        'attachment_url': attachmentUrl,
        'summary': summary,
      };
}
