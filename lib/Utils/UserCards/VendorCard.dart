import 'package:cached_network_image/cached_network_image.dart';
import 'package:carocart/Utils/CacheManager.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

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

  String formatClosingTime(String? timeStr, BuildContext context) {
    if (timeStr == null || timeStr.isEmpty) return "";

    try {
      // Clean up: "23:30:00:000000" → "23:30:00"
      String clean = timeStr.split(":").length >= 2
          ? "${timeStr.split(":")[0]}:${timeStr.split(":")[1]}"
          : timeStr;

      // Parse into DateTime
      DateTime dt = DateTime.parse("1970-01-01 $clean:00");

      // Convert to 12h format
      return TimeOfDay.fromDateTime(dt).format(context);
    } catch (e) {
      return timeStr; // fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    // bool open = isVendorOpen(vendor);
    bool open = true;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (open) {
          Navigator.pushNamed(
            context,
            "/vendorproducts",
            arguments: vendor["id"],
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("This vendor is currently closed.")),
          );
        }
      },
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child:
                      vendor["profileImageUrl"] != null &&
                          vendor["profileImageUrl"].toString().isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: vendor["profileImageUrl"],
                          cacheManager: MyCacheManager(),
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            height: 160,
                            width: double.infinity,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(
                                Icons.image,
                                size: 48,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            (vendor["companyName"] ??
                                    vendor["firstName"] ??
                                    "V")
                                .toString()
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ),
                ),

                // Status Chip
                Positioned(
                  top: 12,
                  right: 12,
                  child: Chip(
                    backgroundColor: open ? Color(0xFF273E06) : Colors.red,
                    label: Text(
                      open ? "Open Now" : "Closed",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

            // Info section
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vendor name
                  Text(
                    vendor["companyName"] ??
                        "${vendor["firstName"] ?? ""} ${vendor["lastName"] ?? ""}"
                            .trim(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Address
                  if (vendor["addressLine1"] != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
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
                      ],
                    ),

                  const SizedBox(height: 8),

                  // Delivery info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.orange.shade800,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            open
                                ? "Opens until ${formatClosingTime(vendor["closingTime"], context)}"
                                : "Closed",
                            style: TextStyle(
                              fontSize: 13,
                              color: open
                                  ? Colors.orange.shade800
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            vendor["rating"]?.toString() ?? "N/A",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VendorCardShimmer extends StatelessWidget {
  const VendorCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image shimmer
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Title shimmer
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 25,
                  width: 280,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 16,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Subtitle shimmer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 8.0,
                    right: 8,
                    bottom: 16,
                  ),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 16,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 8.0,
                    right: 8,
                    bottom: 16,
                  ),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 16,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
