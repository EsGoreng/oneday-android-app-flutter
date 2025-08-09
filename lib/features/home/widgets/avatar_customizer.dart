import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:http/http.dart' as http;
import 'package:oneday/core/providers/profile_provider.dart';
import 'package:oneday/shared/widgets/common_widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AvatarCustomizer extends StatefulWidget {
  const AvatarCustomizer({super.key});

  @override
  State<AvatarCustomizer> createState() => _AvatarCustomizerState();
}

class _AvatarCustomizerState extends State<AvatarCustomizer> {
  bool _isDownloading = false;
  String _seed = "Budi";
  double _rotate = 0;
  double _scale = 100;
  bool _flip = false;
  Color _backgroundColor = Colors.transparent;
  Color _clothingColor = Colors.blue;
  Color _skinColor = const Color(0xFFffdbb4); // Warna kulit default
  final TextEditingController _seedController = TextEditingController();
  String? _selectedFace;
  String? _selectedHead;
  String? _selectedFacialHair;
  String? _selectedClothing;
  String? _selectedAccessories;
  double _accessoriesProbability = 100;
  double _facialHairProbability = 100;

  final List<String> _headOptions = ['afro', 'bangs', 'bangs2', 'bantuKnots', 'bear', 'bun', 'bun2', 'buns', 'cornrows', 'cornrows2', 'dreads1', 'dreads2', 'flatTop', 'flatTopLong', 'grayBun', 'grayMedium', 'grayShort', 'hatBeanie', 'hatHip', 'hijab', 'long', 'longAfro', 'longBangs', 'longCurly', 'medium1', 'medium2', 'medium3', 'mediumBangs', 'mediumBangs2', 'mediumBangs3', 'mediumStraight', 'mohawk', 'mohawk2', 'noHair1', 'noHair2', 'noHair3', 'pomp', 'shaved1', 'shaved2', 'shaved3', 'short1', 'short2', 'short3', 'short4', 'short5', 'turban', 'twists', 'twists2'];
  final List<String> _faceOptions = ['angryWithFang', 'awe', 'blank', 'calm', 'cheeky', 'concerned', 'concernedFear', 'contempt', 'cute', 'cyclops', 'driven', 'eatingHappy', 'explaining', 'eyesClosed', 'fear', 'hectic', 'lovingGrin1', 'lovingGrin2', 'monster', 'old', 'rage', 'serious', 'smile', 'smileBig', 'smileLOL', 'smileTeethGap', 'solemn', 'suspicious', 'tired', 'veryAngry'];
  final List<String> _facialHairOptions = ['chin', 'full', 'full2', 'full3', 'full4', 'goatee1', 'goatee2', 'moustache1', 'moustache2', 'moustache3', 'moustache4', 'moustache5', 'moustache6', 'moustache7', 'moustache8', 'moustache9'];
  final List<String> _accessoriesOptions = ['eyepatch', 'glasses', 'glasses2', 'glasses3', 'glasses4', 'glasses5', 'sunglasses', 'sunglasses2'];
  
