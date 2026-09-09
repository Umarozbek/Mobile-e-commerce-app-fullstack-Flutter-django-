import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';


import '../../../../core/constans/app_sizes.dart';

class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey[100]!;
    final containerColor = isDark ? Colors.grey.shade800 : Colors.white;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            width: 100,
            height: 20,
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false, // Align with ProfilePage
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.s16),
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Container( // Transparent container for layout
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimens.s20),
                // decoration: removed to be transparent or maybe just border
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: containerColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                     const SizedBox(height: AppDimens.s12),
                     // Name
                     Container(
                       width: 180,
                       height: 24,
                       decoration: BoxDecoration(
                         color: containerColor,
                         borderRadius: BorderRadius.circular(4),
                       ),
                     ),
                     const SizedBox(height: 8),
                     // Phone
                     Container(
                       width: 120,
                       height: 16,
                       decoration: BoxDecoration(
                         color: containerColor,
                         borderRadius: BorderRadius.circular(4),
                       ),
                     ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.s24),

              // Hisob Section (5 items)
              _buildSectionTitleShimmer(context),
              _buildMenuContainerShimmer(context, 5),
              const SizedBox(height: AppDimens.s24),

              // Boshqaruv Section (2 items)
              _buildSectionTitleShimmer(context),
              _buildMenuContainerShimmer(context, 2),
              const SizedBox(height: AppDimens.s24),

              // Yordam Section (2 items)
              _buildSectionTitleShimmer(context),
              _buildMenuContainerShimmer(context, 2),
              const SizedBox(height: AppDimens.s24),

              // Tizim Section (1 item)
              _buildSectionTitleShimmer(context),
              _buildMenuContainerShimmer(context, 1),
              const SizedBox(height: AppDimens.s40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitleShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.s12, left: 4),
      child: Container(
        width: 100,
        height: 18,
         decoration: BoxDecoration(
           color: isDark ? Colors.grey.shade800 : Colors.white,
           borderRadius: BorderRadius.circular(4),
         ),
      ),
    );
  }

  Widget _buildMenuContainerShimmer(BuildContext context, int itemCount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? Colors.grey.shade800 : Colors.white;

    return Container(
      // The parent container is transparent so we see individual items shimmering
      decoration: BoxDecoration(
        // color: Colors.white, // REMOVED: This was causing the whole block to shimmer
        borderRadius: BorderRadius.circular(AppDimens.r16),
        // border: Border.all(color: Colors.grey[200]!), // Maybe a faint border? No, let's keep it clean
      ),
      child: Column(
        children: List.generate(itemCount, (index) {
          final isLast = index == itemCount - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.s16, vertical: AppDimens.s16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon placeholder
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: containerColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: AppDimens.s16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title placeholder
                          Container(
                            width: double.infinity, 
                            height: 16,
                            margin: const EdgeInsets.only(right: 60), 
                             decoration: BoxDecoration(
                               color: containerColor,
                               borderRadius: BorderRadius.circular(4),
                             ),
                          ),
                          const SizedBox(height: 8), // Increased spacing
                          // Subtitle placeholder
                          Container(
                            width: 150,
                            height: 12,
                             decoration: BoxDecoration(
                               color: containerColor,
                               borderRadius: BorderRadius.circular(4),
                             ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Arrow placeholder
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: containerColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                 Divider(
                   height: 1, 
                   thickness: 0.5, 
                   color: containerColor, // This will shimmer as a line
                   indent: 72, 
                   endIndent: 0,
                ),
            ],
          );
        }),
      ),
    );
  }
}
