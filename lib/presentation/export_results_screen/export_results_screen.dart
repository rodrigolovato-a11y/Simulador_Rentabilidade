import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import '../services/report/report_service.dart';
import 'report_template_widget.dart';
import '../services/report/report_capture.dart';

/// Navegação tipada
class SimulationExportArgs {
  final Map<String, dynamic> traditional;
  final Map<String, dynamic> effatha;
  final String cropKey;
  final String areaUnit;          // 'hectares' | 'acres'
  final String productivityUnit;  // 'kg/ha' | 't/ha' | 'sc/ha' | 'sc/acre'
  final double kgPerSack;

  /// Parâmetros crus para serem formatados no PDF (opcional).
  /// Exemplo:
  /// {
  ///   'area': {'value': '120', 'unit': 'hectares'},
  ///   'historicalProductivity': {'value': '55', 'unit': 'sc/ha'},
  ///   'historicalCosts': {'value': '800', 'unit': r'$/ha'},
  ///   'cropPrice': {'value': '130', 'unit': r'$/sc'},
  ///   'effathaInvestment': {'value': '50', 'unit': r'$/ha'},
  ///   'additionalProductivity': {'value': '5', 'unit': 'sc/ha'},
  ///   'kgPerSack': 60.0
  /// }
  final Map<String, dynamic>? inputs;

  const SimulationExportArgs({
    required this.traditional,
    required this.effatha,
    required this.cropKey,
    required this.areaUnit,
    required this.productivityUnit,
    required this.kgPerSack,
    this.inputs,
  });
}

class ExportResultsScreen extends StatefulWidget {
  const ExportResultsScreen({super.key});

  @override
  State<ExportResultsScreen> createState() => _ExportResultsScreenState();
}

class _ExportResultsScreenState extends State<ExportResultsScreen> {
  final _capture = ReportCaptureController();
  double _kgPerSackFallback = 60.0;

  @override
  void initState() {
    super.initState();
    _loadKgPerSack();
  }