  // List baru untuk opsi warna kulit
  final List<Color> _skinColorOptions = [
    const Color(0xFF694d3d),
    const Color(0xFFae5d29),
    const Color(0xFFd08b5b),
    const Color(0xFFedb98a),
    const Color(0xFFffdbb4),
  ];


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final initialSeed = context.read<ProfileProvider>().userName;
        setState(() {
          _seed = initialSeed.isNotEmpty ? initialSeed : 'Default';
          _seedController.text = _seed;
        });
      }
    });
  }

  String _buildAvatarUrl() {
    String baseUrl = "https://api.dicebear.com/9.x/open-peeps/svg";
    String colorToHex(Color color) {return color.value.toRadixString(16).padLeft(8, '0').substring(2);}
    Map<String, String> queryParams = {
      'seed': _seed,
      'rotate': _rotate.toInt().toString(),
      'scale': _scale.toInt().toString(),
      'flip': _flip.toString(),
      'skinColor': colorToHex(_skinColor), // Tambahkan parameter warna kulit
    };
    if (_backgroundColor.value != Colors.transparent.value) {queryParams['backgroundColor'] = colorToHex(_backgroundColor);}
    queryParams['clothingColor'] = colorToHex(_clothingColor);
    void addQuery(String key, String? value) {if (value != null && value.isNotEmpty) {queryParams[key] = value;}}
    addQuery('head', _selectedHead);
    addQuery('face', _selectedFace);
    addQuery('clothing', _selectedClothing);
    if (_selectedFacialHair != null && _selectedFacialHair!.isNotEmpty) {addQuery('facialHair', _selectedFacialHair);queryParams['facialHairProbability'] = _facialHairProbability.toInt().toString();}
    if (_selectedAccessories != null && _selectedAccessories!.isNotEmpty) {addQuery('accessories', _selectedAccessories);queryParams['accessoriesProbability'] = _accessoriesProbability.toInt().toString();}
    Uri uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
    return uri.toString();
  }
  
  Future<void> _saveAvatarFromUrl() async {
    setState(() {
      _isDownloading = true;
    });
    var status = await Permission.photos.request();
    if (status.isPermanentlyDenied) {
       await openAppSettings();
    }
    if (!status.isGranted) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Storage permission is required to save avatars.')));
      setState(() { _isDownloading = false; });
      return;
    }
    
    try {
      final url = _buildAvatarUrl();
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Gagal mengunduh SVG dari server.');
      }
      final svgString = response.body;
      final pictureInfo = await vg.loadPicture(SvgStringLoader(svgString), null);
      final image = await pictureInfo.picture.toImage(pictureInfo.size.width.toInt(), pictureInfo.size.height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.png').create();
      await file.writeAsBytes(pngBytes);
      await GallerySaver.saveImage(file.path, albumName: "OneDay Avatars");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar succesfully saved to Gallery! ✨'), backgroundColor: Colors.green,));

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to Save avatar: $e'), backgroundColor: Colors.red,));
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StyledCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Avatar Maker', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              InkWell(
                onTap: () => launchUrl(Uri.parse('https://www.dicebear.com/playground/?style=open-peeps')),
                child: const Text('DiceBear Playground', style: TextStyle(fontSize: 12, color: Colors.blue, decoration: TextDecoration.underline)),
              ),
            ],
          ),
          const Divider(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16), border: Border.all()),
            child: SvgPicture.network(
              _buildAvatarUrl(),
              key: ValueKey(_buildAvatarUrl()),
              placeholderBuilder: (context) => const CircularProgressIndicator(),
              width: 150,
              height: 150,
              errorBuilder: (context, error, stackTrace) => const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 40),
                  SizedBox(height: 8),
                  Text('Kombinasi Opsi Tidak Valid', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _seedController,
            decoration: const InputDecoration(labelText: 'Seed (ID Unik)', border: OutlineInputBorder()),
            onChanged: (value) => setState(() => _seed = value.isEmpty ? 'default' : value),
          ),
          const SizedBox(height: 12),
          _buildDropdown('Head', _selectedHead, _headOptions, (val) => setState(() => _selectedHead = val)),
          const SizedBox(height: 12),
          _buildDropdown('Face', _selectedFace, _faceOptions, (val) => setState(() => _selectedFace = val)),
          const SizedBox(height: 12),
          _buildDropdown('Facial Hair', _selectedFacialHair, _facialHairOptions, (val) => setState(() => _selectedFacialHair = val)),
          const SizedBox(height: 12),
          _buildSlider('Facial Hair Probability', _facialHairProbability, 0, 100, (val) => setState(() => _facialHairProbability = val)),
          const SizedBox(height: 12),
          _buildDropdown('Accessories', _selectedAccessories, _accessoriesOptions, (val) => setState(() => _selectedAccessories = val)),
          const SizedBox(height: 12),
          _buildSlider('Accessories Probability', _accessoriesProbability, 0, 100, (val) => setState(() => _accessoriesProbability = val)),
          const Divider(height: 12),
          SwitchListTile(title: const Text('Flip'), value: _flip, onChanged: (val) => setState(() => _flip = val)),
          const Divider(),
          _buildSlider('Scale', _scale, 50, 150, (val) => setState(() => _scale = val)),
          const SizedBox(height: 12),
          _buildSlider('Rotate', _rotate, 0, 360, (val) => setState(() => _rotate = val)),
          ListTile(title: const Text('Background Color'), trailing: CircleAvatar(backgroundColor: _backgroundColor), onTap: () => _pickColor(true)),
          ListTile(title: const Text('Clothing Color'), trailing: CircleAvatar(backgroundColor: _clothingColor), onTap: () => _pickColor(false)),
          
          // ## UI BARU UNTUK MEMILIH WARNA KULIT ##
          const Divider(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Skin Color', style: TextStyle(fontSize: 16)),
          ),
          Wrap(
            spacing: 12.0,
            runSpacing: 8.0,
            children: _skinColorOptions.map((color) {
              return GestureDetector(
                onTap: () => setState(() => _skinColor = color),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _skinColor == color ? Colors.blue : Colors.grey.shade300,
                      width: _skinColor == color ? 3 : 1,
                    ),
                  ),
                  child: _skinColor == color
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
          // ## AKHIR DARI UI WARNA KULIT ##

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  text: 'Save Avatar',
                  padding: const EdgeInsets.all(8),
                  color: customGreen,
                  onPressed: _isDownloading ? null : _saveAvatarFromUrl, 
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  text: 'Apply Avatar',
                  padding: const EdgeInsets.all(8),
                  onPressed: () async {
                    final profileProvider = context.read<ProfileProvider>();
                    final finalUrl = _buildAvatarUrl();
                    try {
                      await profileProvider.setProfilePicture(finalUrl);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar Updated!'), backgroundColor: Colors.green));
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to Update avatar: $e'), backgroundColor: Colors.red));
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toInt()}%'),
        Slider(value: value, min: min, max: max, divisions: (max - min).toInt(), label: '${value.round()}%', onChanged: onChanged),
      ],
    );
  }

  Widget _buildDropdown(String label, String? currentValue, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      value: currentValue,
      hint: Text('Pilih $label'),
      isExpanded: true,
      items: [
        const DropdownMenuItem<String>(value: null, child: Text('Default')),
        ...items.map((item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
      ],
      onChanged: onChanged,
    );
  }

  void _pickColor(bool isBackground) async {
    final initialColor = isBackground ? _backgroundColor : _clothingColor;
    Color? pickedColor = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isBackground ? 'Pilih Warna Background' : 'Pilih Warna Pakaian'),
        content: SingleChildScrollView(child: BlockPicker(pickerColor: initialColor, onColorChanged: (color) => Navigator.of(context).pop(color))),
      ),
    );
    if (pickedColor != null) {
      setState(() {
        if (isBackground) { _backgroundColor = pickedColor; } 
        else { _clothingColor = pickedColor; }
      });
    }
  }

  @override
  void dispose() {
    _seedController.dispose();
    super.dispose();
  }
}

class BlockPicker extends StatelessWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;
  const BlockPicker({super.key, required this.pickerColor, required this.onColorChanged});

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = [Colors.red, Colors.pink, Colors.purple, Colors.deepPurple, Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan, Colors.teal, Colors.green, Colors.lightGreen, Colors.lime, Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange, Colors.brown, Colors.grey, Colors.blueGrey, Colors.black, Colors.white, Colors.transparent];
    return Wrap(spacing: 8, runSpacing: 8, children: colors.map((color) => GestureDetector(onTap: () => onColorChanged(color), child: Container(width: 40, height: 40, decoration: BoxDecoration(color: color, border: Border.all(color: Colors.grey.shade300), shape: BoxShape.circle)))).toList());
  }
}