import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/universal_button.dart';
import '../../../../gen/assets.gen.dart';
import '../cubit/b2b_cubit.dart';

class B2BRegistrationPage extends StatefulWidget {
  const B2BRegistrationPage({super.key});

  @override
  State<B2BRegistrationPage> createState() => _B2BRegistrationPageState();
}

class _B2BRegistrationPageState extends State<B2BRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _innController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  File? _documentImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Sahifaga kirilganda B2B statusni API orqali tekshiramiz
    context.read<B2BCubit>().getB2BStatus();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _innController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _contactPersonController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDocumentImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _documentImage = File(pickedFile.path);
        });
      }
    } catch (_) {
      // silently ignore for now, can show snackbar if needed
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Optional: require document image
    if (_documentImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('b2b_upload_document'.tr()),
        ),
      );
      return;
    }

    // Cubit orqali B2B user sifatida ro'yxatdan o'tish
    context.read<B2BCubit>().registerAsB2B(
      companyName: _companyNameController.text,
      inn: _innController.text.isEmpty ? 'N/A' : _innController.text,
      address: _addressController.text,
      contactPerson: _contactPersonController.text,
      phoneNumber: _phoneController.text,
      extraInfo: _descriptionController.text,
      documentImage: _documentImage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<B2BCubit, B2BState>(
      listener: (context, state) {
        if (state is B2BLoading && state.type == 'register') {
          setState(() {
            _isLoading = true;
          });
        } else if (state is B2BRegistrationSuccess) {
          setState(() {
            _isLoading = false;
          });
          
          // Show success dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('b2b_success_title'.tr()),
              content: Text('b2b_success_message'.tr()),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: Text('common_ok'.tr()),
                ),
              ],
            ),
          );
        } else if (state is B2BError && state.type == 'register') {
          setState(() {
            _isLoading = false;
          });
          
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'error'.tr()}: ${state.failure.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('b2b_register_page_title'.tr()),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: BlocBuilder<B2BCubit, B2BState>(
          builder: (context, state) {
            // Status yuklanmoqda
            if (state is B2BLoading && state.type == 'getStatus' ||
                state is B2BInitial) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            // Status API dan muvaffaqiyatli yuklangan
            if (state is B2BStatusLoaded) {
              final status = state.status;

              if (status.isPending) {
                // So'rov yuborilgan, tasdiqlash kutilmoqda
                return _buildPendingBody(context);
              }

              if (status.isApprovedB2B) {
                // Foydalanuvchi allaqachon B2B (ulgurji) xaridor
                return _buildApprovedBody(context);
              }

              if (status.isRejected) {
                // Ariza rad etilgan – foydalanuvchi yangi so'rov yubora olmaydi
                return _buildRejectedBody(context);
              }

              // STANDART yoki boshqa holatlarda — ariza formasi
              return _buildFormBody(context);
            }

            // Statusni olishda xato bo'lsa ham, foydalanuvchi ariza yubora olishi uchun formani ko'rsatamiz
            if (state is B2BError && state.type == 'getStatus') {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppDimens.s16),
                    child: Container(
                      padding: const EdgeInsets.all(AppDimens.s12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(AppDimens.r12),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: AppDimens.s10),
                          Expanded(
                            child: Text(
                              state.failure.error,
                              style: TextStyle(
                                fontSize: AppDimens.s12,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(child: _buildFormBody(context)),
                ],
              );
            }

            // Qolgan holatlarda default — ariza formasi
            return _buildFormBody(context);
          },
        ),
      ),
    );
  }

  Widget _buildFormBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.s16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(AppDimens.s16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimens.r12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: AppDimens.s12),
                  Expanded(
                    child: Text(
                      'b2b_form_info'.tr(),
                      style: TextStyle(
                        fontSize: AppDimens.s14,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.s24),

            // Company Name
            AppTextField(
              controller: _companyNameController,
              title: 'b2b_company_name'.tr(),
              hintText: 'b2b_company_name_hint'.tr(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'b2b_company_name_required'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimens.s16),

            // INN
            // AppTextField(
            //   controller: _innController,
            //   title: 'INN (Identifikatsiya raqami)',
            //   hintText: 'Masalan: 123456789',
            //   keyboardType: TextInputType.number,
            //   formatter: [
            //     FilteringTextInputFormatter.digitsOnly,
            //   ],
            //   validator: (value) {
            //     if (value == null || value.isEmpty) {
            //       return 'INN ni kiriting';
            //     }
            //     return null;
            //   },
            // ),
            // const SizedBox(height: AppDimens.s16),

            // Phone
            AppTextField(
              controller: _phoneController,
              title: 'b2b_phone'.tr(),
              hintText: 'b2b_phone_hint'.tr(),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'b2b_phone_required'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimens.s16),

            // Email
            // AppTextField(
            //   controller: _emailController,
            //   title: 'Email',
            //   hintText: 'Masalan: info@company.uz',
            //   keyboardType: TextInputType.emailAddress,
            //   validator: (value) {
            //     if (value == null || value.isEmpty) {
            //       return 'Email ni kiriting';
            //     }
            //     if (!value.contains('@')) {
            //       return 'To\'g\'ri email kiriting';
            //     }
            //     return null;
            //   },
            // ),
            // const SizedBox(height: AppDimens.s16),

            // Address
            AppTextField(
              controller: _addressController,
              title: 'b2b_address'.tr(),
              hintText: 'b2b_address_hint'.tr(),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'b2b_address_required'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimens.s16),

            // Contact Person
            AppTextField(
              controller: _contactPersonController,
              title: 'b2b_contact_person'.tr(),
              hintText: 'b2b_contact_person_hint'.tr(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'b2b_contact_person_required'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimens.s16),

            // Description
            AppTextField(
              controller: _descriptionController,
              title: 'b2b_extra_info'.tr(),
              hintText: 'b2b_extra_info_hint'.tr(),
              maxLines: 10,
              minLines: 4,
            ),
            const SizedBox(height: AppDimens.s24),

            // Document Image Upload
            Text(
              'b2b_upload_document_btn'.tr(),
              style: TextStyle(
                fontSize: AppDimens.s16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: AppDimens.s8),
            GestureDetector(
              onTap: _isLoading ? null : _pickDocumentImage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimens.s16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(AppDimens.r12),
                  border: Border.all(
                    color: _documentImage == null
                        ? (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade300)
                        : AppColors.primary,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(AppDimens.r12),
                      ),
                      child: _documentImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(AppDimens.r12),
                              child: Image.file(
                                _documentImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.insert_drive_file_outlined,
                              color: AppColors.primary,
                            ),
                    ),
                    const SizedBox(width: AppDimens.s16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _documentImage != null
                                ? 'b2b_change_document'.tr()
                                : 'b2b_select_document'.tr(),
                            style: TextStyle(
                              fontSize: AppDimens.s14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: AppDimens.s4),
                          Text(
                            'b2b_document_hint'.tr(),
                            style: TextStyle(
                              fontSize: AppDimens.s12,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimens.s8),
                    SvgPicture.asset(Assets.icons.fileSelect)
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimens.s24),

            // Submit Button
            UniversalButton.filled(
              text: _isLoading ? 'b2b_submitting'.tr() : 'apply_button'.tr(),
              onPressed: _isLoading
                  ? () {}
                  : () {
                      _submitForm();
                    },
            ),
            const SizedBox(height: AppDimens.s16),
          ],
        ),
      ),
    );
  }

  /// PENDING holatidagi sahifa – foydalanuvchiga so'rov ko'rib chiqilayotgani haqida ma'lumot.
  Widget _buildPendingBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppDimens.s24),
          Container(
            padding: const EdgeInsets.all(AppDimens.s20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(AppDimens.r16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.schedule_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: AppDimens.s14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'b2b_status_pending_title'.tr(),
                        style: TextStyle(
                          fontSize: AppDimens.s16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: AppDimens.s8),
                      Text(
                        'b2b_status_pending_message'.tr(),
                        style: TextStyle(
                          fontSize: AppDimens.s14,
                          height: 1.5,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// APPROVED holatidagi sahifa – foydalanuvchi allaqachon ulgurji xaridor.
  Widget _buildApprovedBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppDimens.s24),
          Container(
            padding: const EdgeInsets.all(AppDimens.s20),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.06),
              borderRadius: BorderRadius.circular(AppDimens.r16),
              border: Border.all(
                color: Colors.green.withOpacity(0.4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: Colors.green,
                  size: 28,
                ),
                const SizedBox(width: AppDimens.s14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'b2b_status_approved_title'.tr(),
                        style: TextStyle(
                          fontSize: AppDimens.s16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: AppDimens.s8),
                      Text(
                        'b2b_status_approved_message'.tr(),
                        style: TextStyle(
                          fontSize: AppDimens.s14,
                          height: 1.5,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// REJECTED holatidagi sahifa – ariza rad etilgan, qayta yuborish imkoni yo'q.
  Widget _buildRejectedBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppDimens.s24),
          Container(
            padding: const EdgeInsets.all(AppDimens.s20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.06),
              borderRadius: BorderRadius.circular(AppDimens.r16),
              border: Border.all(
                color: Colors.red.withOpacity(0.4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.block_rounded,
                  color: Colors.red,
                  size: 28,
                ),
                const SizedBox(width: AppDimens.s14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'b2b_status_rejected_title'.tr(),
                        style: TextStyle(
                          fontSize: AppDimens.s16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: AppDimens.s8),
                      Text(
                        'b2b_status_rejected_message'.tr(),
                        style: TextStyle(
                          fontSize: AppDimens.s14,
                          height: 1.5,
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

