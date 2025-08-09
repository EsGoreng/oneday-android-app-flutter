import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/providers/profile_provider.dart';

const customRed = Color(0xFFFF5F5F);
const customDarkRed = Color.fromARGB(255, 75, 16, 16);
const customGreen = Color(0XFF4CFE78);
const customDarkGreen = Color.fromARGB(255, 34, 123, 56);
const customYellow = Color(0xffffbf00);
const customCream = Color(0xfffef3c8);
const customPink = Color(0xFFFF97D9);

class StyledBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const StyledBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final double maxWidth = min(MediaQuery.of(context).size.width * 0.9, 540.0);

    return Container(
      width: maxWidth,
      margin: const EdgeInsets.all(18),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(4, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavBarItem(
            icon: Icons.sentiment_very_satisfied_rounded,
            label: 'Mood',
            isSelected: selectedIndex == 0,
            onTap: () => onItemTapped(0),
          ),
          const SizedBox(width: 8),
          _NavBarItem(
            icon: Icons.repeat_outlined,
            label: 'Habit',
            isSelected: selectedIndex == 1,
            onTap: () => onItemTapped(1),
          ),
          const SizedBox(width: 8),
          _NavBarItem(
            icon: Icons.attach_money_outlined,
            label: 'Finance',
            isSelected: selectedIndex == 2,
            onTap: () => onItemTapped(2),
          ),
          const SizedBox(width: 8),
          _NavBarItem(
            icon: Icons.home_outlined,
            label: 'Home',
            isSelected: selectedIndex == 3,
            onTap: () => onItemTapped(3),
          ),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Offset shadowOffset = widget.isSelected ? const Offset(2, 2) : const Offset(4, 4);
    final Color backgroundColor = widget.isSelected ? const Color(0xFFFFD000) : const Color(0xff4c6efe);
    final Color contentColor = Colors.black;

    return Expanded(
      child: GestureDetector(
        onTapDown: (_) {
          _controller.forward();
        },
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () {
          _controller.reverse();
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  offset: shadowOffset,
                  blurRadius: 0,
                ),
              ],
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, color: contentColor, size: 20),
                  if (widget.isSelected) ...[
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: contentColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GridBackground extends StatelessWidget {
  final double gridSize;
  final Color lineColor;
  const GridBackground({super.key, this.gridSize = 50.0, required this.lineColor});
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _GridPainter(gridSize, lineColor), child: Container());
}

class _GridPainter extends CustomPainter {
  final double gridSize;
  final Color lineColor;
  _GridPainter(this.gridSize, this.lineColor);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = lineColor;
    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StyledCard extends StatelessWidget {
  final Widget child;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  const StyledCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.height,
    this.width,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,

      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        border: Border.all(color: Colors.black, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

class OutlineText extends StatelessWidget {
  final Text child;
  final double strokeWidth;
  final Color? strokeColor;
  final TextOverflow? overflow;
  const OutlineText({super.key, required this.child, this.strokeWidth = 2, this.strokeColor, this.overflow});
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          child.data!,
          style: TextStyle(
            fontSize: child.style?.fontSize,
            fontWeight: child.style?.fontWeight,
            letterSpacing: 1,
            foreground: Paint()
              ..color = strokeColor ?? Theme.of(context).shadowColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth,
          ),
          overflow: overflow,
        ),
        child
      ],
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Hapus semua karakter non-digit
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (newText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Parse angka yang sudah bersih
    double number = double.parse(newText);
    
    // Format angka dengan pemisah ribuan (koma)
    final formatter = NumberFormat('#,###');
    String formattedText = formatter.format(number);

    // Kembalikan nilai baru dengan teks yang diformat dan kursor di akhir
    return newValue.copyWith(
        text: formattedText,
        selection: TextSelection.collapsed(offset: formattedText.length));
  }
}

class CustomTextField extends StatelessWidget {
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final String? prefix;
  final List<TextInputFormatter>? inputFormatters;
  final IconButton? suffixButton;

  const CustomTextField({
    this.suffixButton,
    this.prefix,
    super.key,
    this.keyboardType,
    this.validator,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      inputFormatters: inputFormatters,
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        suffixIcon: suffixButton,
        prefixText: prefix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.black),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.black),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

class PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final Widget? icon;
  final EdgeInsets? padding;
  final bool isSelected; // Tambahkan properti ini

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = customYellow,
    this.textColor = Colors.black,
    this.icon,
    this.padding,
    this.isSelected = false, // Defaultnya false
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Tentukan offset bayangan berdasarkan state isPressed atau isSelected
    final Offset shadowOffset = _isPressed || widget.isSelected ? const Offset(2, 2) : const Offset(4, 4);

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
        widget.onPressed!(
        );
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      child: AnimatedContainer(
        padding: widget.padding,
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              offset: shadowOffset,
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                widget.icon!,
                const SizedBox(width: 8),
              ],
              Text(
                widget.text,
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeAppBar extends StatefulWidget {
  const HomeAppBar({
    super.key,
    required this.profileProvider,
  });

  final ProfileProvider profileProvider;

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();
}

class _HomeAppBarState extends State<HomeAppBar> {

  @override
  Widget build(BuildContext context) {

    final profileProvider = Provider.of<ProfileProvider>(context);

    final String avatarUrl = profileProvider.profilePicturePath;
    final bool isSvg =
        avatarUrl.contains('api.dicebear.com') || avatarUrl.endsWith('.svg');

    return StyledCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            profileProvider.userName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all()
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade300,
                child: ClipOval(
                  child: isSvg
                      ? SvgPicture.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          width: 65,
                          height: 65,
                          placeholderBuilder: (_) =>
                              const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          width: 65,
                          height: 65,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.person, size: 40, color: Colors.white),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class StyledTopNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const StyledTopNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> labels = ['Calendar', 'Daily', 'Monthly', 'Budget', 'Note'];

    return StyledCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final double tabWidth = constraints.maxWidth / labels.length;
              final double indicatorPosition = selectedIndex * tabWidth;

              return SizedBox(
                height: 30,
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      left: indicatorPosition,
                      child: Container(
                        width: tabWidth,
                        height: 30,
                        decoration: BoxDecoration(
                          color: customGreen,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.black),
                        ),
                      ),
                    ),
                    
                    Row(
                      children: List.generate(labels.length, (index) {
                        return _TopNavBarItem(
                          label: labels[index],
                          isSelected: selectedIndex == index,
                          onTap: () => onItemTapped(index),
                        );
                      }),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          )
        ],
      ),
    );
  }
}

class _TopNavBarItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TopNavBarItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Tentukan gaya teks berdasarkan status isSelected
    final FontWeight fontWeight = isSelected ? FontWeight.bold : FontWeight.normal;
    final double fontSize = isSelected ? 12 : 10;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: Colors.transparent,
          height: 30,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              
              style: DefaultTextStyle.of(context).style.merge(
                TextStyle(
                  fontWeight: fontWeight,
                  fontSize: fontSize,
                ),
              ),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TopNavigationBar extends StatelessWidget {

  final String title;
  final VoidCallback? onEditPressed;
  final IconData? actionIcon;

  const TopNavigationBar({
    super.key, 
    required this.title,
    this.onEditPressed,
    this.actionIcon,
    });

  @override
  Widget build(BuildContext context) {
    return StyledCard(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          if (actionIcon != null && onEditPressed != null) 
            IconButton(
              icon: Icon(actionIcon),
              onPressed: onEditPressed,
            )
          else
            const SizedBox(width: 48,),
        ],
      ),
    );
  }
}

class IconButtonHelper extends StatelessWidget {
  const IconButtonHelper({
    super.key,
    required this.icon,
    required this.label,
    required this.ontap,
  });

  final Function()? ontap;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Material(
        shape: RoundedRectangleBorder(side: BorderSide(), borderRadius: BorderRadiusGeometry.circular(8)),
        color: customYellow, // button color
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: ontap, // button pressed
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 20), // icon
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)), // text
            ],
          ),
        ),
      ),
    );
  }
}

class IconButtonHelper2 extends StatelessWidget {
  const IconButtonHelper2({
    super.key,
    required this.icon,
    required this.label,
    required this.ontap,
  });

  final Function()? ontap;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: RoundedRectangleBorder(side: BorderSide(), borderRadius: BorderRadiusGeometry.circular(8)),
      color: customYellow, // button color
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: ontap, // button pressed
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Icon(icon, size: 20), // icon
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)), // text
            ],
          ),
        ),
      ),
    );
  }
}

