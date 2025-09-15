import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../Apis/delivery.Person.dart';

class DeliveryEarningsPage extends StatefulWidget {
  const DeliveryEarningsPage({super.key});

  @override
  State<DeliveryEarningsPage> createState() => _DeliveryEarningsPageState();
}

class _DeliveryEarningsPageState extends State<DeliveryEarningsPage> {
  String? _token;
  DateTime? _fromDate;
  DateTime? _toDate;

  /// Holds summary data for today, week, and month
  Map<String, dynamic> _summaryData = {"today": {}, "week": {}, "month": {}};

  List<dynamic> _earningsList = [];

  bool _isLoading = true;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  /// Get token from local storage and load data
  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null || token.isEmpty) {
      setState(() {
        _isError = true;
        _isLoading = false;
      });
      return;
    }

    _token = token;
    await _fetchData();
  }

  /// Fetch Summary first, then Earnings List
  Future<void> _fetchData() async {
    if (_token == null) return;

    setState(() => _isLoading = true);

    try {
      final fromStr = _fromDate != null
          ? DateFormat('yyyy-MM-dd').format(_fromDate!)
          : null;
      final toStr = _toDate != null
          ? DateFormat('yyyy-MM-dd').format(_toDate!)
          : null;

      debugPrint("Fetching data sequentially...");

      // Step 1: Fetch Summary Data
      debugPrint("Fetching TODAY summary...");
      final todaySummary = await getDeliveryEarningsSummary(
        context,
        _token!,
        "today",
      );
      debugPrint("Today Summary: $todaySummary");

      debugPrint("Fetching WEEK summary...");
      final weekSummary = await getDeliveryEarningsSummary(
        context,
        _token!,
        "week",
      );
      debugPrint("Week Summary: $weekSummary");

      debugPrint("Fetching MONTH summary...");
      final monthSummary = await getDeliveryEarningsSummary(
        context,
        _token!,
        "month",
      );
      debugPrint("Month Summary: $monthSummary");

      final combinedSummary = {
        "today": todaySummary,
        "week": weekSummary,
        "month": monthSummary,
      };

      // Update UI immediately after summary fetch
      setState(() {
        _summaryData = combinedSummary;
      });

      // Step 2: Fetch Earnings List
      debugPrint("Fetching Earnings List...");
      final earnings = await getDeliveryEarnings(
        context,
        _token!,
        from: fromStr,
        to: toStr,
      );
      debugPrint("Earnings List Response: $earnings");

      // Final UI Update
      setState(() {
        _earningsList = earnings['data'] ?? [];
        _isLoading = false;
        _isError = false;
      });
    } catch (e, stackTrace) {
      debugPrint("FETCH DATA ERROR: $e");
      debugPrint("STACK TRACE: $stackTrace");
      setState(() {
        _isError = true;
        _isLoading = false;
      });
    }
  }

  /// Open date picker
  Future<void> _selectDate({required bool isFrom}) async {
    final DateTime today = DateTime.now();
    final DateTime firstDate = DateTime(today.year - 1);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: firstDate,
      lastDate: today,
    );

    if (pickedDate != null) {
      setState(() {
        if (isFrom) {
          _fromDate = pickedDate;
        } else {
          _toDate = pickedDate;
        }
      });
      await _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 60),
              const SizedBox(height: 10),
              const Text(
                "Something went wrong",
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: _fetchData, child: const Text("Retry")),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Earnings Details"),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
              _buildSummaryCards(),
              const SizedBox(height: 10),

              // Date Range Filters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // From Date
                    Expanded(
                      flex: 3,
                      child: _buildDateButton(
                        label: _fromDate != null
                            ? DateFormat('dd MMM yyyy').format(_fromDate!)
                            : "From Date",
                        onTap: () => _selectDate(isFrom: true),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // To Date
                    Expanded(
                      flex: 3,
                      child: _buildDateButton(
                        label: _toDate != null
                            ? DateFormat('dd MMM yyyy').format(_toDate!)
                            : "To Date",
                        onTap: () => _selectDate(isFrom: false),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Filter Button
                    Flexible(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _fetchData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          fixedSize: const Size(
                            56,
                            56,
                          ), // Equal width and height
                          shape: const CircleBorder(), // Circular shape
                          padding: const EdgeInsets.all(12),
                        ),
                        child: const Icon(
                          Icons.refresh,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Earnings List
              if (_earningsList.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      "No earnings data available",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: _earningsList.length,
                  itemBuilder: (context, index) {
                    final item = _earningsList[index];
                    return _buildEarningsItem(item);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds three summary cards for today, week, month
  Widget _buildSummaryCards() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSummaryCard("Today", _summaryData["today"]),
          const SizedBox(height: 10),
          _buildSummaryCard("This Week", _summaryData["week"]),
          const SizedBox(height: 10),
          _buildSummaryCard("This Month", _summaryData["month"]),
        ],
      ),
    );
  }

  /// Single summary card
  Widget _buildSummaryCard(String title, Map<String, dynamic>? data) {
    final deliveredCount = data?['deliveredCount'] ?? 0;
    final totalFee = data?['totalFee'] ?? 0;
    final totalTip = data?['totalTip'] ?? 0;
    final totalPenalty = data?['totalPenalty'] ?? 0;
    final net = data?['net'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem("Delivered", "$deliveredCount"),
              _buildSummaryItem("Tips", "₹$totalTip"),
              _buildSummaryItem("Penalty", "₹$totalPenalty"),
            ],
          ),

          const Divider(height: 30),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.currency_rupee, color: Colors.green, size: 28),
              Text(
                net.toString(),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Center(
            child: Text(
              "Net Earnings",
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }

  /// Date Picker Button
  Widget _buildDateButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: Colors.green),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Earnings Item Widget
  Widget _buildEarningsItem(dynamic item) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row - Date & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Delivered: ${DateFormat('dd MMM yyyy').format(DateTime.parse(item['deliveredAt']))}",
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item['status'],
                  style: const TextStyle(color: Colors.green, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Fee, Tip, Penalty, Net Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAmountDetail("Fee", item['fee']),
              _buildAmountDetail("Tip", item['tip']),
              _buildAmountDetail("Penalty", item['penalty']),
              _buildAmountDetail("Net", item['netAmount']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountDetail(String title, dynamic value) {
    return Column(
      children: [
        Text(
          "₹${value ?? 0}",
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}
