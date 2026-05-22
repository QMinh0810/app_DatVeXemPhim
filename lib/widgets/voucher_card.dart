import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/voucher_model.dart';

class VoucherCard extends StatelessWidget {
  final VoucherModel voucher;
  final bool isSelected;
  final VoidCallback onTap;

  const VoucherCard({
    super.key,
    required this.voucher,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final isShipping = voucher.type == 'shipping';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipPath(
          clipper: TicketClipper(),
          child: Row(
            children: [
              // Left part with icon/image
              Container(
                width: 100,
                decoration: BoxDecoration(
                  color: isShipping ? const Color(0xFF00BFA5) : const Color(0xFFEE4D2D),
                  border: Border(
                    right: BorderSide(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                      style: BorderStyle.none,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isShipping ? Icons.local_shipping : Icons.confirmation_number,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isShipping ? 'FREE SHIP' : 'VOUCHER',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Right part with details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        voucher.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        voucher.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'HSD: ${DateFormat('dd.MM.yyyy').format(voucher.expiryDate)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? const Color(0xFFEE4D2D) : Colors.grey[300]!,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 14, color: Color(0xFFEE4D2D))
                                : const SizedBox(width: 14, height: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);

    // Right side cut-out
    // path.arcToPoint(Offset(size.width, size.height * 0.3), radius: Radius.circular(10));
    
    // Scalloped effect on the vertical line between left and right
    double dashWidth = 100; // where the line is
    double punchRadius = 6.0;
    
    // Top punch
    path.moveTo(dashWidth - punchRadius, 0);
    path.arcToPoint(
      Offset(dashWidth + punchRadius, 0),
      radius: Radius.circular(punchRadius),
      clockwise: false,
    );
    
    // Bottom punch
    path.moveTo(dashWidth + punchRadius, size.height);
    path.arcToPoint(
      Offset(dashWidth - punchRadius, size.height),
      radius: Radius.circular(punchRadius),
      clockwise: false,
    );

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
