import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:effatha_agro_simulator/l10n/app_localizations.dart';

class ReportTemplateWidget extends StatelessWidget {
  final Map<String, dynamic> traditional;
  final Map<String, dynamic> effatha;
  final String cropKey;
  final String areaUnit;
  final String productivityUnit;

  const ReportTemplateWidget({
    super.key,
    required this.traditional,
    required this.effatha,
    required this.cropKey,
    required this.areaUnit,
    required this.productivityUnit,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // Locale-aware formatters
    final localeStr = Localizations.localeOf(context).toString();
    final moneyFmt = NumberFormat.simpleCurrency(locale: localeStr);
    String fmtMoney(num v) => moneyFmt.format(v);
    String fmtPercent(num v, {int decimals = 1}) =>
        '${NumberFormat.decimalPattern(localeStr).format(
          num.parse(v.toStringAsFixed(decimals)),
        )}%';

    // Valores brutos
    final double tProfit = (traditional['profit'] as double?) ?? 0.0;
    final double eProfit = (effatha['profit'] as double?) ?? 0.0;

    final double tProdKg = (traditional['_productionKg'] as double?) ?? 0.0;
    final double eProdKg = (effatha['_productionKg'] as double?) ?? 0.0;

    final double tRevenue = (traditional['revenue'] as double?) ?? 0.0;
    final double eRevenue = (effatha['revenue'] as double?) ?? 0.0;

    final double tCosts = (traditional['_totalCosts'] as double?) ?? 0.0;
    final double eCosts = (effatha['_totalCosts'] as double?) ?? 0.0;

    final double tPerc = (traditional['_profitabilityRaw'] as double?) ?? 0.0;
    final double ePerc = (effatha['_profitabilityRaw'] as double?) ?? 0.0;

    // Métricas derivadas
    final double diffProfitMoney = eProfit - tProfit;
    final double additionalProfitPercent =
        tProfit.abs() > 0 ? ((eProfit - tProfit) / tProfit) * 100.0 : 0.0;

    // Peso por saca (fallback 60)
    final double kgPerSack =
        (effatha['kgPerSack'] as double?) ??
        (traditional['kgPerSack'] as double?) ??
        60.0;

    String prodKgToSc(double kg) {
      final sc = kgPerSack > 0 ? kg / kgPerSack : 0.0;
      return '${NumberFormat.decimalPattern(localeStr).format(sc.round())} sc';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título traduzido
          Text(
            loc.results,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),

          _doubleRow(
            context,
            label: loc.totalInvestment,
            left: fmtMoney(tCosts),
            right: fmtMoney(eCosts),
            farmStandardLabel: loc.farmStandard,
          ),
          _doubleRow(
            context,
            label: loc.totalRevenue,
            left: fmtMoney(tRevenue),
            right: fmtMoney(eRevenue),
            farmStandardLabel: loc.farmStandard,
          ),
          _doubleRow(
            context,
            label: loc.totalProduction,
            left: prodKgToSc(tProdKg),
            right: prodKgToSc(eProdKg),
            farmStandardLabel: loc.farmStandard,
          ),
          _doubleRow(
            context,
            label: loc.totalProfit,
            left: fmtMoney(tProfit),
            right: fmtMoney(eProfit),
            farmStandardLabel: loc.farmStandard,
          ),
          _doubleRow(
            context,
            label: loc.totalProfitPercent,
            left: fmtPercent(tPerc),
            right: fmtPercent(ePerc),
            farmStandardLabel: loc.farmStandard,
          ),

          const SizedBox(height: 16),

          // Destaques de rentabilidade (traduzidos)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2ecc71), Color(0xFF27ae60)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _highlightTile(
                    context,
                    title: '${loc.difference} (${moneyFmt.currencySymbol})',
                    value: fmtMoney(diffProfitMoney),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _highlightTile(
                    context,
                    title: loc.additionalProfitability,
                    value: fmtPercent(additionalProfitPercent, decimals: 2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _highlightTile(BuildContext context,
      {required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Colors.black54, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }

  Widget _doubleRow(
    BuildContext context, {
    required String label,
    required String left,
    required String right,
    required String farmStandardLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Coluna "Padrão Fazenda" traduzida
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label ($farmStandardLabel)',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(left, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Coluna "Effatha"
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Effatha',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(right, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
