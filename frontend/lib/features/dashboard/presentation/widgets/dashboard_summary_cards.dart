import 'package:flutter/material.dart';
import 'package:budget_kos/shared/models/transaction_model.dart';
import '../../../../core/utils/formatters.dart';
import '../../../transaction/presentation/bloc/transaction_state.dart';

class DashboardSummaryCards extends StatelessWidget {
  final TransactionLoaded state;
  final double monthlyBudget;
  final double incomeTarget;
  final VoidCallback onEditBudget;
  final VoidCallback onEditIncome;
  final bool isDesktop;
  final bool isExpanded;

  const DashboardSummaryCards({
    super.key,
    required this.state,
    required this.monthlyBudget,
    required this.incomeTarget,
    required this.onEditBudget,
    required this.onEditIncome,
    this.isDesktop = false,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double incomeProgress = (incomeTarget > 0 ? state.totalIncome / incomeTarget : 0.0).clamp(0.0, 1.0);
    double expenseProgress = (monthlyBudget > 0 ? state.totalExpense / monthlyBudget : 0.0).clamp(0.0, 1.0);

    if (!isDesktop) {
      return Row(
        children: [
          Expanded(
            child: _statCard(theme, 'Pemasukan', 'Rp ${AppFormatters.formatMoney(state.totalIncome)}', theme.colorScheme.primary, incomeProgress, onTap: onEditIncome, isDesktop: isDesktop),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _statCard(theme, 'Pengeluaran', 'Rp ${AppFormatters.formatMoney(state.totalExpense)}', theme.colorScheme.secondary, expenseProgress, onTap: onEditBudget, isDesktop: isDesktop),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: isExpanded ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _statCard(theme, 'Pemasukan', 'Rp ${AppFormatters.formatMoney(state.totalIncome)}', theme.colorScheme.primary, incomeProgress, onTap: onEditIncome, isDesktop: isDesktop, isExpanded: isExpanded),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statCard(theme, 'Pengeluaran', 'Rp ${AppFormatters.formatMoney(state.totalExpense)}', theme.colorScheme.secondary, expenseProgress, onTap: onEditBudget, isDesktop: isDesktop, isExpanded: isExpanded),
        ),
      ],
    );
  }

  Widget _statCard(ThemeData theme, String title, String amount, Color color, double progress, {VoidCallback? onTap, bool isDesktop = true, bool isExpanded = false}) {
    final isDark = theme.brightness == Brightness.dark;
    
    Widget card = Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  title == 'Pemasukan' ? Icons.arrow_downward : Icons.arrow_upward,
                  color: color,
                  size: 16,
                ),
              ),
              if (onTap != null && isDesktop)
                IconButton(
                  icon: const Icon(Icons.edit, size: 16),
                  color: theme.colorScheme.primary,
                  onPressed: onTap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(amount, style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w800)),
          if (isExpanded) const Spacer() else const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(progress * 100).toInt()}%', 
              style: theme.textTheme.labelLarge?.copyWith(
                color: color, 
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('0%', style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey, fontSize: 10)),
              const Spacer(),
              Text('100%', style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ],
      ),
    );

    if (!isDesktop && onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }
}

class DashboardBalanceCard extends StatelessWidget {
  final TransactionLoaded state;

  const DashboardBalanceCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final totalDays = lastDay.day;
    final currentDay = now.day;
    final progress = currentDay / totalDays;
    
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final monthName = months[now.month - 1];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.tertiary.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
                child: const Icon(Icons.account_balance_wallet, size: 12, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text('Sisa Saldo', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Rp ${AppFormatters.formatMoney(state.balance)}', style: theme.textTheme.headlineLarge?.copyWith(color: Colors.black, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("1 $monthName", style: const TextStyle(color: Colors.black54, fontSize: 12)),
              Text("$currentDay $monthName", style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
              Text("${lastDay.day} $monthName", style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardBudgetCard extends StatelessWidget {
  final TransactionLoaded state;
  final double monthlyBudget;
  final VoidCallback onEditBudget;
  final bool isDesktop;

  const DashboardBudgetCard({
    super.key,
    required this.state,
    required this.monthlyBudget,
    required this.onEditBudget,
    this.isDesktop = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final double expense = state.totalExpense;
    double progress = monthlyBudget > 0 ? expense / monthlyBudget : 0;
    if (progress > 1.0) progress = 1.0;

    final Color progressColor = progress > 0.8 ? Colors.red : (progress > 0.5 ? Colors.orange : Colors.green);

    Widget card = Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Target Pengeluaran Bulanan', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              if (isDesktop)
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  color: theme.colorScheme.primary,
                  tooltip: 'Ubah Target',
                  onPressed: onEditBudget,
                ),
            ],
          ),
          if (!isDesktop) const SizedBox(height: 12),
          if (isDesktop) const SizedBox(height: 12),
          Row(
            children: [
              Text('Rp ${AppFormatters.formatMoney(expense)}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: progressColor)),
              Text(' / Rp ${AppFormatters.formatMoney(monthlyBudget)}', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: progressColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            progress >= 1.0 ? 'Batas budget telah terlampaui!' : 'Tersisa Rp ${AppFormatters.formatMoney(monthlyBudget - expense)}',
            style: theme.textTheme.labelSmall?.copyWith(color: progress >= 1.0 ? Colors.red : Colors.grey),
          ),
        ],
      ),
    );

    if (!isDesktop) {
      return GestureDetector(
        onTap: onEditBudget,
        child: card,
      );
    }
    return card;
  }
}
