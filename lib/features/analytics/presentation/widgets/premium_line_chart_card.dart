import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import 'dart:math';

class PremiumLineChartCard extends StatefulWidget {
  final String title;
  final List<FlSpot> dataSpots;
  final List<String> xLabels;
  final String primaryMetricLabel;
  final Color chartColor;
  final String selectedFilter;
  final ValueChanged<String>? onFilterChanged;

  const PremiumLineChartCard({
    super.key,
    required this.title,
    required this.dataSpots,
    required this.xLabels,
    required this.primaryMetricLabel,
    required this.selectedFilter,
    this.chartColor = Colors.green, // FreshGa Green default
    this.onFilterChanged,
  });

  @override
  State<PremiumLineChartCard> createState() => _PremiumLineChartCardState();
}

class _PremiumLineChartCardState extends State<PremiumLineChartCard> with SingleTickerProviderStateMixin {
  final List<String> _filters = ['Today', '7D', '30D', '90D', 'All'];
  
  // To handle the load animation
  bool _isLoaded = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _isLoaded = true);
    });

    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 4.0, end: 12.0).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dataSpots.isEmpty) {
      return _buildEmptyState();
    }

    final double highestValue = widget.dataSpots.map((e) => e.y).reduce(max);
    final double lowestValue = widget.dataSpots.map((e) => e.y).reduce(min);
    final double averageValue = widget.dataSpots.map((e) => e.y).reduce((a, b) => a + b) / widget.dataSpots.length;
    final int latestIndex = widget.dataSpots.length - 1;

    // We animate the data array from 0s for the load-in effect
    final displayedSpots = _isLoaded 
        ? widget.dataSpots 
        : widget.dataSpots.map((e) => FlSpot(e.x, 0)).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey200.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          SizedBox(
            height: 240,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: highestValue / 4 == 0 ? 1 : highestValue / 4,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.withOpacity(0.15),
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: widget.xLabels.length > 7 ? (widget.xLabels.length / 5).ceilToDouble() : 1,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 && value.toInt() < widget.xLabels.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: Text(widget.xLabels[value.toInt()], style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                              );
                            }
                            return const Text('');
                          },
                          reservedSize: 32,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: highestValue / 4 == 0 ? 1 : highestValue / 4,
                          getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          reservedSize: 40,
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    clipData: const FlClipData.none(),
                    minX: 0,
                    maxX: widget.dataSpots.length.toDouble() - 1,
                    minY: 0,
                    maxY: highestValue * 1.2,
                    lineBarsData: [
                      LineChartBarData(
                        spots: displayedSpots,
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: widget.chartColor,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        isStrokeJoinRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              widget.chartColor.withOpacity(0.25),
                              widget.chartColor.withOpacity(0.12),
                              widget.chartColor.withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) => Colors.black.withOpacity(0.8),
                        tooltipRoundedRadius: 12,
                        tooltipPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) => LineTooltipItem(
                            '${widget.xLabels[spot.x.toInt()]}\n',
                            const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                            children: [
                              TextSpan(
                                text: '${spot.y.toInt()} ${widget.primaryMetricLabel}',
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          )).toList();
                        },
                      ),
                      getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                        return spotIndexes.map((index) {
                          return TouchedSpotIndicatorData(
                            const FlLine(color: Colors.grey, strokeWidth: 1.5, dashArray: [4, 4]),
                            FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                radius: 6,
                                color: widget.chartColor,
                                strokeWidth: 4,
                                strokeColor: widget.chartColor.withOpacity(0.3),
                              ),
                            ),
                          );
                        }).toList();
                      },
                      handleBuiltInTouches: true,
                    ),
                  ),
                );
              }
            ),
          ),
          _buildStatisticsRow(highestValue, averageValue, lowestValue),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _buildSegmentedControl(),
        ),
      ],
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey200.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _filters.map((filter) {
          final isSelected = widget.selectedFilter == filter;
          return GestureDetector(
            onTap: () {
              if (widget.onFilterChanged != null) {
                widget.onFilterChanged!(filter);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuint,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                boxShadow: isSelected ? [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                ] : [],
              ),
              child: Text(
                filter,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatisticsRow(double highest, double average, double lowest) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatChip('Highest', highest.toInt().toString()),
        _buildStatChip('Average', average.toInt().toString()),
        _buildStatChip('Lowest', lowest.toInt().toString()),
        _buildStatChip('Growth', '+18.6%', isTrend: true),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, {bool isTrend = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isTrend ? Colors.green.shade700 : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey200.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Icon(Icons.insights_rounded, size: 64, color: AppColors.grey200),
          const SizedBox(height: 16),
          const Text('No analytics available yet.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Complete your first order to start seeing insights.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
