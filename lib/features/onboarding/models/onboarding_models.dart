class OnboardingData {
  final String userName;
  final String goal;
  final int trainingDays;
  final String experience;
  final bool onboardingCompleted;

  const OnboardingData({
    required this.userName,
    required this.goal,
    required this.trainingDays,
    required this.experience,
    this.onboardingCompleted = false,
  });

  factory OnboardingData.defaults() => const OnboardingData(
        userName: '',
        goal: 'Ganar músculo',
        trainingDays: 3,
        experience: 'Intermedio',
        onboardingCompleted: false,
      );

  OnboardingData copyWith({
    String? userName,
    String? goal,
    int? trainingDays,
    String? experience,
    bool? onboardingCompleted,
  }) =>
      OnboardingData(
        userName: userName ?? this.userName,
        goal: goal ?? this.goal,
        trainingDays: trainingDays ?? this.trainingDays,
        experience: experience ?? this.experience,
        onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      );

  Map<String, dynamic> toJson() => {
        'userName': userName,
        'goal': goal,
        'trainingDays': trainingDays,
        'experience': experience,
        'onboardingCompleted': onboardingCompleted,
      };

  factory OnboardingData.fromJson(Map<String, dynamic> m) => OnboardingData(
        userName: m['userName'] as String? ?? '',
        goal: m['goal'] as String? ?? 'Ganar músculo',
        trainingDays: m['trainingDays'] as int? ?? 3,
        experience: m['experience'] as String? ?? 'Intermedio',
        onboardingCompleted: m['onboardingCompleted'] as bool? ?? false,
      );
}
