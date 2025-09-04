import 'package:carocart/User/UserCart.dart';
import 'package:flutter/material.dart';

class PaymentPage extends StatefulWidget {
  final List<CartItem> cartItems;
  final double totalAmount;
  final double grandTotal;

  const PaymentPage({
    Key? key,
    required this.cartItems,
    required this.totalAmount,
    required this.grandTotal,
  }) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? selectedPaymentMethod;

  void handlePlaceOrder() async {
    if (selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select payment method")),
      );
      return;
    }

    if (selectedPaymentMethod == "razorpay") {
      // Call OrderService.prepareRazorpayOrder + open Razorpay
    } else if (selectedPaymentMethod == "cod") {
      // Call OrderService.placeOrder + markOrderAsCod
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment")),
      body: Column(
        children: [
          // --- Payment Method Selection ---
          ListTile(
            title: const Text("Cash on Delivery"),
            leading: Radio<String>(
              value: "cod",
              groupValue: selectedPaymentMethod,
              onChanged: (val) => setState(() => selectedPaymentMethod = val),
            ),
          ),
          ListTile(
            title: const Text("Pay with Razorpay"),
            leading: Radio<String>(
              value: "razorpay",
              groupValue: selectedPaymentMethod,
              onChanged: (val) => setState(() => selectedPaymentMethod = val),
            ),
          ),

          const Spacer(),

          // --- Proceed Button ---
          ElevatedButton(
            onPressed: handlePlaceOrder,
            child: const Text("Confirm & Pay"),
          ),
        ],
      ),
    );
  }
}
