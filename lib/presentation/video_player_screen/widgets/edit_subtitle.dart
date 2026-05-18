import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class EditSubtitle extends StatefulWidget {
  final double? initialFontSize;
  final int? initialFontColorValue;
  final int? initialBgColorValue;

  const EditSubtitle({
    super.key,
    this.initialFontSize,
    this.initialFontColorValue,
    this.initialBgColorValue,
  });

  @override
  State<EditSubtitle> createState() => _EditSubtitleState();
}

class _EditSubtitleState extends State<EditSubtitle> {
  double _fontSize = 18.0;
  Color _fontColor = Colors.white;
  Color _bgColor = Colors.black54;

  @override
  void initState() {
    super.initState();
    if (widget.initialFontSize != null) _fontSize = widget.initialFontSize!;
    if (widget.initialFontColorValue != null)
      _fontColor = Color(widget.initialFontColorValue!);
    if (widget.initialBgColorValue != null)
      _bgColor = Color(widget.initialBgColorValue!);
  }

  Future<void> _pickColor({
    required Color currentColor,
    required ValueChanged<Color> onColorChanged,
    required String title,
  }) async {
    Color temp = currentColor;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: (c) => temp = c,
            enableAlpha: true,
            showLabel: true,
            pickerAreaHeightPercent: 0.7,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancle',
              style: TextStyle(color: Color(0xFF0D47A1)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              onColorChanged(temp);
              Navigator.of(context).pop();
            },
            child: const Text(
              'Select',
              style: TextStyle(color: Color(0xFF0D47A1)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Subtitle Editing',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 140,
                color: Colors.black,
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  color: _bgColor,
                  child: Text(
                    'محل تست ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: _fontSize,
                      color: _fontColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Font Size'),
                  Text(_fontSize.toStringAsFixed(0)),
                ],
              ),
              Slider(
                value: _fontSize,
                min: 10,
                max: 60,
                divisions: 50,
                label: _fontSize.toStringAsFixed(0),
                onChanged: (v) => setState(() => _fontSize = v),
              ),

              const SizedBox(height: 10),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Font Color'),
                trailing: GestureDetector(
                  onTap: () async {
                    await _pickColor(
                      currentColor: _fontColor,
                      onColorChanged: (c) => setState(() => _fontColor = c),
                      title: 'Choose the font color',
                    );
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _fontColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white24),
                    ),
                  ),
                ),
              ),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Background Color'),
                trailing: GestureDetector(
                  onTap: () async {
                    await _pickColor(
                      currentColor: _bgColor,
                      onColorChanged: (c) => setState(() => _bgColor = c),
                      title: 'Choose the Background Color',
                    );
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _bgColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white24),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide.none,
                        backgroundColor: Color(0xFF0D47A1),
                      ),
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0D47A1),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop({
                          'fontSize': _fontSize,
                          'fontColor': _fontColor.value,
                          'bgColor': _bgColor.value,
                        });
                      },
                      child: const Text(
                        'Save and Apply',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
