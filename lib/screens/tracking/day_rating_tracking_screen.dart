// lib/screens/tracking/day_rating_tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:chosen/controllers/tracking_controller.dart';
import 'package:chosen/models/day_rating.dart';
import 'package:fl_chart/fl_chart.dart';

class DayRatingTrackingScreen extends StatefulWidget {
  const DayRatingTrackingScreen({super.key});

  @override
  State<DayRatingTrackingScreen> createState() => _DayRatingTrackingScreenState();
}

class _DayRatingTrackingScreenState extends State<DayRatingTrackingScreen> {
  List<DayRating> _ratingHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRatingData();
  }

  Future<void> _loadRatingData() async {
    setState(() => _isLoading = true);
    
    try {
      final ratingHistory = await TrackingController.getDayRatings();
      setState(() {
        _ratingHistory = ratingHistory;
      });
    } catch (e) {
      print('Error loading rating data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddRatingDialog() {
    int? selectedScore;
    final TextEditingController noteController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.sentiment_satisfied, color: Colors.black, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'Ocjeni svoj dan',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Kako je prošao tvoj dan? (1-10)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(10, (index) {
                        final score = index + 1;
                        final isSelected = selectedScore == score;
                        return GestureDetector(
                          onTap: () => setState(() => selectedScore = score),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.black : Colors.transparent,
                              border: Border.all(color: Colors.black),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                score.toString(),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Zašto? (opcionalno)',
                        hintText: 'Kako se osjećaš danas?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Odustani'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: selectedScore != null ? () async {
                            Navigator.of(context).pop();
                            
                            final result = await TrackingController.createDayRating(
                              score: selectedScore,
                              note: noteController.text.isNotEmpty ? noteController.text : null,
                            );
                            
                            if (result != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Ocjena dana je spremljena!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadRatingData();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Greška pri spremanju ocene'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Spremi'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<FlSpot> _getChartData() {
    if (_ratingHistory.isEmpty) return [];
    
    // Sort by date (oldest first for chart)
    final sortedHistory = List<DayRating>.from(_ratingHistory)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return sortedHistory.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), (entry.value.score ?? 0).toDouble());
    }).toList();
  }

  double _getAverageRating() {
    if (_ratingHistory.isEmpty) return 0;
    final validRatings = _ratingHistory.where((r) => r.score != null).toList();
    if (validRatings.isEmpty) return 0;
    final sum = validRatings.fold(0, (sum, rating) => sum + (rating.score ?? 0));
    return sum / validRatings.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Praćenje ocjena dana',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showAddRatingDialog,
            icon: const Icon(Icons.add, color: Colors.black),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.black))
        : RefreshIndicator(
            onRefresh: _loadRatingData,
            color: Colors.black,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCards(),
                  const SizedBox(height: 32),
                  _buildRatingChart(),
                  const SizedBox(height: 32),
                  _buildRatingHistory(),
                ],
              ),
            ),
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRatingDialog,
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatsCards() {
    int? lastRating = _ratingHistory.isNotEmpty && _ratingHistory.first.score != null ? _ratingHistory.first.score : null;
    double averageRating = _getAverageRating();
    
    // Calculate streak of days rated
    int currentStreak = 0;
    for (int i = 0; i < _ratingHistory.length; i++) {
      final rating = _ratingHistory[i];
      if (rating.score != null) {
        currentStreak++;
        // Break if there's a gap of more than 1 day from today
        final daysSinceRating = DateTime.now().difference(rating.createdAt).inDays;
        if (daysSinceRating > i + 1) break;
      } else {
        break;
      }
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Zadnja ocjena',
            lastRating?.toString() ?? '--',
            '/10',
            Icons.sentiment_satisfied,
            _getRatingColor(lastRating),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Prosjek',
            averageRating > 0 ? averageRating.toStringAsFixed(1) : '--',
            '/10',
            Icons.bar_chart,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Ukupno unosa',
            _ratingHistory.length.toString(),
            '',
            Icons.calendar_today,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: unit,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Napredak raspoloženja',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _ratingHistory.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sentiment_neutral, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'Nema podataka o ocjeni',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dodajte svoju prvu ocjenu da vidite grafikon',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey[200]!,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value >= 1 && value <= 10) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: _ratingHistory.length > 7 ? (_ratingHistory.length / 5).floorToDouble() : 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < _ratingHistory.length) {
                              final sortedHistory = List<DayRating>.from(_ratingHistory)
                                ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
                              final date = sortedHistory[index].createdAt;
                              return Text(
                                '${date.day}/${date.month}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        left: BorderSide(color: Colors.grey[300]!),
                        bottom: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    minX: 0,
                    maxX: (_ratingHistory.length - 1).toDouble(),
                    minY: 0,
                    maxY: 10,
                    lineBarsData: [
                      LineChartBarData(
                        spots: _getChartData(),
                        isCurved: true,
                        color: Colors.black,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: _getRatingColor(spot.y.toInt()),
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Povijest ocjena',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            Text(
              '${_ratingHistory.length} unosa',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ratingHistory.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.sentiment_neutral, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Nema ocjena dana',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Počnite pratiti svoje raspoloženje!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _ratingHistory.length,
                itemBuilder: (context, index) {
                  final entry = _ratingHistory[index];
                  final date = entry.createdAt;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _getRatingColor(entry.score).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            _getRatingIcon(entry.score),
                            color: _getRatingColor(entry.score),
                            size: 24,
                          ),
                        ),
                      ),
                      title: Text(
                        'Ocjena: ${entry.score ?? 'N/A'}/10',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '${date.day}/${date.month}/${date.year}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (entry.note != null && entry.note!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                entry.note!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            // TODO: Implement edit functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Funkcija uređivanja uskoro!')),
                            );
                          } else if (value == 'delete') {
                            // TODO: Implement delete functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Funkcija brisanja uskoro!')),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, color: Colors.grey[600], size: 18),
                                const SizedBox(width: 12),
                                const Text('Uredi', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: Colors.red[400], size: 18),
                                const SizedBox(width: 12),
                                Text('Obriši', style: TextStyle(fontSize: 14, color: Colors.red[400])),
                              ],
                            ),
                          ),
                        ],
                        child: Icon(
                          Icons.more_vert,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  Color _getRatingColor(int? score) {
    if (score == null) return Colors.grey;
    if (score >= 8) return Colors.green;
    if (score >= 6) return Colors.orange;
    if (score >= 4) return Colors.yellow[700]!;
    return Colors.red;
  }

  IconData _getRatingIcon(int? score) {
    if (score == null) return Icons.sentiment_neutral;
    if (score >= 8) return Icons.sentiment_very_satisfied;
    if (score >= 6) return Icons.sentiment_satisfied;
    if (score >= 4) return Icons.sentiment_neutral;
    return Icons.sentiment_very_dissatisfied;
  }
}