  Future<void> _loadKgPerSack() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final k = prefs.getDouble('kg_per_sack_weight');
      if (mounted && k != null && k > 0) {
        setState(() => _kgPerSackFallback = k);
      }
    } catch (_) {/* mantém 60.0 */}
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // Aceita SimulationExportArgs OU Map<String, dynamic> (retrocompat.)
    final raw = ModalRoute.of(context)?.settings.arguments;

    Map<String, dynamic>? traditional;
    Map<String, dynamic>? effatha;
    String cropKey = 'soy';
    String areaUnit = 'hectares';
    String productivityUnit = 'sc/ha';
    double kgPerSack = _kgPerSackFallback;
    Map<String, dynamic>? inputs;

    if (raw is SimulationExportArgs) {
      traditional = raw.traditional;
      effatha = raw.effatha;
      cropKey = raw.cropKey;
      areaUnit = raw.areaUnit;
      productivityUnit = raw.productivityUnit;
      kgPerSack = raw.kgPerSack;
      inputs = raw.inputs;
    } else if (raw is Map<String, dynamic>) {
      traditional = raw['traditional'] as Map<String, dynamic>?;
      effatha = raw['effatha'] as Map<String, dynamic>?;
      cropKey = (raw['cropKey'] as String?) ?? cropKey;

      final inMap = raw['inputs'] as Map<String, dynamic>?;
      if (inMap != null) {
        inputs = inMap;
        areaUnit = (inMap['areaUnit'] as String?) ?? areaUnit;
        productivityUnit = (inMap['productivityUnit'] as String?) ?? productivityUnit;
        final k = inMap['kgPerSack'];
        if (k is num && k > 0) kgPerSack = k.toDouble();
      }
    }

    if (traditional == null || effatha == null) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.exportReportTitle)),
        body: Center(child: Text(loc.noDataForExport)),
      );
    }

    // ===== Labels localizados para o PDF =====
    // Usa chaves que você já tem no l10n.
    final labels = ReportLabels(
      reportTitle: loc.exportReportTitle,                 // "Exportar Relatório" / equivalente
      sectionResults: loc.results,                        // "Resultados"
      traditionalTitle: loc.farmStandard,                 // "Padrão Fazenda"
      effathaTitle: 'Effatha',                            // normalmente fixo
      totalInvestment: loc.totalInvestment,               // "Investimento Total"
      totalRevenue: loc.totalRevenue,                     // "Receita Total"
      totalProduction: loc.totalProduction,               // "Produção Total"
      totalProfit: loc.totalProfit,                       // "Lucro Total"
      totalProfitPercent: loc.totalProfitPercent,         // "Rentabilidade Total (%)"
      profitability: loc.profitabilityAdditionalEffatha,  // "Rentabilidade"
      difference: loc.difference,                         // "Diferença"
      additionalProfitability: loc.additionalProfitability, // "Lucro adicional (%)"
      farmStandard: loc.farmStandard,                     // rótulo da coluna esquerda
      currencySymbol: r'$',
      cropLabel: _localizedCrop(cropKey, loc),
      areaUnitLabel: _localizedAreaUnit(areaUnit, loc),
      productivityUnitLabel: productivityUnit,            // exibe como está (sc/ha etc.)
      inputsSectionTitle: loc.inputParameters,            // "Parâmetros de entrada"
      notesSectionTitle: loc.notesSectionTitle,           // adicione essa chave no arb, ex.: "Observações"
      dateTimeLabel: loc.dateTimeLabel,                   // adicione essa chave, ex.: "Data/Hora"
    );

    // ===== Parâmetros de entrada (formatados para exibir no PDF) =====
    final inputFields = <ReportField>[];
    if (inputs != null) {
      String fmt(String keyValue, String keyUnit, {String? fallbackLabel}) {
        final v = (inputs![keyValue] ?? {})['value']?.toString() ?? '';
        final u = (inputs![keyUnit] ?? {})['unit']?.toString() ??
            (inputs![keyUnit]?.toString() ?? '');
        return '$v ${u.isNotEmpty ? u : ''}'.trim();
      }

      // Como as estruturas de 'inputs' podem variar, trato defensivamente:
      String valUnit(String valueKey, String unitKey) {
        final v = inputs![valueKey]?['value']?.toString() ??
            inputs![valueKey]?.toString() ??
            '';
        final u = inputs![valueKey]?['unit']?.toString() ??
            inputs![unitKey]?.toString() ??
            '';
        return (v.isEmpty && u.isEmpty) ? '' : '$v ${u.isNotEmpty ? u : ''}'.trim();
      }

      // Área
      if (inputs.containsKey('area')) {
        inputFields.add(ReportField(loc.area, valUnit('area', 'areaUnit')));
      }
      // Produtividade histórica
      if (inputs.containsKey('historicalProductivity')) {
        inputFields.add(ReportField(
          loc.historicalProductivity,
          valUnit('historicalProductivity', 'productivityUnit'),
        ));
      }
      // Custos históricos
      if (inputs.containsKey('historicalCosts')) {
        inputFields.add(ReportField(
          loc.historicalCosts,
          valUnit('historicalCosts', 'costUnit'),
        ));
      }
      // Preço da cultura
      if (inputs.containsKey('cropPrice')) {
        inputFields.add(ReportField(
          loc.cropPrice,
          valUnit('cropPrice', 'priceUnit'),
        ));
      }
      // Investimento Effatha
      if (inputs.containsKey('effathaInvestment')) {
        inputFields.add(ReportField(
          loc.effathaInvestmentCost,
          valUnit('effathaInvestment', 'investmentUnit'),
        ));
      }
      // Produtividade adicional
      if (inputs.containsKey('additionalProductivity')) {
        inputFields.add(ReportField(
          loc.additionalProductivity,
          valUnit('additionalProductivity', 'additionalProductivityUnit'),
        ));
      }
      // Peso por saca
      final k = inputs['kgPerSack'];
      final kStr = (k is num && k > 0) ? '${k.toString()} kg' : '${kgPerSack.toString()} kg';
      inputFields.add(ReportField(loc.sackWeightKg, kStr));
    }

    // ===== Observações =====
    final notes = <ReportField>[
      ReportField(loc.reportGeneratedAutomatically, ''), // adicione no arb (ex.: "Relatório gerado automaticamente pelo simulador.")
      ReportField(loc.valuesCurrencyHint, labels.currencySymbol), // adicione no arb (ex.: "Valores expressos em")
    ];

    final reportData = SimulationReportData(
      traditional: traditional,
      effatha: effatha,
      cropKey: cropKey,
      areaUnit: areaUnit,
      productivityUnit: productivityUnit,
      kgPerSack: kgPerSack,
      labels: labels,
      inputs: inputFields,
      notes: notes,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.exportReportTitle),
        actions: [
          IconButton(
            tooltip: loc.shareAsPng,
            onPressed: () async {
              try {
                final file = await _capture.saveAsPng(
                  filename: 'effatha_report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.png',
                );
                await Share.shareXFiles(
                  [XFile(file.path)],
                  text: loc.reportShareText,
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${loc.pngExportFailed}: $e')),
                );
              }
            },
            icon: const Icon(Icons.image_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          // Preview do PDF
          Expanded(
            child: PdfPreview(
              canChangeOrientation: false,
              canChangePageFormat: false,
              initialPageFormat: PdfPageFormat.a4,
              build: (fmt) => ReportService.buildSimulationPdf(reportData),
            ),
          ),

          // Prévia PNG / Área de captura (mantida)
          Container(
            height: 340,
            width: double.infinity,
            color: Colors.black12,
            child: RepaintBoundary(
              key: _capture.repaintKey,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: _ReportPreviewShell(),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final bytes = await ReportService.buildSimulationPdf(reportData);
          await Printing.sharePdf(
            bytes: bytes,
            filename: 'effatha_report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
          );
        },
        icon: const Icon(Icons.picture_as_pdf_outlined),
        label: Text(loc.sharePdf),
      ),
    );
  }

  String _localizedCrop(String cropKey, AppLocalizations loc) {
    switch (cropKey) {
      case 'soy':
        return loc.cropSoy;
      case 'corn':
        return loc.cropCorn;
      case 'cotton':
        return loc.cropCotton;
      case 'sugarcane':
        return loc.cropSugarcane;
      case 'wheat':
        return loc.cropWheat;
      case 'coffee':
        return loc.cropCoffee;
      case 'orange':
        return loc.cropOrange;
      default:
        return cropKey;
    }
  }

  String _localizedAreaUnit(String unit, AppLocalizations loc) {
    switch (unit) {
      case 'hectares':
        return loc.hectares;
      case 'acres':
        return loc.acres;
      case 'm²':
        return loc.squareMeters;
      default:
        return unit;
    }
  }
}

