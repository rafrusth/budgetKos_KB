import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:budget_kos/shared/models/transaction_model.dart';
import '../../../../core/utils/formatters.dart';
import '../../../transaction/presentation/bloc/transaction_state.dart';
import '../../../transaction/presentation/bloc/transaction_event.dart';

class DashboardCharts extends StatelessWidget {
  final TransactionLoaded state;
  final bool isDesktop;
  final bool isExpanded;

  const DashboardCharts({
    super.key,
    required this.state,
    this.isDesktop = false,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (isDesktop) {
      final child = Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(child: _buildChartCard(theme, isDark, state, ChartFilterType.income, state.totalIncome, true, false, isDesktop: true)),
                const SizedBox(width: 24),
                Expanded(child: _buildChartCard(theme, isDark, state, ChartFilterType.expense, state.totalExpense, false, false, isDesktop: true)),
              ],
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            flex: 1,
            child: _buildChartCard(theme, isDark, state, ChartFilterType.balance, state.balance, false, true, isDesktop: true),
          ),
        ],
      );
      if (isExpanded) return child;
      return SizedBox(
        height: 220,
        child: child,
      );
    } else {
      return SizedBox(
        height: MediaQuery.of(context).size.width * 0.85,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width - 48,
                child: _buildChartCard(theme, isDark, state, ChartFilterType.income, state.totalIncome, true, false, isDesktop: isDesktop),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: MediaQuery.of(context).size.width - 48,
                child: _buildChartCard(theme, isDark, state, ChartFilterType.expense, state.totalExpense, false, false, isDesktop: isDesktop),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: MediaQuery.of(context).size.width - 48,
                child: _buildChartCard(theme, isDark, state, ChartFilterType.balance, state.balance, false, true, isDesktop: isDesktop),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildChartCard(ThemeData theme, bool isDark, TransactionLoaded state, ChartFilterType type, double total, bool isFirst, bool isLast, {bool isDesktop = false}) {
    final chartData = _generateChartData(state.transactions, type);
    final String title = type == ChartFilterType.income ? "Pemasukan" : type == ChartFilterType.expense ? "Pengeluaran" : "Saldo";
    
    double xRange = 0;
    double minY = 0;
    double maxY = 0;
    final isScrollable = chartData.isNotEmpty && (chartData.last.x - chartData.first.x) > 10;
    if (chartData.isNotEmpty) {
      xRange = chartData.last.x - chartData.first.x;
      minY = chartData.map((e) => e.y).reduce((a, b) => a < b ? a : b);
      maxY = chartData.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    }
    final yAxisWidth = type == ChartFilterType.expense ? 55.0 : 45.0;
    if (minY == maxY) {
      minY -= 100;
      maxY += 100;
    }
    final rangeY = maxY - minY;
    final computedMaxY = maxY + (rangeY * 0.2); // 20% headroom
    final computedMinY = minY - (rangeY * 0.1); // 10% bottom room

    Widget getLeftTitles(double value, TitleMeta meta) {
      String text;
      if (value.abs() >= 1000000) {
        text = '${(value / 1000000).toStringAsFixed(1)}Jt';
      } else if (value.abs() >= 1000) {
        text = '${(value / 1000).toStringAsFixed(0)}K';
      } else {
        text = value.toStringAsFixed(0);
      }
      return SideTitleWidget(
        meta: meta,
        child: Text(text, style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: Colors.grey)),
      );
    }

    final mainChartData = LineChartData(
      clipData: const FlClipData.none(), // Prevent FlChart from clipping tooltips
      minY: computedMinY,
      maxY: computedMaxY,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final amountText = 'Rp ${AppFormatters.formatMoney(spot.y)}';
              final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt() * 86400000);
              return LineTooltipItem(
                '$title (${date.day}/${date.month})\n',
                TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12),
                children: [
                  TextSpan(
                    text: amountText,
                    style: TextStyle(
                      color: _getChartColor(theme, type),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.withValues(alpha: 0.1),
          strokeWidth: 1,
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: Colors.grey.withValues(alpha: 0.1),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt() * 86400000);
              return SideTitleWidget(
                meta: meta,
                child: Text("${date.day}/${date.month}", style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: Colors.grey)),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: !isScrollable,
            reservedSize: yAxisWidth,
            getTitlesWidget: getLeftTitles,
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: chartData,
          isCurved: true,
          color: _getChartColor(theme, type),
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                _getChartColor(theme, type).withValues(alpha: 0.5),
                _getChartColor(theme, type).withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );

    final lineChart = LineChart(mainChartData);

    final yAxisOverlay = LineChart(
      LineChartData(
        minY: computedMinY,
        maxY: computedMaxY,
        lineTouchData: const LineTouchData(enabled: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) => const SizedBox.shrink(),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: yAxisWidth,
              getTitlesWidget: getLeftTitles,
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: chartData.isEmpty ? [const FlSpot(0, 0)] : chartData,
            color: Colors.transparent,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );

    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getChartColor(theme, type).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              "Grafik $title",
              style: theme.textTheme.titleSmall?.copyWith(
                color: _getChartColor(theme, type),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 180),
              child: isScrollable 
                  ? _ScrollableChart(
                      chart: lineChart,
                      yAxisOverlay: yAxisOverlay,
                      width: (xRange + 1) * 40.0,
                      yAxisWidth: yAxisWidth,
                    )
                  : lineChart,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total $title', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
              Text('Rp ${AppFormatters.formatMoney(total)}', style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  List<FlSpot> _generateChartData(List<TransactionModel> transactions, ChartFilterType filterType) {
    if (transactions.isEmpty) return [const FlSpot(0, 0)];

    final sortedTx = List<TransactionModel>.from(transactions)..sort((a, b) => a.date.compareTo(b.date));
    
    Map<int, double> groupedData = {};
    double runningBalance = 0;

    for (var tx in sortedTx) {
      final dateObj = tx.date.toLocal();
      final dayStart = DateTime(dateObj.year, dateObj.month, dateObj.day);
      final int dayKey = dayStart.millisecondsSinceEpoch ~/ 86400000;

      if (tx.type == 'income') runningBalance += tx.amount;
      if (tx.type == 'expense') runningBalance -= tx.amount;

      switch (filterType) {
        case ChartFilterType.income:
          if (tx.type == 'income') {
            groupedData[dayKey] = (groupedData[dayKey] ?? 0) + tx.amount;
          } else {
            groupedData.putIfAbsent(dayKey, () => 0);
          }
          break;
        case ChartFilterType.expense:
          if (tx.type == 'expense') {
            groupedData[dayKey] = (groupedData[dayKey] ?? 0) + tx.amount;
          } else {
            groupedData.putIfAbsent(dayKey, () => 0);
          }
          break;
        case ChartFilterType.balance:
          groupedData[dayKey] = runningBalance;
          break;
      }
    }

    List<FlSpot> spots = groupedData.entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    spots.sort((a, b) => a.x.compareTo(b.x));

    if (spots.isEmpty) return [const FlSpot(0, 0)];
    return spots;
  }

  Color _getChartColor(ThemeData theme, ChartFilterType type) {
    switch (type) {
      case ChartFilterType.income: return theme.colorScheme.primary;
      case ChartFilterType.expense: return theme.colorScheme.secondary;
      case ChartFilterType.balance: return theme.colorScheme.tertiary;
    }
  }
}

class _ScrollableChart extends StatefulWidget {
  final Widget chart;
  final Widget yAxisOverlay;
  final double width;
  final double yAxisWidth;

  const _ScrollableChart({
    required this.chart,
    required this.yAxisOverlay,
    required this.width,
    required this.yAxisWidth,
  });

  @override
  State<_ScrollableChart> createState() => _ScrollableChartState();
}

class _ScrollableChartState extends State<_ScrollableChart> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 36.0),
          child: SizedBox(
            width: widget.yAxisWidth,
            child: widget.yAxisOverlay,
          ),
        ),
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: ClipPath(
              clipper: _ChartClipper(),
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: SizedBox(
                  width: widget.width,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 36.0),
                    child: widget.chart,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    // Clip Left and Right strictly to widget bounds to prevent graph lines from overflowing horizontally.
    // Allow infinite overflow on Top and Bottom for tooltips.
    return Path()
      ..addRect(Rect.fromLTRB(0, -1000, size.width, size.height + 1000));
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
