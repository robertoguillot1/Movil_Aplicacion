// v1.6 - widgets/receipt_capture_widget.dart
import 'package:flutter/material.dart';
import '../services/receipt_service.dart';

class ReceiptCaptureWidget extends StatefulWidget {
  final String? initialReceiptPath;
  final Function(String?) onReceiptChanged;

  const ReceiptCaptureWidget({
    super.key,
    this.initialReceiptPath,
    required this.onReceiptChanged,
  });

  @override
  State<ReceiptCaptureWidget> createState() => _ReceiptCaptureWidgetState();
}

class _ReceiptCaptureWidgetState extends State<ReceiptCaptureWidget> {
  String? _receiptPath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _receiptPath = widget.initialReceiptPath;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Comprobante de Pago Nequi',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                if (_receiptPath != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '✓',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Botones más compactos
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _takePhoto,
                    icon: _isLoading 
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt, size: 16),
                    label: Text(_isLoading ? 'Capturando...' : 'Tomar Foto', style: const TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _pickFromGallery,
                    icon: const Icon(Icons.photo_library, size: 16),
                    label: const Text('Galería', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
                if (_receiptPath != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isLoading ? null : _removeReceipt,
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    tooltip: 'Eliminar comprobante',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 6),
            Text(
              '💡 Toma una foto clara del comprobante',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    setState(() => _isLoading = true);
    
    try {
      final receiptPath = await ReceiptService.takePhoto();
      if (receiptPath != null) {
        setState(() => _receiptPath = receiptPath);
        widget.onReceiptChanged(receiptPath);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() => _isLoading = true);
    
    try {
      final receiptPath = await ReceiptService.pickFromGallery();
      if (receiptPath != null) {
        setState(() => _receiptPath = receiptPath);
        widget.onReceiptChanged(receiptPath);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _removeReceipt() {
    setState(() => _receiptPath = null);
    widget.onReceiptChanged(null);
  }
}

