import 'dart:math';

import '../models/insight.dart';
import '../models/transaction_item.dart';

class InsightService {
  List<Insight> buildInsights(
    List<TransactionItem> items, {
    double? monthlyBudget,
    String? currencyOverride,
  }) {
    if (items.isEmpty) {
      return [
        Insight(
          title: 'No spending yet',
          detail: 'Add your first transaction to unlock insights.',
          tone: InsightTone.neutral,
        ),
      ];
    }

    final sorted = [...items]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final currency = currencyOverride ?? sorted.first.currency;
    final totalSpend = items.fold<double>(0, (sum, item) => sum + item.amount);
    final insights = <Insight>[];

    insights.add(
      Insight(
        title: 'Total spending',
        detail: 'You have logged ${_formatAmount(totalSpend, currency)} so far.',
        tone: InsightTone.neutral,
      ),
    );

    final categoryTotals = <String, double>{};
    for (final item in items) {
      categoryTotals[item.category] = (categoryTotals[item.category] ?? 0) + item.amount;
    }
    if (categoryTotals.isNotEmpty) {
      final topCategory = categoryTotals.entries.reduce((a, b) => a.value >= b.value ? a : b);
      final percent = (topCategory.value / max(totalSpend, 1)) * 100;
      insights.add(
        Insight(
          title: 'Top category',
          detail: '${_titleCase(topCategory.key)} takes ${percent.toStringAsFixed(0)}% of your spend.',
          tone: percent > 50 ? InsightTone.caution : InsightTone.neutral,
        ),
      );
    }

    final weekend = items.where((item) => item.timestamp.weekday >= 6).toList();
    final weekday = items.where((item) => item.timestamp.weekday <= 5).toList();
    if (weekend.isNotEmpty && weekday.isNotEmpty) {
      final weekendAvg = weekend.fold<double>(0, (sum, item) => sum + item.amount) / weekend.length;
      final weekdayAvg = weekday.fold<double>(0, (sum, item) => sum + item.amount) / weekday.length;
      if (weekendAvg > weekdayAvg * 1.25) {
        insights.add(
          Insight(
            title: 'Weekend lift',
            detail: 'Weekend spend is ${(weekendAvg / weekdayAvg).toStringAsFixed(1)}x your weekday average.',
            tone: InsightTone.caution,
          ),
        );
      } else {
        insights.add(
          Insight(
            title: 'Balanced weeks',
            detail: 'Weekend and weekday spending are fairly even.',
            tone: InsightTone.positive,
          ),
        );
      }
    }

    final lateNight = items.where((item) {
      final hour = item.timestamp.hour;
      return hour >= 22 || hour < 5;
    }).toList();
    if (lateNight.isNotEmpty) {
      final percent = (lateNight.length / items.length) * 100;
      insights.add(
        Insight(
          title: 'Late-night activity',
          detail: '${percent.toStringAsFixed(0)}% of transactions happen after 10pm.',
          tone: percent > 25 ? InsightTone.caution : InsightTone.neutral,
        ),
      );
    }

    final merchantCounts = <String, int>{};
    for (final item in items) {
      merchantCounts[item.merchant] = (merchantCounts[item.merchant] ?? 0) + 1;
    }
    if (merchantCounts.isNotEmpty) {
      final topMerchant = merchantCounts.entries.reduce((a, b) => a.value >= b.value ? a : b);
      insights.add(
        Insight(
          title: 'Frequent merchant',
          detail: 'You visit ${topMerchant.key} most often (${topMerchant.value} times).',
          tone: InsightTone.neutral,
        ),
      );
    }

    final dayInsight = _dayOfWeekInsight(items);
    if (dayInsight != null) insights.add(dayInsight);

    final averageTicket = totalSpend / max(items.length, 1);
    insights.add(
      Insight(
        title: 'Average transaction',
        detail: 'Your typical transaction is ${_formatAmount(averageTicket, currency)}.',
        tone: InsightTone.neutral,
      ),
    );

    final now = DateTime.now();
    final last7 = items.where((item) => item.timestamp.isAfter(now.subtract(const Duration(days: 7)))).toList();
    final prev7 = items.where((item) {
      final afterPrev = item.timestamp.isAfter(now.subtract(const Duration(days: 14)));
      final beforePrev = item.timestamp.isBefore(now.subtract(const Duration(days: 7)));
      return afterPrev && beforePrev;
    }).toList();
    if (last7.isNotEmpty && prev7.isNotEmpty) {
      final lastTotal = last7.fold<double>(0, (sum, item) => sum + item.amount);
      final prevTotal = prev7.fold<double>(0, (sum, item) => sum + item.amount);
      if (lastTotal > prevTotal * 1.5) {
        insights.add(
          Insight(
            title: 'Spending spike',
            detail: 'Last 7 days are up ${(lastTotal / prevTotal).toStringAsFixed(1)}x vs the week before.',
            tone: InsightTone.caution,
          ),
        );
      }
    }

    final dailyAverage = _averageDailySpend(items);
    if (dailyAverage > 0) {
      final forecast = dailyAverage * 7;
      insights.add(
        Insight(
          title: '7-day forecast',
          detail: 'At this pace, next week could be ${_formatAmount(forecast, currency)}.',
          tone: InsightTone.neutral,
        ),
      );
    }

    final budgetInsight = _budgetInsight(items, currency, monthlyBudget);
    if (budgetInsight != null) insights.add(budgetInsight);

    return insights;
  }

