import 'package:effatha_agro_simulator/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportTemplateWidget extends StatelessWidget {
  final Map<String, dynamic> traditional;
  final Map<String, dynamic> effatha;
  final String areaUnit;
  final String productivityUnit;

  const ReportTemplateWidget({
    super.key,
    required this.traditional,
    required this.effatha,
    required this.areaUnit,
    required this.productivityUnit,
  });

  String _fmtMoney(BuildContext context, double v) {
    final f = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$ ', decimalDigits: 2);
    return f.format(v);
  }

  String _fmtPercent(BuildContext context, double v, {int decimals = 1}) {
    final rounded = double.parse(v.toStringAsFixed(decimals));
    return '${NumberFormat.decimalPattern('pt_BR').format(rounded)}%';
  }

  String _prodKgToSc(BuildContext context, double kg, double kgPerSack) {
    final sc = kgPerSack > 0 ? kg / kgPerSack : 0.0;
    return '${NumberFormat.decimalPattern('pt_BR').format(sc.round())} sc';
  }

  @override
  Widget build(BuildContext context) {
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

    // Diferença monetária (lucro adicional em R$)
    final double diffProfitMoney = eProfit - tProfit;

    // Lucro adicional (%) – modelo antigo (base no lucro tradicional)
    final double additionalProfitPercent =
        tProfit.abs() > 0 ? ((eProfit - tProfit) / tProfit) * 100.0 : 0.0;

    // Peso da saca para conversão (se vier junto do mapa, usa; senão default 60)
    final double kgPerSack =
        (effatha['kgPerSack'] as double?) ??
        (traditional['kgPerSack'] as double?) ??
        60.0;

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
          Text(
            AppLocalizations.of(context)!.results,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),

          // Totais (Padrão x Effatha)
          _doubleRow(
            context,
            label: AppLocalizations.of(context)!.totalInvestment,
            left: _fmtMoney(context, tCosts),
            right: _fmtMoney(context, eCosts),
          ),
          _doubleRow(
            context,
            label: AppLocalizations.of(context)!.totalRevenue,
            left: _fmtMoney(context, tRevenue),
            right: _fmtMoney(context, eRevenue),
          ),
          _doubleRow(
            context,
            label: AppLocalizations.of(context)!.totalProduction,
            left: _prodKgToSc(context, tProdKg, kgPerSack),
            right: _prodKgToSc(context, eProdKg, kgPerSack),
          ),
          _doubleRow(
            context,
            label: AppLocalizations.of(context)!.totalProfit,
            left: _fmtMoney(context, tProfit),
            right: _fmtMoney(context, eProfit),
          ),
          _doubleRow(
            context,
            label: AppLocalizations.of(context)!.totalProfitPercent,
            left: _fmtPercent(context, tPerc),
            right: _fmtPercent(context, ePerc),
          ),

          const SizedBox(height: 16),

          // Destaques de rentabilidade
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
                    // usa chave existente no ARB
                    title: AppLocalizations.of(context)!.additionalProfitCash,
                    value: _fmtMoney(context, diffProfitMoney),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _highlightTile(
                    context,
                    // usa chave existente no ARB
                    title: AppLocalizations.of(context)!.additionalProfitPercent,
                    value: _fmtPercent(context, additionalProfitPercent, decimals: 2),
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

  Widget _doubleRow(BuildContext context,
      {required String label, required String left, required String right}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label (Padrão Fazenda)',
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label (Effatha)',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.black54),
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
