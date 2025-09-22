import 'package:flutter/material.dart';
import 'package:effatha_agro_simulator/l10n/app_localizations.dart';

class CropSelectorWidget extends StatelessWidget {
  final String selectedCrop; // keys: soy|corn|cotton|sugarcane|wheat|coffee|orange
  final ValueChanged<String> onCropChanged;

  const CropSelectorWidget({
    super.key,
    required this.selectedCrop,
    required this.onCropChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    String cropLabel(String key) {
      switch (key) {
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
          return key;
      }
    }

    final items = const [
      'soy',
      'corn',
      'cotton',
      'sugarcane',
      'wheat',
      'coffee',
      'orange',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.crop, // "Crop"
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedCrop,
          items: items
              .map((k) => DropdownMenuItem(
                    value: k,
                    child: Text(cropLabel(k)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onCropChanged(v);
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