  Insight? _budgetInsight(List<TransactionItem> items, String currency, double? monthlyBudget) {
    if (monthlyBudget == null || monthlyBudget <= 0) return null;

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final monthItems = items.where((item) {
      return item.timestamp.isAfter(monthStart.subtract(const Duration(seconds: 1))) &&
          item.timestamp.isBefore(nextMonth);
    }).toList();
    final monthTotal = monthItems.fold<double>(0, (sum, item) => sum + item.amount);
    final remaining = monthlyBudget - monthTotal;

    if (remaining <= 0) {
      return Insight(
        title: 'Budget exceeded',
        detail: 'You are ${_formatAmount(remaining.abs(), currency)} over your monthly budget.',
        tone: InsightTone.caution,
      );
    }

    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dayOfMonth = max(now.day, 1);
    final dailyAvg = monthTotal / dayOfMonth;
    final projected = dailyAvg * daysInMonth;

    if (projected > monthlyBudget * 1.05) {
      final daysToExceed = dailyAvg > 0 ? (remaining / dailyAvg).floor() : daysInMonth - dayOfMonth;
      return Insight(
        title: 'Budget risk',
        detail: 'At this pace you may exceed in about $daysToExceed days.',
        tone: InsightTone.caution,
      );
    }

    return Insight(
      title: 'Budget on track',
      detail: 'You have ${_formatAmount(remaining, currency)} left this month.',
      tone: InsightTone.positive,
    );
  }

  Insight? _dayOfWeekInsight(List<TransactionItem> items) {
    if (items.length < 5) return null;

    final totals = List<double>.filled(7, 0);
    final counts = List<int>.filled(7, 0);
    for (final item in items) {
      final index = item.timestamp.weekday - 1;
      totals[index] += item.amount;
      counts[index] += 1;
    }
    double topAvg = 0;
    int topIndex = 0;
    double overallAvg = 0;
    int totalCount = 0;
    for (var i = 0; i < 7; i++) {
      if (counts[i] > 0) {
        final avg = totals[i] / counts[i];
        if (avg > topAvg) {
          topAvg = avg;
          topIndex = i;
        }
        overallAvg += totals[i];
        totalCount += counts[i];
      }
    }
    if (totalCount == 0) return null;
    overallAvg = overallAvg / totalCount;
    if (topAvg < overallAvg * 1.2) return null;

    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Insight(
      title: 'Peak day',
      detail: '${labels[topIndex]} spending is noticeably higher than average.',
      tone: InsightTone.neutral,
    );
  }

  double _averageDailySpend(List<TransactionItem> items) {
    if (items.isEmpty) return 0;
    final dates = <String>{};
    for (final item in items) {
      dates.add('${item.timestamp.year}-${item.timestamp.month}-${item.timestamp.day}');
    }
    final total = items.fold<double>(0, (sum, item) => sum + item.amount);
    return total / max(dates.length, 1);
  }

  String _formatAmount(double amount, String currency) {
    return '${currency.toUpperCase()} ${amount.toStringAsFixed(2)}';
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }
}
