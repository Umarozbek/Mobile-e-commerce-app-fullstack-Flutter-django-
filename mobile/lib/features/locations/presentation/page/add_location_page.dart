import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/location_model.dart';
import '../cubit/location_cubit.dart';

class AddLocationPage extends StatefulWidget {
  final LocationModel? locationToEdit;

  const AddLocationPage({super.key, this.locationToEdit});

  @override
  State<AddLocationPage> createState() => _AddLocationPageState();
}

class _AddLocationPageState extends State<AddLocationPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _addressController;
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.locationToEdit?.address);
    if (widget.locationToEdit != null) {
      _isActive = widget.locationToEdit!.active;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveLocation() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      if (widget.locationToEdit != null) {
        await context.read<LocationCubit>().updateLocation(
          widget.locationToEdit!.id!,
          _addressController.text.trim(),
          _isActive,
        );
      } else {
        await context.read<LocationCubit>().addLocation(
          _addressController.text.trim(),
          _isActive,
        );
      }

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.locationToEdit != null
                  ? 'location_updated_success'.tr()
                  : 'location_added_success'.tr(),
            ),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.locationToEdit != null;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isEditing ? 'edit_location_title'.tr() : 'new_location_title'.tr()),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.s16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Address Field
              AppTextField(
                controller: _addressController,
                title: 'address_label'.tr(),
                hintText: 'checkout_delivery_address'.tr(),
                maxLines: 10,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'address_required'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimens.s16),
              
              // Active/Default Checkbox
              Container(
                padding: const EdgeInsets.all(AppDimens.s16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(AppDimens.r12),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value ?? false;
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                    Expanded(
                      child: Text(
                        'active_address'.tr(),
                        style: TextStyle(
                          fontSize: AppDimens.s16,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.s24),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: AppDimens.s16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.r12),
                    ),
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'common_save'.tr(),
                          style: const TextStyle(
                            fontSize: AppDimens.s16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
