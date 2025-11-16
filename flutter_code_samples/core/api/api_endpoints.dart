/// Centralized API endpoints for the GRead app
/// Maps to WordPress/BuddyPress REST API structure
class ApiEndpoints {
  // Base paths
  static const String buddyPress = '/buddypress/v1';
  static const String gread = '/gread/v1';
  static const String jwtAuth = '/jwt-auth/v1';

  // Authentication
  static const String login = '$jwtAuth/token';
  static const String signup = '$buddyPress/signup';
  static const String currentUser = '$buddyPress/members/me';

  // User Management
  static String userStats(int userId) => '$gread/user/$userId/stats';
  static const String userCosmetics = '$gread/user/cosmetics';
  static const String setTheme = '$gread/user/cosmetics/theme';
  static const String setFont = '$gread/user/cosmetics/font';
  static const String setIcon = '$gread/user/cosmetics/icon';
  static const String checkUnlocks = '$gread/user/check-unlocks';

  // Activities
  static const String activities = '$gread/activity';
  static String activityComments(int activityId) => '$gread/activity/$activityId/comments';
  static const String createActivity = '$gread/activity';
  static String deleteActivity(int activityId) => '$gread/activity/$activityId';

  // Friends
  static const String friendRequest = '$gread/friends/request';
  static String friends(int userId) => '$gread/friends/$userId';
  static const String friendRequests = '$gread/friends/requests';
  static const String acceptFriendRequest = '$gread/friends/accept';
  static const String rejectFriendRequest = '$gread/friends/reject';
  static String removeFriend(int friendId) => '$gread/friends/$friendId';

  // Achievements
  static const String achievements = '$gread/achievements';
  static String userAchievements(int userId) => '$gread/user/$userId/achievements';
  static const String achievementsLeaderboard = '$gread/achievements/leaderboard';
  static const String checkAchievements = '$gread/me/achievements/check';

  // Moderation
  static const String blockUser = '$gread/user/block';
  static const String unblockUser = '$gread/user/unblock';
  static const String muteUser = '$gread/user/mute';
  static const String unmuteUser = '$gread/user/unmute';
  static const String reportUser = '$gread/user/report';
  static const String reportActivity = '$gread/activity/report';
  static const String blockedList = '$gread/user/blocked_list';
  static const String mutedList = '$gread/user/muted_list';

  // Mentions
  static const String mentionsSearch = '$gread/mentions/search';
  static String userMentions(int userId) => '$gread/user/$userId/mentions';
  static const String markMentionsRead = '$gread/me/mentions/read';

  // Notifications
  static const String notifications = '$buddyPress/notifications';
  static String deleteNotification(int id) => '$buddyPress/notifications/$id';

  // Search
  static const String searchMembers = '$gread/members/search';

  // Cosmetics
  static const String cosmetics = '$gread/cosmetics';
  static const String themes = '$gread/cosmetics/themes';
  static const String fonts = '$gread/cosmetics/fonts';
  static const String icons = '$gread/cosmetics/icons';

  // Library
  static const String library = '$gread/library';
  static const String addToLibrary = '$gread/library/add';
  static String updateLibraryItem(int itemId) => '$gread/library/$itemId';
  static String deleteLibraryItem(int itemId) => '$gread/library/$itemId';

  // Books
  static const String searchBooks = '$gread/books/search';
  static String bookDetails(int bookId) => '$gread/books/$bookId';
}
