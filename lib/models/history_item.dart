class HistoryItem {
  final int? id;
  final String qrContent;
  final String date; // E.g., 'Today', 'Yesterday', or '2026-06-29'
  final String time; // E.g., '14:23'
  final String scanType; // 'url' or 'text'
  final String url; // The URL if it's a URL scan, empty string otherwise
  final String text; // The raw text if it's a text scan, empty string otherwise
  final bool isFavorite;
  final int timestamp; // Milliseconds since epoch for duplicate comparison

  HistoryItem({
    this.id,
    required this.qrContent,
    required this.date,
    required this.time,
    required this.scanType,
    required this.url,
    required this.text,
    this.isFavorite = false,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'qr_content': qrContent,
      'date': date,
      'time': time,
      'scan_type': scanType,
      'url': url,
      'text': text,
      'is_favorite': isFavorite ? 1 : 0,
      'timestamp': timestamp,
    };
  }

  factory HistoryItem.fromMap(Map<String, dynamic> map) {
    return HistoryItem(
      id: map['id'] as int?,
      qrContent: map['qr_content'] as String,
      date: map['date'] as String,
      time: map['time'] as String,
      scanType: map['scan_type'] as String,
      url: map['url'] as String,
      text: map['text'] as String,
      isFavorite: (map['is_favorite'] as int) == 1,
      timestamp: map['timestamp'] as int? ?? 0,
    );
  }

  HistoryItem copyWith({
    int? id,
    String? qrContent,
    String? date,
    String? time,
    String? scanType,
    String? url,
    String? text,
    bool? isFavorite,
    int? timestamp,
  }) {
    return HistoryItem(
      id: id ?? this.id,
      qrContent: qrContent ?? this.qrContent,
      date: date ?? this.date,
      time: time ?? this.time,
      scanType: scanType ?? this.scanType,
      url: url ?? this.url,
      text: text ?? this.text,
      isFavorite: isFavorite ?? this.isFavorite,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
