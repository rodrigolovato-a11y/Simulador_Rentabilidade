// lib/presentation/services/report/report_service.dart
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class ReportLabels {
  final String reportTitle;
  final String sectionResults;
  final String traditionalTitle;
  final String effathaTitle;
  final String totalInvestment;
  final String totalRevenue;
  final String totalProduction;
  final String totalProfit;
  final String totalProfitPercent;
  final String profitability;
  final String difference;
  final String additionalProfitability;
  final String farmStandard;

  // Contexto
  final String currencySymbol;
  final String cropLabel;
  final String areaUnitLabel;
  final String productivityUnitLabel;

  const ReportLabels({
    required this.reportTitle,
    required this.sectionResults,
    required this.traditionalTitle,
    required this.effathaTitle,
    required this.totalInvestment,
    required this.totalRevenue,
    required this.totalProduction,
    required this.totalProfit,
    required this.totalProfitPercent,
    required this.profitability,
    required this.difference,
    required this.additionalProfitability,
    required this.farmStandard,
    required this.currencySymbol,
    required this.cropLabel,
    required this.areaUnitLabel,
    required this.productivityUnitLabel,
  });
}

class SimulationReportData {
  final Map<String, dynamic> traditional;
  final Map<String, dynamic> effatha;
  final String cropKey;
  final String areaUnit;
  final String productivityUnit;
  final double kgPerSack;
  final ReportLabels labels;

  const SimulationReportData({
    required this.traditional,
    required this.effatha,
    required this.cropKey,
    required this.areaUnit,
    required this.productivityUnit,
    required this.kgPerSack,
    required this.labels,
  });
}

class ReportService {
  static Future<Uint8List> buildSimulationPdf(
    SimulationReportData data,
  ) async {
    final pdf = pw.Document();

    final t = data.traditional;
    final e = data.effatha;

    // Helpers
    String _s(Object? v) => v?.toString() ?? '';

    String _money(Object? v) {
      if (v == null) return '${data.labels.currencySymbol} 0,00';
      final num n = (v is num) ? v : num.tryParse(v.toString()) ?? 0;
      // formatação simples com vírgula decimal (compatível com exemplo anterior)
      final s = n.toStringAsFixed(2).replaceAll('.', ',');
      return '${data.labels.currencySymbol} $s';
    }

    String _percent(num? v) {
      final d = (v ?? 0).toDouble();
      return '${d.toStringAsFixed(0)}%';
    }

    // Produção: usa texto pronto se veio no map; se não, calcula em "sc"
    String _productionStr(Map<String, dynamic> m) {
      final ready = m['productionTotal'];
      if (ready is String && ready.isNotEmpty) return ready;
      final kg = (m['_productionKg'] as num?)?.toDouble() ?? 0.0;
      final sc = data.kgPerSack > 0 ? (kg / data.kgPerSack).round() : 0;
      return '$sc sc';
    }

    // Linhas da tabela (3 colunas: Métrica | Padrão Fazenda | Effatha)
    pw.TableRow _row(String metric, String left, String right) {
      return pw.TableRow(
        decoration: const pw.BoxDecoration(),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(metric, style: const pw.TextStyle(fontSize: 11)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(left, style: const pw.TextStyle(fontSize: 11)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(right, style: const pw.TextStyle(fontSize: 11)),
          ),
        ],
      );
    }

    // Bloco “chip” sem withOpacity: usamos pw.Opacity para simular transparência
    pw.Widget _chip(String title, String value) {
      return pw.Container(
        decoration: pw.BoxDecoration(
          color: PdfColors.white, // base
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.white),
        ),
        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: pw.Opacity(
          opacity: 0.85, // emula "branco com opacidade"
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(title, style: pw.TextStyle(color: PdfColors.black, fontSize: 10)),
              pw.SizedBox(height: 2),
              pw.Text(
                value,
                style: pw.TextStyle(
                  color: PdfColors.black,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Cálculos para rentabilidade
    final num tProfit = (t['profit'] as num?) ?? 0;
    final num eProfit = (e['profit'] as num?) ?? 0;
    final num diffMoney = eProfit - tProfit;
    final double compPct = (tProfit == 0) ? 0 : (diffMoney / tProfit) * 100.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [
          // Cabeçalho — título principal e subtítulo
          pw.Text(
            data.labels.reportTitle, // ex.: "Relatório de Simulação"
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            // linha de contexto (Cultura / área / produtividade) + data/hora
            '${data.labels.cropLabel} • ${data.labels.areaUnitLabel} • ${data.labels.productivityUnitLabel}\n'
            '${_timestampLine()}',
            style: pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
          ),
          pw.SizedBox(height: 16),

          // Título da sessão
          pw.Text(
            data.labels.sectionResults, // ex.: "Resultados"
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),

          // Tabela Métrica | Padrão Fazenda | Effatha
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.8),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.6),
              1: pw.FlexColumnWidth(1.2),
              2: pw.FlexColumnWidth(1.2),
            },
            children: [
              // Cabeçalho
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _th('Métrica'),
                  _th(data.labels.farmStandard),
                  _th(data.labels.effathaTitle),
                ],
              ),
              // Linhas
              _row(
                data.labels.totalInvestment,
                _s(t['investmentTotal']),
                _s(e['investmentTotal']),
              ),
              _row(
                data.labels.totalProduction,
                _productionStr(t),
                _productionStr(e),
              ),
              _row(
                data.labels.totalRevenue,
                t['revenue'] != null ? _money(t['revenue']) : _s(t['investmentTotal']),
                e['revenue'] != null ? _money(e['revenue']) : _s(e['investmentTotal']),
              ),
              _row(
                data.labels.totalProfit,
                _money(t['profit']),
                _money(e['profit']),
              ),
              _row(
                data.labels.totalProfitPercent,
                _s(t['profitabilityPercent'] ?? _percent(t['_profitabilityRaw'] as num?)),
                _s(e['profitabilityPercent'] ?? _percent(e['_profitabilityRaw'] as num?)),
              ),
            ],
          ),

          pw.SizedBox(height: 16),

          // Bloco "Rentabilidade"
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF2ECC71), // verde base
              borderRadius: pw.BorderRadius.circular(10),
            ),
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  data.labels.profitability,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _chip(
                        '${data.labels.difference} (${data.labels.currencySymbol})',
                        _money(diffMoney),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: _chip(
                        data.labels.additionalProfitability,
                        '${compPct.toStringAsFixed(0)}%',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _th(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          text,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
        ),
      );

  static String _timestampLine() {
    final now = DateTime.now();
    final two = (int n) => n.toString().padLeft(2, '0');
    final date = '${two(now.day)}/${two(now.month)}/${now.year}';
    final time = '${two(now.hour)}:${two(now.minute)}';
    return '$date $time';
  }
}
