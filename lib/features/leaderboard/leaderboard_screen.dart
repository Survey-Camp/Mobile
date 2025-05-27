import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:survey_camp/core/utils/responsive.dart';
import 'package:survey_camp/features/profile/services/fetchUserRanks.dart';
import 'package:survey_camp/shared/theme/app_pallete.dart';
import 'package:survey_camp/shared/widgets/top_bar.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final UserRankings _userRankings = UserRankings();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  String? currentUserId;
  List<Map<String, dynamic>> _leaderboardData = [];

  @override
  void initState() {
    super.initState();
    currentUserId = _auth.currentUser?.uid;
    _loadLeaderboardData();
  }

  Future<void> _loadLeaderboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final topUsers = await _userRankings.getTop10UserRankings();
      setState(() {
        _leaderboardData = topUsers;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading leaderboard data: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load leaderboard data')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    double titleFontSize = responsive.screenWidth * 0.06;
    double descriptionFontSize = responsive.screenWidth * 0.04;

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadLeaderboardData,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.screenWidth * 0.05,
              vertical: responsive.screenHeight * 0.03,
            ),
            child: Column(
              children: [
                CustomTopBar(),
                const SizedBox(height: 24),
                _buildHeaderSection(titleFontSize, descriptionFontSize),
                const SizedBox(height: 16),
                _buildLeaderboardList(descriptionFontSize),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(double titleFontSize, double descriptionFontSize) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: titleFontSize * 0.33),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Leaderboard',
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track your progress and compete with others',
            style: TextStyle(
              fontSize: descriptionFontSize,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(double descriptionFontSize) {
    return Expanded(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _leaderboardData.isEmpty
              ? Center(
                  child: Text(
                    'No data available',
                    style: TextStyle(
                      fontSize: descriptionFontSize,
                      color: Colors.grey,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _leaderboardData.length,
                  itemBuilder: (context, index) {
                    final entry = _leaderboardData[index];
                    final isCurrentUser = entry['uid'] == currentUserId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildLeaderboardCard(entry, index, isCurrentUser),
                    );
                  },
                ),
    );
  }

  Widget _buildLeaderboardCard(
      Map<String, dynamic> entry, int index, bool isCurrentUser) {
    String displayName = entry['displayName'] ?? 'Anonymous User';
    String initials = displayName.isNotEmpty
        ? displayName
            .split(' ')
            .map((name) => name.isNotEmpty ? name[0] : '')
            .join()
        : 'U';
    if (initials.length > 2) initials = initials.substring(0, 2);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isCurrentUser
            ? Border.all(color: AppPalettes.primary, width: 2)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildRank(index),
                const SizedBox(width: 16),
                _buildAvatar(initials, entry['photoURL']),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              letterSpacing: -0.2,
                              color: isCurrentUser
                                  ? AppPalettes.primary
                                  : Colors.black,
                            ),
                          ),
                          if (isCurrentUser)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppPalettes.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'You',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppPalettes.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${entry['totalPoints']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: AppPalettes.softCoral,
                      ),
                    ),
                    Text(
                      'points',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRank(int index) {
    if (index < 3) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getMedalColor(index).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.emoji_events,
          color: _getMedalColor(index),
          size: 24,
        ),
      );
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String initials, String? photoURL) {
    if (photoURL != null && photoURL.isNotEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            photoURL,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildInitialsAvatar(initials);
            },
          ),
        ),
      );
    } else {
      return _buildInitialsAvatar(initials);
    }
  }

  Widget _buildInitialsAvatar(String initials) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppPalettes.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Color _getMedalColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber[400]!;
      case 1:
        return Colors.blueGrey[300]!;
      case 2:
        return Colors.brown[300]!;
      default:
        return Colors.grey;
    }
  }
}
