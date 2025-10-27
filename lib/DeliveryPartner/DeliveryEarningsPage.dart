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
  // Theme colors
  static const Color primaryGreen = Color(0xFF273E06);
  static const Color lightGreen = Color(0xFF4A6B1E);
  static const Color darkGreen = Color(0xFF1A2B04);
  static const Color accentGreen = Color(0xFF3B5A0F);

  String? _token;
  DateTime? _fromDate;
  DateTime? _toDate;

  Map<String, dynamic> _summaryData = {"today": {}, "week": {}, "month": {}};
  List<dynamic> _earningsList = [];

  bool _isLoading = true;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

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

      final todaySummary = await getDeliveryEarningsSummary(
        context,
        _token!,
        "today",
      );
      final weekSummary = await getDeliveryEarningsSummary(
        context,
        _token!,
        "week",
      );
      final monthSummary = await getDeliveryEarningsSummary(
        context,
        _token!,
        "month",
      );

      final combinedSummary = {
        "today": todaySummary,
        "week": weekSummary,
        "month": monthSummary,
      };

      setState(() {
        _summaryData = combinedSummary;
      });

      final earnings = await getDeliveryEarnings(
        context,
        _token!,
        from: fromStr,
        to: toStr,
      );

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

  Future<void> _selectDate({required bool isFrom}) async {
    final DateTime today = DateTime.now();
    final DateTime firstDate = DateTime(today.year - 1);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: firstDate,
      lastDate: today,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
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
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
          ),
        ),
      );
    }

    if (_isError) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[300], size: 64),
              const SizedBox(height: 16),
              Text(
                "Something went wrong",
                style: TextStyle(fontSize: 18, color: Colors.red[700]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchData,
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Earnings Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryGreen, accentGreen],
            ),
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildSummaryCards(),
              const SizedBox(height: 20),

              // Date Range Filters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryGreen.withOpacity(0.1),
                                accentGreen.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.filter_list,
                            color: primaryGreen,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Filter by Date",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateButton(
                            label: _fromDate != null
                                ? DateFormat('dd MMM yyyy').format(_fromDate!)
                                : "From Date",
                            onTap: () => _selectDate(isFrom: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateButton(
                            label: _toDate != null
                                ? DateFormat('dd MMM yyyy').format(_toDate!)
                                : "To Date",
                            onTap: () => _selectDate(isFrom: false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryGreen, accentGreen],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryGreen.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(28),
                              onTap: _fetchData,
                              child: const SizedBox(
                                width: 56,
                                height: 56,
                                child: Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Earnings List
              if (_earningsList.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No earnings data available",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryGreen.withOpacity(0.1),
                                  accentGreen.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.history,
                              color: primaryGreen,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Transaction History",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _earningsList.length,
                      itemBuilder: (context, index) {
                        final item = _earningsList[index];
                        return _buildEarningsItem(item);
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildSummaryCard("Today", _summaryData["today"], Icons.today),
          const SizedBox(height: 12),
          _buildSummaryCard(
            "This Week",
            _summaryData["week"],
            Icons.calendar_view_week,
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            "This Month",
            _summaryData["month"],
            Icons.calendar_month,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    Map<String, dynamic>? data,
    IconData icon,
  ) {
    final deliveredCount = data?['deliveredCount'] ?? 0;
    final totalFee = data?['totalFee'] ?? 0;
    final totalTip = data?['totalTip'] ?? 0;
    final totalPenalty = data?['totalPenalty'] ?? 0;
    final net = data?['net'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lightGreen.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryGreen.withOpacity(0.1),
                      accentGreen.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: primaryGreen, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                "Delivered",
                "$deliveredCount",
                Icons.check_circle_outline,
              ),
              _buildSummaryItem(
                "Tips",
                "₹$totalTip",
                Icons.volunteer_activism_outlined,
              ),
              _buildSummaryItem(
                "Penalty",
                "₹$totalPenalty",
                Icons.warning_amber_outlined,
              ),
            ],
          ),

          const Divider(height: 30),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryGreen.withOpacity(0.1),
                  accentGreen.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: primaryGreen,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  "₹$net",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              "Net Earnings",
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: primaryGreen),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildDateButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lightGreen.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: primaryGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEarningsItem(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lightGreen.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: primaryGreen,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat(
                        'dd MMM yyyy',
                      ).format(DateTime.parse(item['deliveredAt'])),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryGreen, accentGreen],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item['status'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAmountDetail("Fee", item['fee']),
                _buildAmountDetail("Tip", item['tip']),
                _buildAmountDetail("Penalty", item['penalty']),
                _buildAmountDetail("Net", item['netAmount'], isHighlight: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountDetail(
    String title,
    dynamic value, {
    bool isHighlight = false,
  }) {
    return Column(
      children: [
        Text(
          "₹${value ?? 0}",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isHighlight ? primaryGreen : Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }
}
