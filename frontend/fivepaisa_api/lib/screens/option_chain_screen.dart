import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OptionData {
  final String cpType;
  final int openInterest;
  final double lastRate;
  final double strikeRate;

  OptionData({
    required this.cpType,
    required this.openInterest,
    required this.lastRate,
    required this.strikeRate,
  });

  factory OptionData.fromJson(Map<String, dynamic> json) {
    return OptionData(
      cpType: json['CPType'] ?? '',
      openInterest: json['OpenInterest'] ?? 0,
      lastRate: (json['LastRate'] ?? 0).toDouble(),
      strikeRate: (json['StrikeRate'] ?? 0).toDouble(),
    );
  }
}

class OptionChainPage extends StatefulWidget {
  const OptionChainPage({super.key});

  @override
  State<OptionChainPage> createState() => _OptionChainPageState();
}

class _OptionChainPageState extends State<OptionChainPage>
    with SingleTickerProviderStateMixin {
  List<OptionData> ceOptions = [];
  List<OptionData> peOptions = [];
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    fetchOptionChain();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  Future<void> fetchOptionChain() async {
    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/option-chain'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final options = (data['Options'] as List)
          .map((e) => OptionData.fromJson(e))
          .toList();

      setState(() {
        ceOptions = options.where((e) => e.cpType == 'CE').toList();
        peOptions = options.where((e) => e.cpType == 'PE').toList();
      });

      _controller.forward();
    } else {
      print("Failed to fetch option chain: ${response.statusCode}");
    }
  }

  Widget buildOptionRow(double strikeRate) {
    final ce = ceOptions.firstWhere(
      (e) => e.strikeRate == strikeRate && e.cpType == 'CE',
      orElse: () => OptionData(
        cpType: 'CE',
        openInterest: 0,
        lastRate: 0,
        strikeRate: strikeRate,
      ),
    );

    final pe = peOptions.firstWhere(
      (e) => e.strikeRate == strikeRate && e.cpType == 'PE',
      orElse: () => OptionData(
        cpType: 'PE',
        openInterest: 0,
        lastRate: 0,
        strikeRate: strikeRate,
      ),
    );

    return FadeTransition(
      opacity: _fadeIn,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildOptionBox(ce, color: Colors.greenAccent.shade100),
              Column(
                children: [
                  Text(
                    "${strikeRate.toInt()}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Text("Strike"),
                ],
              ),
              buildOptionBox(pe, color: Colors.redAccent.shade100),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildOptionBox(OptionData option, {required Color color}) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            option.cpType,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text("OI: ${option.openInterest}"),
          Text("Price: ${option.lastRate.toStringAsFixed(2)}"),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  final strikes = ceOptions
      .map((e) => e.strikeRate)
      .toSet()
      .toList()
    ..sort();

  if (strikes.isEmpty) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  // Determine ATM strike (closest to average of CE+PE prices)
  final allOptions = [...ceOptions, ...peOptions];
  final avgPrice = allOptions.map((e) => e.lastRate).reduce((a, b) => a + b) /
      allOptions.length;

  // Find ATM strike
  double atmStrike = strikes.first;
  double minDiff = (atmStrike - avgPrice).abs();

  for (final strike in strikes) {
    final diff = (strike - avgPrice).abs();
    if (diff < minDiff) {
      minDiff = diff;
      atmStrike = strike;
    }
  }

  // Get 10 ITM & 10 OTM from ATM
  final atmIndex = strikes.indexOf(atmStrike);
  final start = (atmIndex - 10).clamp(0, strikes.length - 1);
  final end = (atmIndex + 10).clamp(0, strikes.length);

  final filteredStrikes = strikes.sublist(start, end);

  return Scaffold(
    appBar: AppBar(
      title: const Text("NIFTY Option Chain"),
      centerTitle: true,
    ),
    body: ListView.builder(
      itemCount: filteredStrikes.length,
      itemBuilder: (_, index) => buildOptionRow(filteredStrikes[index]),
    ),
  );
}
    }