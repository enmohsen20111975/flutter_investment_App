// ============================================================================
// مساعد الاستثمار Flutter - Price Chart Widget
// Native Flutter chart using fl_chart (LineChart + AreaChart + Candlestick)
// ============================================================================

import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/chart_data_model.dart';
import '../theme/colors.dart';

enum ChartType { line, area, candle }

class PriceChart extends StatelessWidget {
  final List<ChartDataModel> data;
  final ChartType type;
  final Color? lineColor;
  final Color? fillColor;
  final bool showVolume;
  final bool showGrid;
  final String? title;

  const PriceChart({
    super.key,
    required this.data,
    this.type = ChartType.line,
    this.lineColor,
    this.fillColor,
    this.showVolume = true,
    this.showGrid = true,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.show_chart_rounded, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text('لا توجد بيانات للرسم', style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(title!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Cairo')),
          ),
        AspectRatio(
          aspectRatio: 1.6,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: type == ChartType.candle
                ? _buildCandlestickChart()
                : (type == ChartType.area ? _buildAreaChart() : _buildLineChart()),
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart() {
    final color = lineColor ?? AppColors.chartUp;
    final gradient = fillColor != null
        ? LinearGradient(
            colors: [fillColor!.withValues(alpha: 0.3), fillColor!.withValues(alpha: 0.0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : const LinearGradient(
            colors: [Color(0x4D22C55E), Color(0x0022C55E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    final spots = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      final close = data[i].close;
      if (close != null) {
        spots.add(FlSpot(i.toDouble(), close));
      }
    }

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: color,
            barWidth: 2,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              gradient: gradient,
            ),
            dotData: const FlDotData(show: false),
          ),
        ],
        minY: _getMinY(),
        maxY: _getMaxY(),
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: showGrid,
          drawVerticalLine: false,
          horizontalInterval: _getGridInterval(),
          getDrawingHorizontalLine: (value) {
            return FlLine(color: AppColors.border.withValues(alpha: 0.3), strokeWidth: 0.5);
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: _getBottomTitleInterval(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  final date = data[index].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _formatDate(date),
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: _getGridInterval(),
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatPrice(value),
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildAreaChart() {
    final color = lineColor ?? AppColors.chartUp;
    final gradient = fillColor != null
        ? LinearGradient(
            colors: [fillColor!.withValues(alpha: 0.4), fillColor!.withValues(alpha: 0.0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : const LinearGradient(
            colors: [Color(0x66F97316), Color(0x00F97316)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    final spots = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      final close = data[i].close;
      if (close != null) {
        spots.add(FlSpot(i.toDouble(), close));
      }
    }

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              gradient: gradient,
            ),
            dotData: const FlDotData(show: false),
          ),
        ],
        minY: _getMinY(),
        maxY: _getMaxY(),
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: showGrid,
          drawVerticalLine: false,
          horizontalInterval: _getGridInterval(),
          getDrawingHorizontalLine: (value) {
            return FlLine(color: AppColors.border.withValues(alpha: 0.3), strokeWidth: 0.5);
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: _getBottomTitleInterval(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  final date = data[index].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _formatDate(date),
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: _getGridInterval(),
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatPrice(value),
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildCandlestickChart() {
    final candleGroups = <BarChartGroupData>[];
    for (var i = 0; i < data.length; i++) {
      final item = data[i];
      if (item.open != null && item.high != null && item.low != null && item.close != null) {
        final isUp = item.close! >= item.open!;
        final color = isUp ? AppColors.chartUp : AppColors.chartDown;

        candleGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                fromY: item.low!,
                toY: item.high!,
                color: AppColors.textMuted.withValues(alpha: 0.4),
                width: 1,
              ),
              BarChartRodData(
                fromY: math.min(item.open!, item.close!),
                toY: math.max(item.open!, item.close!),
                color: color,
                width: 4,
              ),
            ],
          ),
        );
      }
    }

    return BarChart(
      BarChartData(
        barGroups: candleGroups,
        minY: _getMinY(),
        maxY: _getMaxY(),
        gridData: FlGridData(
          show: showGrid,
          drawVerticalLine: false,
          horizontalInterval: _getGridInterval(),
          getDrawingHorizontalLine: (value) {
            return FlLine(color: AppColors.border.withValues(alpha: 0.3), strokeWidth: 0.5);
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: _getBottomTitleInterval(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_formatDate(data[index].date), style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: _getGridInterval(),
              getTitlesWidget: (value, meta) {
                return Text(_formatPrice(value), style: const TextStyle(fontSize: 10, color: AppColors.textMuted));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  double _getMinY() {
    if (data.isEmpty) return 0;
    final lows = data.map((e) => e.low).whereType<double>().toList();
    if (lows.isEmpty) return 0;
    final min = lows.reduce((a, b) => a < b ? a : b);
    final max = _getMaxY();
    final range = max - min;
    return min - (range * 0.1);
  }

  double _getMaxY() {
    if (data.isEmpty) return 100;
    final highs = data.map((e) => e.high).whereType<double>().toList();
    final closes = data.map((e) => e.close).whereType<double>().toList();
    final all = <double>[...highs, ...closes];
    if (all.isEmpty) return 100;
    final max = all.reduce((a, b) => a > b ? a : b);
    return max * 1.02;
  }

  double _getGridInterval() {
    final range = _getMaxY() - _getMinY();
    if (range <= 0) return 1;
    final raw = range / 5;
    var magnitude = 1.0;
    while (magnitude * 10 < raw) magnitude *= 10;
    while (magnitude > raw) magnitude /= 10;
    final residual = raw / magnitude;
    if (residual <= 1.5) return magnitude;
    if (residual <= 3.5) return 2 * magnitude;
    if (residual <= 7.5) return 5 * magnitude;
    return 10 * magnitude;
  }

  double _getBottomTitleInterval() {
    if (data.length <= 7) return 1;
    if (data.length <= 30) return (data.length / 6).ceilToDouble();
    return (data.length / 8).ceilToDouble();
  }

  String _formatPrice(double? value) {
    if (value == null) return '';
    if (value >= 1000) return value.toStringAsFixed(0);
    if (value >= 1) return value.toStringAsFixed(2);
    return value.toStringAsFixed(4);
  }

  String _formatDate(String date) {
    if (date.isEmpty) return '';
    if (date.length >= 10) return date.substring(5, 10);
    return date;
  }
}
