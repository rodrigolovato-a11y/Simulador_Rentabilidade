import 'package:effatha_agro_simulator/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import 'report_template_widget.dart';

class SimulationExportArgs {
  final Map<String, dynamic> traditional;
  final Map<String, dynamic> effatha;
  final String cropKey;
  final String areaUnit;
  final String productivityUnit;
  final double kgPerSack;

  SimulationExportArgs({
    required this.traditional,
    required this.effatha,
    required this.cropKey,
    required this.areaUnit,
    required this.productivityUnit,
    required this.kgPerSack,
  });
}

class ExportResultsScreen extends StatelessWidget {
  const ExportResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.export),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _content(context),
      ),
    );
  }

  Widget _content(BuildContext context) {
    Map<String, dynamic>? traditional;
    Map<String, dynamic>? effatha;
    String cropKey = 'soy';
    String areaUnit = 'hectares';
    String productivityUnit = 'sc/ha';

    final raw = ModalRoute.of(context)?.settings.arguments;

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
      areaUnit: areaUnit,
      productivityUnit: productivityUnit,
    );
  }
}
