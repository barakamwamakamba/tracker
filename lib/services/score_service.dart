class ScoreService {
  double calculateScore({
    required int totalGoals,
    required int completedGoals,
  }) {
    if (totalGoals <= 0) {
      return 0;
    }

    return (completedGoals / totalGoals) * 100;
  }

  String getLabel(double score) {
    if (score >= 80) {
      return 'High';
    }
    if (score >= 50) {
      return "Avarage";
    }
    if (score > 0) {
      return 'low';
    }

    return 'Nothing completed';
  }

  int getDisplayedScore({
    required int totalGoals,
    required int completedGoals,
  }) {
    return calculateScore(
      totalGoals: totalGoals,
      completedGoals: completedGoals,
    ).round();
  }
}
