import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:effatha_agro_simulator/l10n/app_localizations.dart';

class ReportTemplateWidget extends StatelessWidget {
  const ReportTemplateWidget({
    super.key,
    required this.traditional,
    required this.effatha,
    required this.areaUnit,
    required this.productivityUnit,
    required this.kgPerSack,
  });

  /// Mapas vindos da simulação contendo (entre outros):
  /// 'profit', 'revenue', '_productionKg', '_totalCosts', '_profitabilityRaw'
  final Map<String, dynamic> traditional;
  final Map<String, dynamic> effatha;

  final String areaUnit;
  final String productivityUnit;
  final double kgPerSack;

  // ===== Helpers =====
  String _fmtMoney(BuildContext context, double v) {
    final locale = Localizations.localeOf(context).toLanguageTag(); // ex: pt-BR
    final f = NumberFormat.currency(
      locale: locale,
      symbol: r'$ ',
      decimalDigits: 2,
    );
    return f.format(v);
  }

  String _fmtPercent(BuildContext context, double v, {int decimals = 1}) {
    final rounded = double.parse(v.toStringAsFixed(decimals));
    final locale = Localizations.localeOf(context).toLanguageTag();
    return '${NumberFormat.decimalPattern(locale).format(rounded)}%';
  }

  String _prodKgToSc(BuildContext context, double kg) {
    final sacks = kgPerSack > 0 ? (kg / kgPerSack) : 0.0;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final formatted = NumberFormat.decimalPattern(locale).format(sacks.round());
    return '$formatted sc';
  }

  Widget _row2(
    BuildContext context,
    String label,
    String leftValue,
    String rightValue,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$label (Padrão Fazenda)',
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(leftValue, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$label (Effatha)', style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(rightValue, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lê valores com fallback seguro
    final tProfit = (traditional['profit'] as double?) ?? 0.0;
    final eProfit = (effatha['profit'] as double?) ?? 0.0;

    final tRevenue = (traditional['revenue'] as double?) ?? 0.0;
    final eRevenue = (effatha['revenue'] as double?) ?? 0.0;

    final tProdKg = (traditional['_productionKg'] as double?) ?? 0.0;
    final eProdKg = (effatha['_productionKg'] as double?) ?? 0.0;

    final tCosts = (traditional['_totalCosts'] as double?) ?? 0.0;
    final eCosts = (effatha['_totalCosts'] as double?) ?? 0.0;

    final tPerc = (traditional['_profitabilityRaw'] as double?) ?? 0.0;
    final ePerc = (effatha['_profitabilityRaw'] as double?) ?? 0.0;

    final diffMoney = eProfit - tProfit;
    final addProfitPercent =
        tProfit.abs() > 0 ? ((eProfit - tProfit) / tProfit) * 100.0 : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.bodyMedium!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.comparisonOverview,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _row2(
              context,
              AppLocalizations.of(context)!.totalInvestment,
              _fmtMoney(context, tCosts),
              _fmtMoney(context, eCosts),
            ),
            _row2(
              context,
              AppLocalizations.of(context)!.totalProduction,
              _prodKgToSc(context, tProdKg),
              _prodKgToSc(context, eProdKg),
            ),
            _row2(
              context,
              AppLocalizations.of(context)!.totalRevenue,
              _fmtMoney(context, tRevenue),
              _fmtMoney(context, eRevenue),
            ),
            _row2(
              context,
              AppLocalizations.of(context)!.totalProfit,
              _fmtMoney(context, tProfit),
              _fmtMoney(context, eProfit),
            ),
            _row2(
              context,
              AppLocalizations.of(context)!.totalProfitPercent,
              _fmtPercent(context, tPerc),
              _fmtPercent(context, ePerc),
            ),
            const SizedBox(height: 16),
            // Destaques
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2ecc71), Color(0xFF27ae60)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DefaultTextStyle(
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .copyWith(color: Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.enhancedProfitability),
                    const SizedBox(height: 6),
                    Text(
                      '${AppLocalizations.of(context)!.difference} (\$): '
                      '${_fmtMoney(context, diffMoney)}',
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${AppLocalizations.of(context)!.additionalProfitability}: '
                      '${_fmtPercent(context, addProfitPercent, decimals: 2)}',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
