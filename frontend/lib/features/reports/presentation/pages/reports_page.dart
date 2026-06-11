import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../transaction/presentation/bloc/transaction_bloc.dart';
import '../../../transaction/presentation/bloc/transaction_state.dart';
import '../../../transaction/presentation/bloc/transaction_event.dart';
import '../../../transaction/data/models/transaction_model.dart';
import '../../../transaction/data/models/category_model.dart';
import '../../../transaction/presentation/widgets/transaction_bottom_sheet.dart' as import_transaction_sheet;

enum ChartType { pie, bar, line }
enum TimeFilter { all, today, week, month, custom }
enum SortOrder { newest, oldest, highest, lowest }

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  ChartType _selectedChart = ChartType.pie;
  int _touchedPieIndex = -1;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isFirstLoad = false;
        });
      }
    });
  }
  
  // Filter states
  TimeFilter _timeFilter = TimeFilter.all;
  DateTimeRange? _customDateRange;
  int? _filterCategoryId; // null = All
  SortOrder _sortOrder = SortOrder.newest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text("Laporan Keuangan", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TransactionLoaded) {
            if (_isFirstLoad) {
              return const Center(child: CircularProgressIndicator());
            }
            return _buildContent(context, state, isDark);
          } else if (state is TransactionError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox();
        },
      ),
    );
  }

  // LOGIC FILTER
  List<TransactionModel> _getFilteredTransactions(List<TransactionModel> rawList) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    List<TransactionModel> filtered = rawList.where((tx) {
      // Waktu
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      if (_timeFilter == TimeFilter.today) {
        if (txDate != today) return false;
      } else if (_timeFilter == TimeFilter.week) {
        if (txDate.isBefore(startOfWeek)) return false;
      } else if (_timeFilter == TimeFilter.month) {
        if (txDate.isBefore(startOfMonth)) return false;
      } else if (_timeFilter == TimeFilter.custom && _customDateRange != null) {
        final start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
        final end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day);
        if (txDate.isBefore(start) || txDate.isAfter(end)) return false;
      }

      // Kategori
      if (_filterCategoryId != null && tx.categoryId != _filterCategoryId) {
        return false;
      }

      return true;
    }).toList();

    // Sortir
    filtered.sort((a, b) {
      switch (_sortOrder) {
        case SortOrder.newest:
          return b.date.compareTo(a.date);
        case SortOrder.oldest:
          return a.date.compareTo(b.date);
        case SortOrder.highest:
          return b.amount.compareTo(a.amount);
        case SortOrder.lowest:
          return a.amount.compareTo(b.amount);
      }
    });

    return filtered;
  }

  Widget _buildContent(BuildContext context, TransactionLoaded state, bool isDark) {
    final theme = Theme.of(context);
    
    // Process Filter ONLY for the transaction list
    final listFiltered = _getFilteredTransactions(state.transactions);
    
    // Charts use UNFILTERED data (or globally loaded data)
    final expenseTxForChart = state.transactions.where((tx) => tx.type == 'expense').toList();
    
    // Group by category for Pie and Bar charts (Only uses Expense data)
    Map<String, double> rawCategoryTotals = {};
    double totalExpense = 0;
    for (var tx in expenseTxForChart) {
      final catName = tx.category?.name ?? 'Lainnya';
      rawCategoryTotals[catName] = (rawCategoryTotals[catName] ?? 0) + tx.amount;
      totalExpense += tx.amount;
    }

    // Sort to get top 5
    var sortedCats = rawCategoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    List<String> topCats = sortedCats.take(5).map((e) => e.key).toList();
    
    Map<String, double> categoryTotals = {};
    double othersTotal = 0;
    for (var entry in sortedCats) {
      if (topCats.contains(entry.key)) {
        categoryTotals[entry.key] = entry.value;
      } else {
        othersTotal += entry.value;
      }
    }
    if (othersTotal > 0) {
      categoryTotals['Lainnya'] = (categoryTotals['Lainnya'] ?? 0) + othersTotal;
    }

    final List<Widget> legendWidgets = [];
    final colors = [
      Colors.redAccent, Colors.blueAccent, Colors.orangeAccent, 
      Colors.purpleAccent, Colors.teal, Colors.pinkAccent, Colors.indigo,
    ];

    int colorIndex = 0;
    categoryTotals.forEach((name, amount) {
      final color = colors[colorIndex % colors.length];
      legendWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
              Text('Rp ${_formatMoney(amount)}', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        )
      );
      colorIndex++;
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Distribusi Pengeluaran", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SegmentedButton<ChartType>(
                segments: const [
                  ButtonSegment(value: ChartType.pie, icon: Icon(Icons.pie_chart)),
                  ButtonSegment(value: ChartType.bar, icon: Icon(Icons.bar_chart)),
                  ButtonSegment(value: ChartType.line, icon: Icon(Icons.show_chart)),
                ],
                selected: {_selectedChart},
                onSelectionChanged: (Set<ChartType> newSelection) {
                  setState(() {
                    _selectedChart = newSelection.first;
                  });
                },
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (expenseTxForChart.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text("Belum ada pengeluaran", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ))
          else ...[
            SizedBox(
              height: 250,
              child: _buildChart(categoryTotals, expenseTxForChart, colors, totalExpense),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(children: legendWidgets),
            ),
          ],
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Daftar Transaksi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _showFilterBottomSheet(context),
                icon: const Icon(Icons.filter_list, size: 18),
                label: const Text("Filter & Urutkan"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  foregroundColor: theme.colorScheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAllTransactions(listFiltered, theme), // Pass ONLY listFiltered here
        ],
      ),
    );
  }

  Widget _buildChart(Map<String, double> categoryTotals, List<TransactionModel> expenseTx, List<Color> colors, double totalExpense) {
    if (_selectedChart == ChartType.pie) {
      final List<PieChartSectionData> pieSections = [];
      int colorIndex = 0;
      categoryTotals.forEach((name, amount) {
        final isTouched = colorIndex == _touchedPieIndex;
        final percentage = totalExpense == 0 ? 0.0 : (amount / totalExpense) * 100;
        final color = colors[colorIndex % colors.length];
        
        final showTitle = percentage >= 5.0 || isTouched;
        
        pieSections.add(
          PieChartSectionData(
            color: color,
            value: amount,
            title: showTitle ? '${percentage.toStringAsFixed(1)}%' : '',
            radius: isTouched ? 70 : 50,
            titleStyle: TextStyle(
              fontSize: isTouched ? 16 : 12, 
              fontWeight: FontWeight.bold, 
              color: Colors.white,
            ),
          )
        );
        colorIndex++;
      });
      
      return PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    pieTouchResponse == null ||
                    pieTouchResponse.touchedSection == null) {
                  _touchedPieIndex = -1;
                  return;
                }
                _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
              });
            },
          ),
          sectionsSpace: 2,
          centerSpaceRadius: 50,
          sections: pieSections,
        ),
      );
    } 
    
    else if (_selectedChart == ChartType.bar) {
      List<BarChartGroupData> barGroups = [];
      int index = 0;
      categoryTotals.forEach((name, amount) {
        barGroups.add(
          BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: amount,
                color: colors[index % colors.length],
                width: 22,
                borderRadius: BorderRadius.circular(4),
              )
            ],
          )
        );
        index++;
      });

      return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barGroups: barGroups,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < 0 || value.toInt() >= categoryTotals.length) return const SizedBox();
                  final catName = categoryTotals.keys.elementAt(value.toInt());
                  final name = catName.length > 6 ? '${catName.substring(0, 6)}.' : catName;
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(name, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  'Rp ${_formatMoney(rod.toY)}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }
            )
          ),
        ),
      );
    }
    
    else {
      // Line Chart: Multi-Category
      Map<String, Map<int, double>> categoryDailyTotals = {};
      
      for (var cat in categoryTotals.keys) {
        categoryDailyTotals[cat] = {};
      }
      
      int minDay = 999999999;
      int maxDay = 0;
      
      for (var tx in expenseTx) {
        String rawCatName = tx.category?.name ?? 'Lainnya';
        if (!categoryTotals.containsKey(rawCatName)) {
          rawCatName = 'Lainnya';
        }
        
        final dayStart = DateTime(tx.date.year, tx.date.month, tx.date.day);
        final dayKey = dayStart.millisecondsSinceEpoch ~/ 86400000;
        
        if (dayKey < minDay) minDay = dayKey;
        if (dayKey > maxDay) maxDay = dayKey;
        
        categoryDailyTotals[rawCatName]![dayKey] = (categoryDailyTotals[rawCatName]![dayKey] ?? 0) + tx.amount;
      }
      
      // Fill gaps with 0
      for (var cat in categoryDailyTotals.keys) {
        if (minDay <= maxDay) {
          for (int i = minDay; i <= maxDay; i++) {
            categoryDailyTotals[cat]![i] ??= 0.0;
          }
        }
      }
      
      List<LineChartBarData> barDataList = [];
      int colorIndex = 0;
      
      categoryDailyTotals.forEach((catName, dailyTotals) {
        if (dailyTotals.isEmpty) return;
        List<FlSpot> spots = dailyTotals.entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
        spots.sort((a, b) => a.x.compareTo(b.x));
        
        final color = colors[colorIndex % colors.length];
        barDataList.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          )
        );
        colorIndex++;
      });
      
      return LineChart(
        LineChartData(
          lineBarsData: barDataList,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final date = DateTime.fromMillisecondsSinceEpoch(value.toInt() * 86400000);
                  return SideTitleWidget(
                    meta: meta,
                    child: Text("${date.day}/${date.month}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  );
                },
                reservedSize: 30,
                interval: 1,
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    'Rp ${_formatMoney(spot.y)}',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                }).toList();
              }
            )
          ),
        ),
      );
    }
  }

  Widget _buildAllTransactions(List<TransactionModel> transactions, ThemeData theme) {
    if (transactions.isEmpty) {
      return const Center(child: Text("Tidak ada transaksi", style: TextStyle(color: Colors.grey)));
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: transactions.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final tx = transactions[index];
          final isIncome = tx.type == 'income';
          final color = isIncome ? Colors.green : Colors.orange;
          final sign = isIncome ? '+' : '-';
          
          return Dismissible(
            key: Key('tx_${tx.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Konfirmasi"),
                    content: const Text("Apakah Anda yakin ingin menghapus transaksi ini?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Batal")),
                      TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
                    ],
                  );
                },
              );
            },
            onDismissed: (direction) {
              context.read<TransactionBloc>().add(DeleteTransaction(tx.id));
              ToastHelper.showSuccess(context, 'Transaksi berhasil dihapus');
            },
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: color),
              ),
              title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("${tx.date.day}/${tx.date.month}/${tx.date.year}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              trailing: Text(
                "$sign Rp ${_formatMoney(tx.amount)}",
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                import_transaction_sheet.TransactionBottomSheet.show(context, type: tx.type, transaction: tx);
              },
            ),
          );
        },
      ),
    );
  }

  String _formatMoney(double amount) {
    if (amount >= 1000) {
      String formatted = amount.toStringAsFixed(0);
      return formatted.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    }
    return amount.toStringAsFixed(0);
  }

  // BOTTOM SHEET FILTER
  void _showFilterBottomSheet(BuildContext context) {
    final state = context.read<TransactionBloc>().state;
    List<CategoryModel> categories = [];
    if (state is TransactionLoaded) {
      categories = state.categories;
    }

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text("Filter & Urutkan", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  
                  // WAKTU
                  Text("Rentang Waktu", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TimeFilter.values.map((tf) {
                      final names = {
                        TimeFilter.all: "Semua", TimeFilter.today: "Hari Ini",
                        TimeFilter.week: "Minggu Ini", TimeFilter.month: "Bulan Ini", TimeFilter.custom: "Kustom"
                      };
                      return ChoiceChip(
                        label: Text(names[tf]!),
                        selected: _timeFilter == tf,
                        onSelected: (selected) async {
                          if (selected) {
                            if (tf == TimeFilter.custom) {
                              final range = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (range != null) {
                                setModalState(() {
                                  _timeFilter = tf;
                                  _customDateRange = range;
                                });
                                setState(() {
                                  _timeFilter = tf;
                                  _customDateRange = range;
                                });
                              }
                            } else {
                              setModalState(() => _timeFilter = tf);
                              setState(() => _timeFilter = tf);
                            }
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  // KATEGORI
                  Text("Kategori", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text("Semua"),
                        selected: _filterCategoryId == null,
                        onSelected: (val) {
                          if (val) {
                            setModalState(() => _filterCategoryId = null);
                            setState(() => _filterCategoryId = null);
                          }
                        },
                      ),
                      ...categories.map((c) {
                        return ChoiceChip(
                          label: Text(c.name),
                          selected: _filterCategoryId == c.id,
                          onSelected: (val) {
                            if (val) {
                              setModalState(() => _filterCategoryId = c.id);
                              setState(() => _filterCategoryId = c.id);
                            }
                          },
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // URUTAN
                  Text("Urutkan Berdasarkan", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SortOrder.values.map((so) {
                      final names = {
                        SortOrder.newest: "Terbaru", SortOrder.oldest: "Terlama",
                        SortOrder.highest: "Tertinggi", SortOrder.lowest: "Terendah"
                      };
                      return ChoiceChip(
                        label: Text(names[so]!),
                        selected: _sortOrder == so,
                        onSelected: (val) {
                          if (val) {
                            setModalState(() => _sortOrder = so);
                            setState(() => _sortOrder = so);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text("Terapkan Filter", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            );
          }
        );
      }
    );
  }
}
