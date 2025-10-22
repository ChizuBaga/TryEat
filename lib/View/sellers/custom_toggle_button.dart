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
    // ⭐️ Firestore Update should happen in the parent widget's onChanged handler
  }

  @override
  Widget build(BuildContext context) {
    // Determine track width to ensure text fits
    const double trackWidth = 140.0;
    const double trackHeight = 40.0;
    
    // Calculate the horizontal position of the text label
    double textPosition = _isAvailable ? 12.0 : (trackWidth - 100);

    return GestureDetector(
      onTap: () => _handleToggle(!_isAvailable),
      child: Container(
        width: trackWidth,
        height: trackHeight,
        padding: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          // 1. Grey Track Background
          color: Colors.grey[400], 
          borderRadius: BorderRadius.circular(trackHeight / 2),
          // 2. Blue Border
          border: Border.all(
            color: Colors.blue,
            width: 2.0,
          ),
        ),
        child: Stack(
          children: [
            // 3. Text Label (positioned dynamically)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              left: textPosition, // Move the text opposite the thumb
              top: 7,
              child: Text(
                _isAvailable ? 'Available' : 'Not Available',
                style: TextStyle(
                  color: Colors.black, 
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),

            // 4. White Circular Thumb
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              alignment: _isAvailable ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: trackHeight - 4, // 36
                height: trackHeight - 4, // 36
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
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