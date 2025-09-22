import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';


/// Campo genérico para lista de parâmetros/observações.
class ReportField {
  final String label;
  final String value;
  const ReportField(this.label, this.value);
}

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
  final String cropLabel;                // ex.: "Soja" (localizado)
  final String areaUnitLabel;            // ex.: "Hectares" (localizado)
  final String productivityUnitLabel;    // ex.: "sc/ha" (localizado)

  // Seções extras
  final String inputsSectionTitle;       // ex.: "Parâmetros de entrada"
  final String notesSectionTitle;        // ex.: "Observações"
  final String dateTimeLabel;            // ex.: "Data/Hora"

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
    required this.inputsSectionTitle,
    required this.notesSectionTitle,
    required this.dateTimeLabel,
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

  /// Parâmetros de entrada já formatados (value + unidade). Ex.: "Área" -> "120 hectares"
  final List<ReportField> inputs;

  /// Observações (linhas livres).
  final List<ReportField> notes;

  const SimulationReportData({
    required this.traditional,
    required this.effatha,
    required this.cropKey,
    required this.areaUnit,
    required this.productivityUnit,
    required this.kgPerSack,
    required this.labels,
    this.inputs = const [],
    this.notes = const [],
  });
}

class ReportService {
  static Future<Uint8List> buildSimulationPdf(
    SimulationReportData data,
  ) async {
    final pdf = pw.Document();

    final t = data.traditional;
    final e = data.effatha;

    // === formatadores pt-BR (milhar com ponto, decimais com vírgula) ===
    final _currencyFmt = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: '${data.labels.currencySymbol} ',
    );
    final _numFmt = NumberFormat.decimalPattern('pt_BR');

    String _s(Object? v) => v?.toString() ?? '';

    String _money(Object? v) {
      final num n = (v is num) ? v : num.tryParse(v?.toString() ?? '') ?? 0;
      return _currencyFmt.format(n); // ex.: R$ 1.234.567,89
    }

    String _percent(Object? v) {
      final num n = (v is num) ? v : num.tryParse(v?.toString() ?? '') ?? 0;
      final fixed = double.parse(n.toStringAsFixed(2));
      return '${_numFmt.format(fixed)}%'; // ex.: 12,34%
    }

    double _safePct({required double base, required double diff}) {
      if (base == 0) return 0;
      return (diff / base) * 100.0;
    }

    pw.Widget _header() {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Título principal
          pw.Text(
            data.labels.reportTitle,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          // Linha de contexto (cultura • unidade área • unidade produtividade)
          pw.Text(
            '${data.labels.cropLabel} • ${data.labels.areaUnitLabel} • ${data.labels.productivityUnitLabel}',
            style: pw.TextStyle(
              color: PdfColors.grey700,
              fontSize: 10,
            ),
          ),
          pw.SizedBox(height: 2),
          // Data/hora
          pw.Text(
            '${data.labels.dateTimeLabel}: ${_printNow()}',
            style: pw.TextStyle(
              color: PdfColors.grey600,
              fontSize: 9,
            ),
          ),
        ],
      );
    }

    pw.Widget _sectionTitle(String text) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
          child: pw.Text(
            text,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        );

    pw.Widget _resultsTable() {
      // Uma tabela simples: Métrica | Padrão Fazenda | Effatha
      final rows = <List<pw.Widget>>[
        _resultsRow(
          data.labels.totalInvestment,
          _s(t['investmentTotal']),
          _s(e['investmentTotal']),
        ),
        _resultsRow(
          data.labels.totalProduction,
          _s(t['productionTotal']),
          _s(e['productionTotal']),
        ),
        _resultsRow(
          data.labels.totalRevenue,
          t['revenue'] != null ? _money(t['revenue']) : _s(t['investmentTotal']),
          e['revenue'] != null ? _money(e['revenue']) : _s(e['investmentTotal']),
        ),
        _resultsRow(
          data.labels.totalProfit,
          _money(t['profit']),
          _money(e['profit']),
        ),
        _resultsRow(
          data.labels.totalProfitPercent,
          _s(t['profitabilityPercent']),
          _s(e['profitabilityPercent']),
        ),
      ];

      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        columnWidths: {
          0: const pw.FlexColumnWidth(2.2),
          1: const pw.FlexColumnWidth(1.6),
          2: const pw.FlexColumnWidth(1.6),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              _cellHeader('Métrica'),
              _cellHeader(data.labels.farmStandard),
              _cellHeader(data.effatha['title'] as String? ?? data.labels.effathaTitle),
            ],
          ),
          ...rows.map(
            (r) => pw.TableRow(
              children: r,
            ),
          ),
        ],
      );
    }

    pw.Widget _rentabilidadeBlock() {
      final diffMoney =
          ((e['profit'] ?? 0.0) as num).toDouble() - ((t['profit'] ?? 0.0) as num).toDouble();
      final addPct = _safePct(
        base: ((t['profit'] ?? 0.0) as num).toDouble(),
        diff: diffMoney,
      );

      // Fundo verde sólido (sem withOpacity)
      final green = PdfColor.fromInt(0xFF27ae60);

      return pw.Container(
        decoration: pw.BoxDecoration(
          color: green,
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
                    _percent(addPct),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    pw.Widget _inputsSection() {
      if (data.inputs.isEmpty) return pw.SizedBox();
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle(data.labels.inputsSectionTitle),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(2.2),
              1: pw.FlexColumnWidth(2.0),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _cellHeader('Parâmetro'),
                  _cellHeader('Valor'),
                ],
              ),
              ...data.inputs.map(
                (f) => pw.TableRow(
                  children: [
                    _cellBody(f.label),
                    _cellBody(f.value),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    pw.Widget _notesSection() {
      if (data.notes.isEmpty) return pw.SizedBox();
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle(data.labels.notesSectionTitle),
          ...data.notes.map(
            (n) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('• ', style: const pw.TextStyle(fontSize: 10)),
                  pw.Expanded(
                    child: pw.Text(
                      '${n.label}: ${n.value}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [
          _header(),
          _sectionTitle(data.labels.sectionResults),
          _resultsTable(),
          pw.SizedBox(height: 12),
          _rentabilidadeBlock(),
          pw.SizedBox(height: 14),
          _inputsSection(),
          pw.SizedBox(height: 10),
          _notesSection(),
        ],
      ),
    );

    return pdf.save();
  }

  // ===== Helpers visuais =====

  static pw.Widget _cellHeader(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
      );

  static pw.Widget _cellBody(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          text,
          style: const pw.TextStyle(fontSize: 11),
        ),
      );

  static List<pw.Widget> _resultsRow(String metric, String left, String right) {
    return [
      _cellBody(metric),
      _cellBody(left),
      _cellBody(right),
    ];
  }

  static pw.Widget _chip(String title, String value) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF1e8f4e), // verde mais escuro (sólido)
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.white, width: 0.5),
      ),
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(color: PdfColors.white, fontSize: 10),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static String _printNow() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    // Formato dd/MM/yyyy HH:mm
    return '${two(now.day)}/${two(now.month)}/${now.year} ${two(now.hour)}:${two(now.minute)}';
    // Obs.: o texto “Data/Hora” vem de labels.dateTimeLabel (localizado)
  }
}

