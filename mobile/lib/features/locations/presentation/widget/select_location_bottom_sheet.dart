import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../../gen/assets.gen.dart';
import '../../data/models/location_model.dart';

class SelectLocationBottomSheet extends StatelessWidget {
  final List<LocationModel> locations;
  final LocationModel? selectedLocation;
  final Function(LocationModel) onLocationSelected;
  final VoidCallback onAddNewLocation;

  const SelectLocationBottomSheet({
    super.key,
    required this.locations,
    this.selectedLocation,
    required this.onLocationSelected,
    required this.onAddNewLocation,
  });

  static Future<LocationModel?> show({
    required BuildContext context,
    required List<LocationModel> locations,
    LocationModel? selectedLocation,
    required Function(LocationModel) onLocationSelected,
    required VoidCallback onAddNewLocation,
  }) {
    return showModalBottomSheet<LocationModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SelectLocationBottomSheet(
        locations: locations,
        selectedLocation: selectedLocation,
        onLocationSelected: onLocationSelected,
        onAddNewLocation: onAddNewLocation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBgColor = isDark ? AppColors.bgMainDark : Theme.of(context).scaffoldBackgroundColor;
    final handleColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final dividerColor = isDark ? Colors.grey.shade800 : Colors.grey.shade100;
    final closeIconColor = isDark ? AppColors.secondaryTextDark : Colors.grey.shade500;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: sheetBgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle bar ──
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: handleColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Sarlavha ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:  SvgPicture.asset(Assets.icons.location),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'choose_location'.tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: closeIconColor),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).cardColor,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: dividerColor),

          // ── Manzillar ro'yxati ──
          Flexible(
            child: locations.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    itemCount: locations.length,
                    itemBuilder: (context, index) {
                      final location = locations[index];
                      final isSelected = selectedLocation?.id == location.id;
                      return _buildLocationTile(context, location, isSelected);
                    },
                  ),
          ),

          // ── Yangi manzil qo'shish ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onAddNewLocation();
                  },
                  icon: const Icon(Icons.add_location_alt, size: 20),
                  label: Text(
                    'add_new_location'.tr(),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_off_outlined, size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Text(
            'locations_empty'.tr(),
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'no_locations_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTile(BuildContext context, LocationModel location, bool isSelected) {
    return GestureDetector(
      onTap: () {
        onLocationSelected(location);
        Navigator.pop(context, location);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withOpacity(0.06) 
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected 
                ? AppColors.primary 
                : (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade200),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio ko'rsatkich
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade500
                          : Colors.grey.shade400),
                  width: isSelected ? 6 : 2,
                ),
                color: Theme.of(context).cardColor,
              ),
            ),
            const SizedBox(width: 14),

            // Manzil matni
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.address,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (location.active) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.green.shade500,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'active'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}
