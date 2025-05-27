import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:survey_camp/core/models/user_model.dart';
import 'package:survey_camp/core/providers/auth_provider.dart';
import 'package:survey_camp/features/profile/services/fetchUserRanks.dart';
import 'package:survey_camp/shared/theme/app_pallete.dart';
import 'package:survey_camp/core/utils/responsive.dart';
import 'package:survey_camp/shared/widgets/top_bar.dart';
import 'package:survey_camp/core/models/user_activity_model.dart';
import 'package:survey_camp/core/services/user_activity_service.dart';
import 'package:survey_camp/features/profile/widgets/current_progress_section.dart';
import 'package:survey_camp/features/usage_stats/facebook_usage_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  void _handleLogout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authProvider.notifier).signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: ${e.toString()}')),
        );
      }
    }
  }

// Add this helper method to the ProfileScreen class:
  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = Responsive(context);
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (AppUser? user) =>
          _buildProfileContent(context, ref, user, responsive),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          Center(child: Text('Error: ${error.toString()}')),
    );
  }

  Widget _buildProfileContent(BuildContext context, WidgetRef ref,
      AppUser? user, Responsive responsive) {
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.screenWidth * 0.05,
              vertical: responsive.screenHeight * 0.03,
            ),
            child: Column(
              children: [
                const CustomTopBar(),
                const SizedBox(height: 24),
                _buildProfileHeader(responsive),
                const SizedBox(height: 24),
                _buildProfileCard(user),
                CurrentProgressSection(user: user),
                _buildSection(
                  'Recent Activity',
                  [
                    FutureBuilder<List<UserActivity>>(
                      future: UserActivityService()
                          .getUserRecentActivities(user.uid),
                      builder: (context, snapshot) {
  if (snapshot.connectionState == ConnectionState.waiting) {
    return const Center(child: CircularProgressIndicator());
  }

  if (snapshot.hasError) {
    return Center(child: Text('Error: ${snapshot.error}'));
  }

  final activities = snapshot.data ?? [];

  if (activities.isEmpty) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
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
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.hourglass_empty, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          const Text(
            'No recent activity',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Group activities by type and get the latest for each
  final latestActivities = {
    'survey_completed': activities.firstWhere(
      (a) => a.type == 'survey_completed',
      orElse: () => UserActivity(id: '', type: '', description: '', amount: 0, timestamp: DateTime.now()),
    ),
    'xp': activities.firstWhere(
      (a) => a.type == 'xp',
      orElse: () => UserActivity(id: '', type: '', description: '', amount: 0, timestamp: DateTime.now()),
    ),
    'points': activities.firstWhere(
      (a) => a.type == 'points',
      orElse: () => UserActivity(id: 'unknown', type: '', description: '', amount: 0, timestamp: DateTime.now()),
    ),
  };

  return Column(
    children: latestActivities.entries
        .where((entry) => entry.value.type.isNotEmpty)
        .map((entry) {
      IconData icon;
      Color color;

      switch (entry.key) {
        case 'points':
          icon = Icons.add_circle_outline;
          color = Colors.green;
          break;
        case 'xp':
          icon = Icons.star_outline;
          color = Colors.orange;
          break;
        case 'survey_completed':
          icon = Icons.check_circle_outline;
          color = AppPalettes.primary;
          break;
        default:
          icon = Icons.info_outline;
          color = Colors.grey;
      }

      return _buildActivityItem(
        entry.value.description,
        _getTimeAgo(entry.value.timestamp),
        icon,
        color,
      );
    }).toList(),
  );
},
                    ),
                  ],
                ),
                _buildSection(
                  'Settings',
                  [
                    _buildSettingItem('Notification Preferences',
                        Icons.notifications_outlined),
                    _buildSettingItem('Privacy Settings', Icons.lock_outline),
                    _buildSettingItem(
                      'Account Settings',
                      Icons.person_outline,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => FacebookUsageScreen()),
                      ),
                    ),
                    _buildSettingItem('Help & Support', Icons.help_outline),
                    _buildLogoutButton(context, ref),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Responsive responsive) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: responsive.screenWidth * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile',
            style: TextStyle(
              fontSize: responsive.screenWidth * 0.06,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'View and edit your profile information',
            style: TextStyle(
              fontSize: responsive.screenWidth * 0.04,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(AppUser user) {
    return Container(
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
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildProfileAvatar(user),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? 'No Name',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Email: ${user.email ?? 'No email'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {},
                  color: AppPalettes.primary,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildStatItem(
                  'Rank',
                  FutureBuilder<Map<String, dynamic>?>(
                    future: UserRankings().getUserRank(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        );
                      } else if (snapshot.hasError || !snapshot.hasData) {
                        return const Text(
                          '?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      } else {
                        // Access the rank value from the Map
                        final rankData = snapshot.data!;
                        final userRank = rankData['user']['rank'] ?? 0;
                        return Text(
                          userRank.toString(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }
                    },
                  ),
                  Icons.emoji_events,
                ),
                _buildStatDivider(),
                _buildStatItem('Credits', user.totalPoints ?? 0, Icons.star),
                _buildStatDivider(),
                _buildStatItem('Level', _checkUserLevel(user.totalPoints ?? 0), Icons.trending_up),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(AppUser user) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppPalettes.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: user.photoURL != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  user.photoURL!,
                  fit: BoxFit.cover,
                ),
              )
            : const Text(
                'JD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildStatItem(String label, dynamic value, IconData icon) {
    // If value is already a widget, return a custom layout
    if (value is Widget) {
      return Expanded(
        child: Column(
          children: [
            Icon(icon, color: AppPalettes.primary, size: 24),
            const SizedBox(height: 8),
            value, // Use the widget directly
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Original implementation for int values
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppPalettes.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.grey[200],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildProgressCard(
    String title,
    String subtitle,
    double progress,
    Color color,
    String percentage,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            percentage,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
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
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String title, IconData icon, [VoidCallback? onTap]) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
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
        ),
        child: Row(
          children: [
            Icon(icon, color: AppPalettes.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _handleLogout(context, ref),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
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
        ),
        child: Row(
          children: [
            Icon(Icons.logout, color: Colors.red[400]),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Logout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  int _checkUserLevel(int points) {
    if (points >= 14500) return 10;
    if (points >= 11000) return 9;
    if (points >= 8000) return 8;
    if (points >= 5500) return 7;
    if (points >= 3500) return 6;
    if (points >= 2000) return 5;
    if (points >= 1000) return 4;
    if (points >= 500) return 3;
    if (points >= 300) return 2;
    if (points >= 200) return 1;
    return 0;
  }
}