/// Apenas para a visualização PNG da página (mantido para compatibilidade)
class _ReportPreviewShell extends StatelessWidget {
  const _ReportPreviewShell();

  @override
  Widget build(BuildContext context) {
    final raw = ModalRoute.of(context)?.settings.arguments;

    Map<String, dynamic>? traditional;
    Map<String, dynamic>? effatha;
    String cropKey = 'soy';
    String areaUnit = 'hectares';
    String productivityUnit = 'sc/ha';

    if (raw is SimulationExportArgs) {
      traditional = raw.traditional;
      effatha = raw.effatha;
      cropKey = raw.cropKey;
      areaUnit = raw.areaUnit;
      productivityUnit = raw.productivityUnit;
    } else if (raw is Map<String, dynamic>) {
      traditional = raw['traditional'] as Map<String, dynamic>?;
      effatha = raw['effatha'] as Map<String, dynamic>?;
      cropKey = (raw['cropKey'] as String?) ?? cropKey;
      final inputs = raw['inputs'] as Map<String, dynamic>?;
      if (inputs != null) {
        areaUnit = (inputs['areaUnit'] as String?) ?? areaUnit;
        productivityUnit = (inputs['productivityUnit'] as String?) ?? productivityUnit;
      }
    }

    return ReportTemplateWidget(
      traditional: traditional ?? const {},
      effatha: effatha ?? const {},
      cropKey: cropKey,
      areaUnit: areaUnit,
      productivityUnit: productivityUnit,
    );
  }
}
