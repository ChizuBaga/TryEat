import 'package:flutter/material.dart';

class CustomAvailabilityToggle extends StatefulWidget {
  final bool initialValue;
  final ValueChanged<bool> onChanged;

  const CustomAvailabilityToggle({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<CustomAvailabilityToggle> createState() => _CustomAvailabilityToggleState();
}

class _CustomAvailabilityToggleState extends State<CustomAvailabilityToggle> {
  late bool _isAvailable;

  @override
  void initState() {
    super.initState();
    _isAvailable = widget.initialValue;
  }

  void _handleToggle(bool newValue) {
    setState(() {
      _isAvailable = newValue;
    });
    widget.onChanged(newValue);
  }

  // lib/path/to/custom_availability_toggle.dart

  @override
  Widget build(BuildContext context) {
    // --- 1. REDUCE THESE VALUES ---
    const double trackWidth = 110.0; // Was 160.0
    const double trackHeight = 45.0; // Was 50.0
    // --- END MODIFICATION ---
    
    const double internalPadding = 1.0; 
    
    final double thumbSize = trackHeight - (internalPadding * 2); // This will now be 37
    final double textWidth = trackWidth - thumbSize - (internalPadding * 3); // This will now be 91

    return GestureDetector(
      onTap: () => _handleToggle(!_isAvailable),
      child: Container(
        width: trackWidth,   // Use the smaller width
        height: trackHeight, // Use the smaller height
        padding: const EdgeInsets.all(internalPadding), 
        decoration: BoxDecoration(
          color: _isAvailable ? Color.fromARGB(255, 144, 238, 144) : Colors.grey[400],
          borderRadius: BorderRadius.circular(trackHeight / 2),
        ),
        child: Stack(
          children: [
            // --- 1. TEXT LABEL ---
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              alignment: _isAvailable ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                width: textWidth, 
                alignment: Alignment.center,
                child: Text(
                  _isAvailable ? 'Available' : 'Not Available',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    // --- 2. CONSIDER REDUCING FONT SIZE ---
                    fontSize: 11, // Was 14
                    // --- END MODIFICATION ---
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // --- 2. WHITE CIRCULAR THUMB ---
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              alignment: _isAvailable ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: thumbSize,
                height: thumbSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}