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

  // extras de contexto
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
    String _s(Object? v) => v?.toString() ?? '';

    pw.Widget _row(String label, String left, String right) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '$label (${data.labels.farmStandard})',
                    style: pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(left, style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '$label (Effatha)',
                    style: pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(right, style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Paleta estável (sem opacidade)
    final PdfColor kGreen = PdfColor.fromInt(0x27ae60);     // fundo do cartão de rentabilidade
    final PdfColor kGreenDark = PdfColor.fromInt(0x1f8e4d); // borda
    final PdfColor kWhite = PdfColors.white;
    final PdfColor kGrey700 = PdfColors.grey700;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [
          // Cabeçalho
          pw.Text(
            data.labels.reportTitle,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            '${data.labels.cropLabel} • ${data.labels.areaUnitLabel} • ${data.labels.productivityUnitLabel}',
            style: pw.TextStyle(color: kGrey700, fontSize: 10),
          ),
          pw.SizedBox(height: 16),

          // Título da sessão
          pw.Text(
            data.labels.sectionResults,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),

          // Linhas
          _row(
            data.labels.totalInvestment,
            _s(t['investmentTotal']),
            _s(e['investmentTotal']),
          ),
          _row(
            data.labels.totalRevenue,
            _s(t['revenue'] != null ? _money(t['revenue']) : t['investmentTotal']),
            _s(e['revenue'] != null ? _money(e['revenue']) : e['investmentTotal']),
          ),
          _row(
            data.labels.totalProduction,
            _s(t['productionTotal']),
            _s(e['productionTotal']),
          ),
          _row(
            data.labels.totalProfit,
            _money(t['profit']),
            _money(e['profit']),
          ),
          _row(
            data.labels.totalProfitPercent,
            _s(t['profitabilityPercent']),
            _s(e['profitabilityPercent']),
          ),

          pw.SizedBox(height: 16),

          // Bloco "Rentabilidade"
          pw.Container(
            decoration: pw.BoxDecoration(
              color: kGreen,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: kGreenDark, width: 1),
            ),
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  data.labels.profitability,
                  style: pw.TextStyle(
                    color: kWhite,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _chip(
                        '${data.labels.difference} (${data.labels.currencySymbol})',
                        _money((e['profit'] ?? 0.0) - (t['profit'] ?? 0.0)),
                        bg: kGreen,
                        border: kGreenDark,
                        fg: kWhite,
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: _chip(
                        data.labels.additionalProfitability,
                        _percent(_safePct(
                          base: (t['profit'] ?? 0.0).toDouble(),
                          diff: ((e['profit'] ?? 0.0) - (t['profit'] ?? 0.0))
                              .toDouble(),
                        )),
                        bg: kGreen,
                        border: kGreenDark,
                        fg: kWhite,
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

  static pw.Widget _chip(
    String title,
    String value, {
    required PdfColor bg,
    required PdfColor border,
    required PdfColor fg,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: border, width: 1),
      ),
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(color: fg, fontSize: 10)),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(color: fg, fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static String _money(Object? v) {
    if (v == null) return r'$ 0,00';
    final num n = (v is num) ? v : num.tryParse(v.toString()) ?? 0;
    // formatação simples: $ x,xx (pt_BR-like)
    return r'$ ' + n.toStringAsFixed(2).replaceAll('.', ',');
    // Dica: se quiser 100% locale-aware, já passe strings formatadas nos mapas.
  }

  static String _percent(double v) => '${v.toStringAsFixed(2)}%';

  static double _safePct({required double base, required double diff}) {
    if (base == 0) return 0;
    return (diff / base) * 100.0;
  }
}
