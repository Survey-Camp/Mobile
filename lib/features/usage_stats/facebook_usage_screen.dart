// ignore_for_file: unused_local_variable, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:survey_camp/shared/theme/app_pallete.dart';
import 'package:survey_camp/core/utils/responsive.dart';
import 'package:survey_camp/core/providers/facebook_usage_provider.dart';

class FacebookUsageScreen extends ConsumerWidget {
  const FacebookUsageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = Responsive(context);
    final facebookUsage = ref.watch(facebookUsageProvider);

    // Fetch usage stats when the screen is loaded
    ref.read(facebookUsageProvider.notifier).updateFacebookUsage();

    double titleFontSize = responsive.screenWidth * 0.06;
    double descriptionFontSize = responsive.screenWidth * 0.04;
    double iconSize = responsive.screenWidth * 0.06;
    double padding = responsive.screenWidth * 0.03;

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppPalettes.background,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.screenWidth * 0.05,
                  vertical: responsive.screenHeight * 0.03,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: EdgeInsets.all(padding),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppPalettes.lightGray),
                            ),
                            child: Icon(
                              Icons.arrow_back,
                              size: iconSize,
                              color: AppPalettes.darkGray,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Facebook Usage',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track and monitor your Facebook activity',
                      style: TextStyle(
                        fontSize: descriptionFontSize,
                        color: AppPalettes.darkGray,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Usage Stats Card
              Padding(
                padding: EdgeInsets.symmetric(horizontal: responsive.screenWidth * 0.05),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(responsive.screenWidth * 0.05),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Usage Statistics',
                        style: TextStyle(
                          fontSize: descriptionFontSize * 1.1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: responsive.screenHeight * 0.02),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(responsive.screenWidth * 0.03),
                            decoration: BoxDecoration(
                              color: AppPalettes.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.access_time_filled,
                              color: AppPalettes.primary,
                              size: iconSize,
                            ),
                          ),
                          SizedBox(width: responsive.screenWidth * 0.03),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Time Spent',
                                  style: TextStyle(
                                    color: AppPalettes.darkGray,
                                    fontSize: descriptionFontSize * 0.9,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${facebookUsage ~/ 1000} seconds',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: descriptionFontSize * 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: responsive.screenHeight * 0.03),
              
              // Refresh Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: responsive.screenWidth * 0.05),
                child: GestureDetector(
                  onTap: () => ref.read(facebookUsageProvider.notifier).updateFacebookUsage(),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: responsive.screenHeight * 0.02,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalettes.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Refresh Usage Stats',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: descriptionFontSize,
                        ),
                      ),
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