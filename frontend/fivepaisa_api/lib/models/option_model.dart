class OptionData {
  final String cpType;
  final double strikeRate;
  final double lastRate;
  final int openInterest;

  OptionData({
    required this.cpType,
    required this.strikeRate,
    required this.lastRate,
    required this.openInterest,
  });

  factory OptionData.fromJson(Map<String, dynamic> json) {
    return OptionData(
      cpType: json['CPType'],
      strikeRate: json['StrikeRate'].toDouble(),
      lastRate: json['LastRate'].toDouble(),
      openInterest: json['OpenInterest'],
    );
  }
}
