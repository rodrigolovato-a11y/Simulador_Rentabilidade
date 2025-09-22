import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:effatha_agro_simulator/l10n/app_localizations.dart';

class ReportTemplateWidget extends StatelessWidget {
  final Map<String, dynamic> traditional;
  final Map<String, dynamic> effatha;
  final String cropKey;
  final String areaUnit;
  final String productivityUnit;
  final double kgPerSack;

  const ReportTemplateWidget({
    super.key,
    required this.traditional,
    required this.effatha,
    required this.cropKey,
    required this.areaUnit,
    required this.productivityUnit,
    this.kgPerSack = 60.0,
  });

  
  String _fmtMoney(context, BuildContext context, double v) {
    final f = NumberFormat.currency(
      locale: Localizations.localeOf(context).toLanguageTag().replaceAll('-', '_'),
      symbol: r'$ ',
      decimalDigits: 2,
    );
    return f.format(v);
  }

  String _fmtPercent(context, BuildContext context, double v) {
    final fixed = double.parse(v.toStringAsFixed(2));
    final f = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag().replaceAll('-', '_'),
    );
    return '${f.format(fixed)}%';
  }

  String _prodKgToSc(context, BuildContext context, double kg) {
    final sc = kg / kgPerSack;
    final f = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag().replaceAll('-', '_'),
    );
    return '${f.format(sc.round())} sc';
  }
Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
    final comparisonPct =
        (tPerc != 0) ? (((ePerc / tPerc) * 100.0) - 100.0) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: DefaultTextStyle(
        style: theme.textTheme.bodyMedium!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.resultsTitle,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),

            // Tabela de duas colunas (igual ao Dashboard/PDF)
            _row2(AppLocalizations.of(context)!.totalInvestment, _fmtMoney(context, context, tCosts), _fmtMoney(context, context, eCosts)),
            _row2(AppLocalizations.of(context)!.totalProduction, _prodKgToSc(context, context, tProdKg), _prodKgToSc(context, context, eProdKg)),
            _row2(AppLocalizations.of(context)!.totalRevenue, _fmtMoney(context, context, tRevenue), _fmtMoney(context, context, eRevenue)),
            _row2(AppLocalizations.of(context)!.totalProfit, _fmtMoney(context, context, tProfit), _fmtMoney(context, context, eProfit)),
            _row2(AppLocalizations.of(context)!.totalProfitPercent,
                _fmtPercent(context, context, tPerc), _fmtPercent(context, context, ePerc)),

            const SizedBox(height: 12),

            // Destaque Rentabilidade
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2ecc71), Color(0xFF27ae60)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: DefaultTextStyle(
                style: theme.textTheme.bodyMedium!.copyWith(color: Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rentabilidade',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        )),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _tile('Diferença (\$)', _fmtMoney(context, context, diffMoney)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _tile(
                              'Comparação (%)',
                              _fmtPercent(context, context, 
                                comparisonPct,
                                decimals: 2,
                              )),
                        ),
                      ],
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

  Widget _row2(String label, String left, String right) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: _kv('$label (Padrão Fazenda)', left),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _kv('$label (Effatha)', right),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(v),
      ],
    );
  }

  Widget _tile(String label, String value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.28)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}




