import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dashboard_page.dart';
import '../../../core/theme/colors.dart'; // <-- your AppColors file

class QRGeneratorPage extends StatefulWidget {
  final bool isNewAccount;
  final String sellerId;

  const QRGeneratorPage({
    Key? key,
    required this.isNewAccount,
    required this.sellerId,
  }) : super(key: key);

  @override
  State<QRGeneratorPage> createState() => _QRGeneratorPageState();
}

class _QRGeneratorPageState extends State<QRGeneratorPage> {
  bool _showQR = false;

  @override
  Widget build(BuildContext context) {
    final double qrSize = MediaQuery.of(context).size.width * 0.75;
    final String websiteUrl =
        "https://toffiy.github.io/bizcat_website/catalog.html?seller=${widget.sellerId}";

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => DashboardPage()),
            );
          },
        ),
        title: const Text(
          'QR Code Generator',
          style: TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: widget.isNewAccount
              ? Column(
                  children: [
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _showQR
                            ? QrImageView(
                                data: websiteUrl,
                                version: QrVersions.auto,
                                size: qrSize,
                                backgroundColor: AppColors.white,
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.qr_code_2,
                                      size: 80, color: Colors.grey[400]),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Your QR code will appear here',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _showQR = true;
                          });
                        },
                        icon: const Icon(Icons.qr_code, color: AppColors.white),
                        label: const Text(
                          'Generate QR Code',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline,
                        size: 60, color: Colors.grey[500]),
                    const SizedBox(height: 10),
                    const Text(
                      'No QR code needed for existing accounts.',
                      style: TextStyle(fontSize: 16, color: AppColors.black),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
