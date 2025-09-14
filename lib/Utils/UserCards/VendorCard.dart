import 'package:flutter/material.dart';

class VendorCard extends StatelessWidget {
  final Map<String, dynamic> vendor;
  final VoidCallback? onTap;

  const VendorCard({Key? key, required this.vendor, this.onTap})
    : super(key: key);

  bool isVendorOpen(Map<String, dynamic> v) {
    if (v.isEmpty ||
        v["acceptingOrders"] == false ||
        (v["acceptingOrders"] is String &&
            (v["acceptingOrders"] as String).toLowerCase() == "false")) {
      return false;
    }

    if (v["openingTime"] == null || v["closingTime"] == null) return true;

    DateTime now = DateTime.now();
    List<String> openParts = v["openingTime"].split(":");
    List<String> closeParts = v["closingTime"].split(":");

    DateTime openTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(openParts[0]),
      int.parse(openParts.length > 1 ? openParts[1] : "0"),
    );

    DateTime closeTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(closeParts[0]),
      int.parse(closeParts.length > 1 ? closeParts[1] : "0"),
    );

    // overnight support
    if (closeTime.isBefore(openTime)) {
      return now.isAfter(openTime) || now.isBefore(closeTime);
    } else {
      return now.isAfter(openTime) && now.isBefore(closeTime);
    }
  }

  String cleanAddress(String? address) {
    if (address == null) return "";
    String cleaned = address.replaceAll(RegExp(r'^[A-Z0-9+ ]+,\s*'), "");
    List<String> parts = cleaned.split(",").map((e) => e.trim()).toList();
    if (parts.length > 2) {
      cleaned = parts.sublist(0, 2).join(", ");
    }
    return cleaned;
  }

  @override
  Widget build(BuildContext context) {
    bool open = isVendorOpen(vendor);

    return GestureDetector(
      onTap: () {
        if (open) {
          Navigator.pushNamed(
            context,
            "/vendorproducts",
            arguments: vendor["id"],
          );
        } else {
          // Optional: show a snackbar/toast
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("This vendor is currently closed.")),
          );
        }
      },

      child: Opacity(
        opacity: open ? 1.0 : 0.8,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: open ? Colors.white : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: open
                        ? Colors.green.withOpacity(0.15)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: open ? Colors.black12 : Colors.grey.shade400,
                ),
              ),
              margin: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //Image / Placeholder
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: ColorFiltered(
                      colorFilter: open
                          ? const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.multiply,
                            )
                          : const ColorFilter.mode(
                              Colors.grey,
                              BlendMode.saturation,
                            ),
                      child:
                          vendor["profileImageUrl"] != null &&
                              vendor["profileImageUrl"].toString().isNotEmpty
                          ? Image.network(
                              vendor["profileImageUrl"],
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: double.infinity,
                              height: 200,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                              ),
                              child: Text(
                                (vendor["companyName"] ??
                                        vendor["firstName"] ??
                                        "V")
                                    .toString()
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                    ),
                  ),

                  //Vendor Details
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendor["companyName"] ??
                              "${vendor["firstName"] ?? ""} ${vendor["lastName"] ?? ""}"
                                  .trim(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        if (vendor["addressLine1"] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              cleanAddress(vendor["addressLine1"]),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                        const SizedBox(height: 6),

                        Row(
                          children: [
                            Text(
                              open
                                  ? "Open"
                                  : vendor["manualCloseReason"] != null
                                  ? "Closed Now – ${vendor["manualCloseReason"]}"
                                  : "Closed Now",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: open ? Colors.green : Colors.red,
                              ),
                            ),
                            if (open && vendor["etaMinutes"] != null)
                              Text(
                                " • ${vendor["etaMinutes"]} min",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            //Closed Overlay
            if (!open)
              Positioned.fill(
                child: Center(
                  child: Transform.translate(
                    offset: Offset(0, -40),
                    child: Transform.rotate(
                      angle: -0.5,
                      child: Text(
                        "CLOSED NOW",
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.withOpacity(0.8),
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
