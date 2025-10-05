import 'package:carocart/Apis/address_service.dart';
import 'package:carocart/Apis/cart_service.dart';
import 'package:carocart/Apis/constants.dart';
import 'package:carocart/Apis/order_service.dart';
import 'package:carocart/Apis/razor_pay_service.dart';
import 'package:carocart/User/UserCart.dart';
import 'package:carocart/Utils/UserIdFromToken.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:dio/dio.dart';

class PaymentPage extends StatefulWidget {
  final List<CartItem> cartItems;
  final double totalAmount;
  final double grandTotal;
  final double deliveryfee;
  final double coupondiscount;

  const PaymentPage({
    super.key,
    required this.cartItems,
    required this.totalAmount,
    required this.grandTotal,
    required this.deliveryfee,
    required this.coupondiscount,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? selectedPaymentMethod;
  late Razorpay _razorpay;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void handlePlaceOrder() async {
    if (selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select payment method")),
      );
      return;
    }

    if (selectedPaymentMethod == "razorpay") {
      await _startRazorpayPayment();
    } else if (selectedPaymentMethod == "cod") {
      await _placeCODOrder();
    }
  }

  final Dio _dio = Dio();

  Future<void> _startRazorpayPayment() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final response = await RazorpayService.createOrder(
        totalAmount: widget.grandTotal.toInt(),
        items: widget.cartItems
            .map(
              (c) => {
                "productId": int.tryParse(c.id.toString()) ?? 0,
                "quantity": c.quantity,
                "price": c.price.toInt(),
              },
            )
            .toList(),
      );
      setState(() {
        _isLoading = false;
      });
      final orderData = response?.data;

      var options = {
        "key": orderData["key"],
        "amount": (widget.grandTotal * 100).toInt(),
        "currency": "INR",
        "name": "CaroCart",
        "description": "Secure Payment",
        "order_id": orderData["razorpayOrderId"],
        "prefill": {"contact": "9876543210", "email": "test@example.com"},
        "theme": {"color": "#7b9456"},
      };

      _razorpay.open(options);
    } catch (e) {
      debugPrint("Razorpay error: $e");
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      setState(() {
        _isLoading = true;
      });
      final addresses = await AddressService.getMyAddresses(context);
      final defaultAddress = addresses.firstWhere(
        (a) => a["isDefault"] == true,
        orElse: () =>
            addresses.isNotEmpty ? addresses.first : <String, dynamic>{},
      );
      var userIdString = await parseJwtUserId();
      var userId = int.parse(userIdString!);
      await RazorpayService.verifyPayment(
        razorpayOrderId: response.orderId!,
        razorpayPaymentId: response.paymentId!,
        razorpaySignature: response.signature!,
        amount: widget.grandTotal.toInt(),
        userId: userId,
        addressId: defaultAddress["id"],
        shippingAddress: defaultAddress["address"],
        items: widget.cartItems
            .map(
              (c) => {
                "productId": int.tryParse(c.id.toString()) ?? 0,
                "quantity": c.quantity,
                "price": c.price.toInt(),
              },
            )
            .toList(),
      );

      await CartService.clearCart();
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Payment successful")));
      Navigator.pushNamedAndRemoveUntil(
        context,
        "/userWithTab",
        arguments: {"index": 1},
        (route) => false,
      );
    } catch (e) {
      debugPrint("Verify error: $e");
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment failed: ${response.message}")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("External wallet selected: ${response.walletName}"),
      ),
    );
  }

  Future<void> _placeCODOrder() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final addresses = await AddressService.getMyAddresses(context);
      final defaultAddress = addresses.firstWhere(
        (a) => a["isDefault"] == true,
        orElse: () =>
            addresses.isNotEmpty ? addresses.first : <String, dynamic>{},
      );
      var userIdString = await parseJwtUserId();
      var userId = int.parse(userIdString!);
      final response = await OrderService.placeOrder(
        items: widget.cartItems
            .map(
              (c) => {
                "productId": int.tryParse(c.id.toString()) ?? 0,
                "quantity": c.quantity,
                "price": c.price.toInt(),
              },
            )
            .toList(),

        totalAmount: widget.totalAmount.toInt(),
        addressId: defaultAddress["id"],
        shippingAdress: defaultAddress["address"],
        userId: userId,
        paymentMethod: "cod",
      );

      if (response?.statusCode == 200) {
        await CartService.clearCart();
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Order placed with COD")));
        Navigator.pushNamedAndRemoveUntil(
          context,
          "/userWithTab",
          arguments: {"index": 1},
          (route) => false,
        );
      } else {
        throw Exception("COD order failed");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment"), elevation: 0),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Cart Summary ---
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Your Items",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const Divider(),
                              Column(
                                children: List.generate(widget.cartItems.length, (
                                  index,
                                ) {
                                  final item = widget.cartItems[index];
                                  return Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          children: [
                                            // Product Image
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                item.imageUrl,
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            const SizedBox(width: 14),

                                            // Product Details
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.productName,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    "Qty: ${item.quantity}",
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Price
                                            Text(
                                              "₹${(item.price * item.quantity).toStringAsFixed(2)}",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: Color(0xFF273E06),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Divider between items (not after the last one)
                                      if (index != widget.cartItems.length - 1)
                                        Divider(
                                          color: Colors.grey.shade300,
                                          thickness: 1,
                                          height: 8,
                                        ),
                                    ],
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // --- Payment Method ---
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Select Payment Method",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const Divider(),

                              const SizedBox(height: 6),

                              // --- Cash on Delivery ---
                              GestureDetector(
                                onTap: () => setState(
                                  () => selectedPaymentMethod = "cod",
                                ),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: selectedPaymentMethod == "cod"
                                          ? Colors.green
                                          : Colors.grey.shade300,
                                      width: 1.3,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    color: selectedPaymentMethod == "cod"
                                        ? Colors.green.withOpacity(0.08)
                                        : Colors.grey.shade50,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delivery_dining,
                                        size: 28,
                                        color: selectedPaymentMethod == "cod"
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          "Cash on Delivery",
                                          style: TextStyle(fontSize: 15),
                                        ),
                                      ),
                                      Radio<String>(
                                        value: "cod",
                                        groupValue: selectedPaymentMethod,
                                        activeColor: Colors.green,
                                        onChanged: (val) => setState(
                                          () => selectedPaymentMethod = val,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // --- Razorpay ---
                              GestureDetector(
                                onTap: () => setState(
                                  () => selectedPaymentMethod = "razorpay",
                                ),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: selectedPaymentMethod == "razorpay"
                                          ? Colors.green
                                          : Colors.grey.shade300,
                                      width: 1.3,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    color: selectedPaymentMethod == "razorpay"
                                        ? Colors.green.withOpacity(0.08)
                                        : Colors.grey.shade50,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.payment,
                                        size: 28,
                                        color:
                                            selectedPaymentMethod == "razorpay"
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          "Pay with Razorpay",
                                          style: TextStyle(fontSize: 15),
                                        ),
                                      ),
                                      Radio<String>(
                                        value: "razorpay",
                                        groupValue: selectedPaymentMethod,
                                        activeColor: Colors.green,
                                        onChanged: (val) => setState(
                                          () => selectedPaymentMethod = val,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // --- Order Summary ---
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Order Summary",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const Divider(),
                              summaryRow(
                                "Subtotal",
                                "₹${widget.totalAmount.toStringAsFixed(2)}",
                              ),
                              summaryRow(
                                "Delivery",
                                "₹${widget.deliveryfee}",
                              ), // Example delivery
                              summaryRow(
                                "Discount",
                                "- ₹${widget.coupondiscount}",
                              ), // Apply logic
                              const Divider(),
                              summaryRow(
                                "Grand Total",
                                "₹${widget.grandTotal.toStringAsFixed(2)}",
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- Checkout Button ---
              SafeArea(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  child: ElevatedButton(
                    onPressed: handlePlaceOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF273E06),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Confirm & Pay",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget summaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : null,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : null,
              fontSize: isBold ? 16 : 14,
              color: isBold ? Color(0xFF273E06) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
