
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mart/gen/assets.gen.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../../core/widgets/common_error_widget.dart';
import '../../data/models/location_model.dart';
import '../cubit/location_cubit.dart';
import '../cubit/location_state.dart';
import '../widget/location_shimmer.dart';
import 'add_location_page.dart';

class LocationsPage extends StatefulWidget {
  const LocationsPage({super.key});

  @override
  State<LocationsPage> createState() => _LocationsPageState();
}

class _LocationsPageState extends State<LocationsPage> {
  @override
  void initState() {
    super.initState();
    // context.read<LocationCubit>().loadLocations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('locations'.tr()),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.add),
          //   onPressed: () => _navigateToAddLocation(),
          // ),
        ],
      ),
      body: BlocBuilder<LocationCubit, LocationState>(
        builder: (context, state) {
          if (state is LocationLoading) {
            return const LocationShimmer();
          }

          if (state is LocationError) {
            return CommonErrorWidget(
              message: state.message.error,
              onRetry: () => context.read<LocationCubit>().loadLocations(),
              title: 'error'.tr(),
              buttonText: 'reload'.tr(),
            );
          }

          if (state is LocationLoaded) {
            if (state.locations.isEmpty) {
              return _buildEmptyState();
            }
            return _buildLocationsList(state.locations, state.selectedLocation);
          }

          return _buildEmptyState();
        },
      ),
      floatingActionButton: BlocBuilder<LocationCubit, LocationState>(
        builder: (context, state) {
          if (state is LocationLoaded && state.locations.isNotEmpty) {
            return FloatingActionButton.extended(
              onPressed: () => _navigateToAddLocation(),
              backgroundColor: AppColors.primary,
              // icon: const Icon(Icons.add_location_alt, color: Colors.white),
              label: Text(
                'add_new_location'.tr(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.s32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimens.s24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on_outlined,
                size: 64,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppDimens.s24),
            Text(
              'no_locations_title'.tr(),
              style: TextStyle(
                fontSize: AppDimens.s20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: AppDimens.s8),
            Text(
              'no_locations_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppDimens.s14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppDimens.s32),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddLocation(),
              icon: const Icon(Icons.add_location_alt),
              label: Text('add_new_location'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.s24,
                  vertical: AppDimens.s14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.r12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationsList(List<LocationModel> locations, LocationModel? selectedLocation) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimens.s16),
      itemCount: locations.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppDimens.s12),
      itemBuilder: (context, index) {
        final location = locations[index];
        final isSelected = selectedLocation?.id == location.id;
        return _buildLocationCard(location, isSelected);
      },
    );
  }

  Widget _buildLocationCard(LocationModel location, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(

      decoration: BoxDecoration(
        color: isDark?AppColors.bgTertiaryDark:AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(AppDimens.s16),
        border: Border.all(
          color: isSelected 
              ? AppColors.primary 
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      // padding: const EdgeInsets.all(AppDimens.s5),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.r12),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimens.r12),
          onTap: () => context.read<LocationCubit>().selectLocation(location),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.s12, 
              vertical: AppDimens.s12,
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.bgSecondaryDark:AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(AppDimens.r12),
                  ),
                  padding: const EdgeInsets.all(AppDimens.s12),
                  height: AppDimens.s50,
                  width: AppDimens.s50,
                  child: SvgPicture.asset(Assets.icons.location),
                ),
                const SizedBox(width: AppDimens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.address,
                        style: TextStyle(
                          fontSize: AppDimens.s14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // if (location.active) ...[
                      //   const SizedBox(height: 4),
                      //   Text(
                      //     'active'.tr(),
                      //     style: const TextStyle(
                      //       fontSize: 11,
                      //       fontWeight: FontWeight.w500,
                      //       color: Colors.green,
                      //     ),
                      //   ),
                      // ],
                    ],
                  ),
                ),
                // if (isSelected)
                //   const Padding(
                //     padding: EdgeInsets.only(right: 8),
                //     child: Icon(
                //       Icons.check_circle,
                //       color: AppColors.primary,
                //       size: 20,
                //     ),
                //   ),
                // IconButton(
                //   icon: const Icon(Icons.edit_outlined),
                //   color: Colors.grey.shade600,
                //   iconSize: 20,
                //   onPressed: () => _navigateToAddLocation(locationToEdit: location),
                //   style: IconButton.styleFrom(
                //     visualDensity: VisualDensity.compact,
                //   ),
                // ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  color: Colors.grey.shade400,
                  iconSize: 20,
                  onPressed: () => _deleteLocation(location),
                  style: IconButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToAddLocation({LocationModel? locationToEdit}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddLocationPage(locationToEdit: locationToEdit),
      ),
    ).then((_) {
      context.read<LocationCubit>().loadLocations();
    });
  }

  void _deleteLocation(LocationModel location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_location_title'.tr()),
        content: Text('delete_location_confirm'.tr(args: [location.address])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<LocationCubit>().deleteLocation(location.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('location_deleted'.tr()),
                  backgroundColor: Colors.red.shade400,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
  }
}
