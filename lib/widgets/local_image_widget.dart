import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../services/local_storage_service.dart';

class LocalImageWidget extends StatefulWidget {
  final String imageKey;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const LocalImageWidget({
    super.key,
    required this.imageKey,
    this.width,
    this.height,
    this.fit,
  });

  @override
  State<LocalImageWidget> createState() => _LocalImageWidgetState();
}

class _LocalImageWidgetState extends State<LocalImageWidget> {
  Uint8List? _imageData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(LocalImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageKey != widget.imageKey) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('Loading image with key: ${widget.imageKey}');
      
      // ตรวจสอบว่า key มีค่าหรือไม่
      if (widget.imageKey.isEmpty) {
        print('Image key is empty');
        if (mounted) {
          setState(() {
            _imageData = null;
            _isLoading = false;
            _error = 'Empty image key';
          });
        }
        return;
      }
      
      final imageData = await LocalStorageService.loadImage(widget.imageKey);
      print('Image data loaded: ${imageData?.length} bytes');
      
      if (mounted) {
        setState(() {
          _imageData = imageData;
          _isLoading = false;
          if (imageData == null) {
            _error = 'Image not found';
          }
        });
      }
    } catch (e) {
      print('Error loading local image: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.brown.shade50,
        alignment: Alignment.center,
        child: CircularProgressIndicator(
          color: Colors.brown.shade400,
          strokeWidth: 2,
        ),
      );
    }

    if (_error != null || _imageData == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.brown.shade50,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, color: Colors.brown.shade300, size: 16),
            const SizedBox(height: 1),
            Text(
              'Pet',
              style: TextStyle(
                fontSize: 6,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: widget.width,
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.width != null && widget.height != null ? 
            (widget.width! < widget.height! ? widget.width! / 2 : widget.height! / 2) : 8),
        child: Image.memory(
          _imageData!,
          width: widget.width,
          height: widget.height,
          fit: widget.fit ?? BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('LocalImageWidget error: $error');
            return Container(
              color: Colors.brown.shade50,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets, size: 32, color: Colors.brown.shade300),
                  const SizedBox(height: 4),
                  Text(
                    'Pet Photo',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Load Error',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.brown.shade500,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
