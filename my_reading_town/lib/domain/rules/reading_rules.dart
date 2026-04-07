class ReadingRules {
  static const int dailyPageLimit = 200;
  static const int coinsPerPage = 3;
  static const int woodPerPage = 2;
  static const int metalPerPage = 1;
  static const int bookCompletionGemBonus = 20;
  static const int bookCompletionCoinBonus = 50;

  static Map<String, int> calculatePageRewards({
    required int actualPagesLogged,
    required bool isBookNowCompleted,
    required bool wasAlreadyCompleted,
  }) {
    if (actualPagesLogged <= 0) {
      return {'coins': 0, 'gems': 0, 'wood': 0, 'metal': 0, 'exp': 0};
    }

    int coinsEarned = actualPagesLogged * coinsPerPage;
    int gemsEarned = 0;
    int woodEarned = actualPagesLogged * woodPerPage;
    int metalEarned = actualPagesLogged * metalPerPage;

    if (isBookNowCompleted && !wasAlreadyCompleted) {
      coinsEarned += bookCompletionCoinBonus;
      gemsEarned += bookCompletionGemBonus;
    }

    return {
      'coins': coinsEarned,
      'gems': gemsEarned,
      'wood': woodEarned,
      'metal': metalEarned,
      'exp': 0,
    };
  }
}
