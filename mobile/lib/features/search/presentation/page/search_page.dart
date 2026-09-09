import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constans/app_colors.dart';
import '../../../../core/constans/app_sizes.dart';
import '../../../../core/widgets/common_error_widget.dart';
import '../../../home/presentation/widget/products_list.dart';
import '../../../main/presentation/cubit/main_cubit.dart';
import '../cubit/search_cubit.dart';
import '../widget/search_shimmer.dart';


class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = searchController.text.trim();
    if (query.isNotEmpty) {
      context.read<SearchCubit>().searchProducts(query: query);
      _focusNode.unfocus(); // Hide keyboard after search
    }
  }

  Future<void> _onRefresh() async {
    if (searchController.text
        .trim()
        .isNotEmpty) {
      context.read<SearchCubit>().searchProducts(
          query: searchController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    return BlocListener<MainCubit, MainState>(
      listener: (context, state) {
        if (state is MainTabChanged && state.focusSearch) {
          // Add a small delay to ensure page is built and visible
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_focusNode.canRequestFocus) {
              _focusNode.requestFocus();
            }
          });
        }
      },
      child: Scaffold(
        backgroundColor: Theme
            .of(context)
            .scaffoldBackgroundColor,
        appBar:
        PreferredSize(
            preferredSize: Size.fromHeight(kToolbarHeight+50), child: Container(
          padding: const EdgeInsets.all(AppDimens.s16),
          color: isDark ? AppColors.bgTertiaryDark : AppColors.bgTertiary,
          child: SafeArea(
            child: SizedBox(
              child: Padding(
                padding:  EdgeInsets.only(top: AppDimens.s10),
                child: CupertinoSearchTextField(
                  controller: searchController,
                  focusNode: _focusNode,
                  placeholder: 'search_hint'.tr(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.s12,
                    vertical: AppDimens.s10,
                  ),
                  style: TextStyle(color: Theme
                      .of(context)
                      .textTheme
                      .bodyLarge
                      ?.color),
                  placeholderStyle: TextStyle(
                    color: isDark ? Colors.grey.shade500 : CupertinoColors.systemGrey,
                  ),
                  decoration: BoxDecoration(
                    color:isDark ? AppColors.bgMainDark : AppColors.bgMain,
                    borderRadius: BorderRadius.circular(AppDimens.r12),
                    // border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border)
                  ),
                  onSubmitted: (value) {
                    _performSearch();
                  },
                  onChanged: (value) {
                    // Clear search when field is empty
                    if (value.isEmpty) {
                      context.read<SearchCubit>().clearSearch();
                    }
                  },
                ),
              ),
            ),
          ),
        ), 


        ),
        body: Column(
          children: [
            // Search Field


            // Search Results
            Expanded(
              child: BlocBuilder<SearchCubit, SearchState>(
                builder: (context, state) {
                  if (state is SearchLoading) {
                    return const SearchShimmer();
                  }

                  if (state is SearchError && state.type == 'search') {
                    return CommonErrorWidget(
                      message: state.failure.error,
                      onRetry: _performSearch,
                      title: 'error'.tr(),
                    );
                  }

                  if (state is SearchSuccess) {
                    if (state.loadingStates['search'] == true) {
                      return const SearchShimmer();
                    }

                    final hasData = state.data != null &&
                        (state.data is List && (state.data as List).isNotEmpty);
                    final hasHistory = state.history.isNotEmpty;

                    if (hasData) {
                      return RefreshIndicator(
                        onRefresh: _onRefresh,
                        child: ProductsList(
                          productsData: state.data,
                          isLoading: state.loadingStates['search'] == true,
                          error: state.errorStates['search']?.error,
                          type: 'search',
                          hasMore: state.hasMore['search'] ?? false,
                          isLoadingMore: state.loadingStates['searchMore'] == true,
                          onRetry: _performSearch,
                        ),
                      );
                    } else if (hasHistory) {
                      return _buildHistoryList(state.history);
                    }
                  }

                  // If Initial or Success with no data and no history
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: isDark ? Colors.grey.shade700 : Colors.grey
                              .shade400,
                        ),
                        const SizedBox(height: AppDimens.s16),
                        Text(
                          'search_no_results'.tr(),
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade500 : Colors.grey
                                .shade600,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<String> history) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppDimens.s16, AppDimens.s16, AppDimens.s16, AppDimens.s8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'search_history'.tr(), // TODO: add key
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme
                      .of(context)
                      .textTheme
                      .bodyLarge
                      ?.color,
                ),
              ),
              InkWell(
                onTap: () {
                  context.read<SearchCubit>().clearHistory();
                },
                child: Text(
                  'clear_history'.tr(), // TODO: add key
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final query = history[index];
              return ListTile(
                leading: Icon(Icons.history,
                    color: isDark ? Colors.grey.shade500 : Colors.grey),
                title: Text(
                  query,
                  style: TextStyle(
                    color: Theme
                        .of(context)
                        .textTheme
                        .bodyMedium
                        ?.color,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.close, size: 20,
                      color: isDark ? Colors.grey.shade500 : Colors.grey),
                  onPressed: () {
                    context.read<SearchCubit>().removeFromHistory(query);
                  },
                ),
                onTap: () {
                  searchController.text = query;
                  _performSearch();
                },
              );
            },
          ),
        ),
      ],
    );
  }

}
