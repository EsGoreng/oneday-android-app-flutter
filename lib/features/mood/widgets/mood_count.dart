import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/mood_models.dart';
import '../../../core/providers/mood_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

class MoodCount extends StatelessWidget {
  const MoodCount({super.key});

  @override
  Widget build(BuildContext context) {
    // Menggunakan Consumer untuk mendapatkan data dari MoodProvider
    return Consumer<MoodProvider>(
      builder: (context, moodProvider, child) {
        // Menghitung jumlah setiap kategori mood
        final moodCounts = <MoodCategory, int>{};
        for (var mood in moodProvider.moods) {
          moodCounts[mood.moodCategory] = (moodCounts[mood.moodCategory] ?? 0) + 1;
        }

        return StyledCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mood Count',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ...MoodCategory.values.map((category) {
                    final count = moodCounts[category] ?? 0;
                    return _MoodCountDetailRow(
                      imagePath: category.imagePath,
                      moodName: category.moodName,
                      count: count,
                    );
                  }),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// Widget private untuk menampilkan detail baris hitungan mood
class _MoodCountDetailRow extends StatelessWidget {
  final String imagePath;
  final String moodName;
  final int count;

  const _MoodCountDetailRow({
    required this.imagePath,
    required this.moodName,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Image.asset(
            imagePath,
            width: 30,
            height: 30,
          ),
          SizedBox(height: 4),
          Text(
            '$count',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            moodName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}