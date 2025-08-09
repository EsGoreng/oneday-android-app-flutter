import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/timer_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

class ManageHistoryPage extends StatefulWidget {
  const ManageHistoryPage({super.key});

  @override
  State<ManageHistoryPage> createState() => _ManageHistoryPageState();
}

class _ManageHistoryPageState extends State<ManageHistoryPage> {
  final Set<String> _selectedSessionIds = {};

  void _deleteSelected() {
    if (_selectedSessionIds.isEmpty) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Delete Confirmation',
      barrierColor: Colors.black.withValues(alpha: 0.2),
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (context, anim1, anim2, child) {
        // Efek blur pada latar belakang
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5 * anim1.value, sigmaY: 5 * anim1.value),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
      pageBuilder: (context, anim1, anim2) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: StyledCard(
            // Gunakan width agar konsisten dengan dialog lain
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Delete Sessions?', // Judul disesuaikan
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: 'Cancel',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Deskripsi yang lebih informatif
                Text('Are you sure you want to delete ${_selectedSessionIds.length} selected session(s)? This action cannot be undone.'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Asumsi PrimaryButton tersedia dari common_widgets.dart
                    PrimaryButton(
                      text: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    PrimaryButton(
                      text: 'Delete',
                      onPressed: () {
                        // Fungsionalitas inti tetap dipertahankan
                        context
                            .read<TimerProvider>()
                            .deleteSessions(_selectedSessionIds.toList());
                        setState(() {
                          _selectedSessionIds.clear();
                        });
                        Navigator.of(context).pop(); // Tutup dialog
                      },
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
                      // Asumsi customRed tersedia
                      color: customRed,
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double maxWidth = min(MediaQuery.of(context).size.width * 0.9, 540.0);
    final sessions = context.watch<TimerProvider>().completedSessions;

    return Scaffold(
      backgroundColor: customCream,
      body: Stack(
        children: [
          const GridBackground(
              gridSize: 50, lineColor: Color.fromARGB(50, 0, 0, 0)),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      children: [
                        const TopNavigationBar(title: 'Timer History'),
                        const SizedBox(height: 12),
                        StyledCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Session History',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: _selectedSessionIds.isNotEmpty
                                          ? Colors.red.shade700
                                          : Colors.grey,
                                    ),
                                    tooltip: 'Delete Selected',
                                    onPressed: _selectedSessionIds.isNotEmpty
                                        ? _deleteSelected
                                        : null,
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              if (sessions.isEmpty)
                                const Center(
                                    child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 32.0),
                                  child: Text('No history to manage.'),
                                ))
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  itemCount: sessions.length,
                                  itemBuilder: (context, index) {
                                    final session = sessions[index];
                                    final isSelected = _selectedSessionIds
                                        .contains(session.id);
                          
                                    return CheckboxListTile(
                                      contentPadding: EdgeInsets.zero,
                                      dense: false,
                                      value: isSelected,
                                      activeColor: Theme.of(context).primaryColor,
                                      onChanged: (_) {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedSessionIds
                                                .remove(session.id);
                                          } else {
                                            _selectedSessionIds
                                                .add(session.id);
                                          }
                                        });
                                      },
                                      title: Text(session.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                                      subtitle: Text(
                                        '${session.actualDuration.inMinutes} min on ${DateFormat.yMd().format(session.completedAt)}',
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}