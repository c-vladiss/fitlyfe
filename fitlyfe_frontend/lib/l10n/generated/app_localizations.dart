import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome to FitLyfe'**
  String get welcomeMessage;

  /// No description provided for @startWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start Workout'**
  String get startWorkout;

  /// No description provided for @nextStep.
  ///
  /// In en, this message translates to:
  /// **'Next Step'**
  String get nextStep;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @calories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get calories;

  /// No description provided for @steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get steps;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to FitLyfe'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your personal fitness companion.'**
  String get welcomeSubtitle;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get languageTitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This will help us translate the app for you.'**
  String get languageSubtitle;

  /// No description provided for @nameTitle.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get nameTitle;

  /// No description provided for @nameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll use this to personalize your experience.'**
  String get nameSubtitle;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get yourName;

  /// No description provided for @dobTitle.
  ///
  /// In en, this message translates to:
  /// **'When were you born?'**
  String get dobTitle;

  /// No description provided for @dobSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your age helps us personalize your fitness plan.'**
  String get dobSubtitle;

  /// No description provided for @heightTitle.
  ///
  /// In en, this message translates to:
  /// **'How tall are you?'**
  String get heightTitle;

  /// No description provided for @heightSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This helps us calculate your BMI.'**
  String get heightSubtitle;

  /// No description provided for @weightTitle.
  ///
  /// In en, this message translates to:
  /// **'What is your current weight?'**
  String get weightTitle;

  /// No description provided for @weightSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can update this any time.'**
  String get weightSubtitle;

  /// No description provided for @goalTitle.
  ///
  /// In en, this message translates to:
  /// **'Finally, what is your main goal?'**
  String get goalTitle;

  /// No description provided for @goalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll customize your plan based on this choice.'**
  String get goalSubtitle;

  /// No description provided for @streakTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open the app daily to increase your streak and earn achievements!'**
  String get streakTooltip;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get last7Days;

  /// No description provided for @caloriesBurnt.
  ///
  /// In en, this message translates to:
  /// **'Calories Burnt'**
  String get caloriesBurnt;

  /// No description provided for @stepsCount.
  ///
  /// In en, this message translates to:
  /// **'Steps Count'**
  String get stepsCount;

  /// No description provided for @kcalLeft.
  ///
  /// In en, this message translates to:
  /// **'KCAL LEFT'**
  String get kcalLeft;

  /// No description provided for @nutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get nutrition;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @workout.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get workout;

  /// No description provided for @ai.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get ai;

  /// No description provided for @loseWeight.
  ///
  /// In en, this message translates to:
  /// **'Lose Weight'**
  String get loseWeight;

  /// No description provided for @buildMuscle.
  ///
  /// In en, this message translates to:
  /// **'Build Muscle'**
  String get buildMuscle;

  /// No description provided for @stayFit.
  ///
  /// In en, this message translates to:
  /// **'Stay Fit'**
  String get stayFit;

  /// No description provided for @improveEndurance.
  ///
  /// In en, this message translates to:
  /// **'Improve Endurance'**
  String get improveEndurance;

  /// No description provided for @protein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get protein;

  /// No description provided for @carbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get carbs;

  /// No description provided for @fats.
  ///
  /// In en, this message translates to:
  /// **'Fats'**
  String get fats;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @todaySummary.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Summary'**
  String get todaySummary;

  /// No description provided for @activeTime.
  ///
  /// In en, this message translates to:
  /// **'Active Time'**
  String get activeTime;

  /// No description provided for @dailyTips.
  ///
  /// In en, this message translates to:
  /// **'Daily Tips'**
  String get dailyTips;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @workoutDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get workoutDuration;

  /// No description provided for @workoutDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get workoutDifficulty;

  /// No description provided for @workoutCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get workoutCalories;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals;

  /// No description provided for @tipsToImprove.
  ///
  /// In en, this message translates to:
  /// **'Tips to improve'**
  String get tipsToImprove;

  /// No description provided for @askAi.
  ///
  /// In en, this message translates to:
  /// **'Ask AI Coach'**
  String get askAi;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'REMAINING'**
  String get remaining;

  /// No description provided for @viewMeals.
  ///
  /// In en, this message translates to:
  /// **'View Meals'**
  String get viewMeals;

  /// No description provided for @viewStats.
  ///
  /// In en, this message translates to:
  /// **'View Stats'**
  String get viewStats;

  /// No description provided for @todayGoals.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Goals'**
  String get todayGoals;

  /// No description provided for @dailyGoals.
  ///
  /// In en, this message translates to:
  /// **'Daily Goals'**
  String get dailyGoals;

  /// No description provided for @expertTips.
  ///
  /// In en, this message translates to:
  /// **'Expert Tips'**
  String get expertTips;

  /// No description provided for @recommendedForYou.
  ///
  /// In en, this message translates to:
  /// **'Recommended for You'**
  String get recommendedForYou;

  /// No description provided for @yourGoal.
  ///
  /// In en, this message translates to:
  /// **'Your Goal'**
  String get yourGoal;

  /// No description provided for @workoutLogBook.
  ///
  /// In en, this message translates to:
  /// **'Workout Log Book'**
  String get workoutLogBook;

  /// No description provided for @trackYourGains.
  ///
  /// In en, this message translates to:
  /// **'Track your gains'**
  String get trackYourGains;

  /// No description provided for @logSession.
  ///
  /// In en, this message translates to:
  /// **'Log Session'**
  String get logSession;

  /// No description provided for @restTimer.
  ///
  /// In en, this message translates to:
  /// **'Rest Timer'**
  String get restTimer;

  /// No description provided for @currentRoutine.
  ///
  /// In en, this message translates to:
  /// **'Current Routine'**
  String get currentRoutine;

  /// No description provided for @activeWorkout.
  ///
  /// In en, this message translates to:
  /// **'Active Workout'**
  String get activeWorkout;

  /// No description provided for @exercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get exercises;

  /// No description provided for @exerciseName.
  ///
  /// In en, this message translates to:
  /// **'Exercise Name'**
  String get exerciseName;

  /// No description provided for @enterExerciseName.
  ///
  /// In en, this message translates to:
  /// **'Enter exercise name'**
  String get enterExerciseName;

  /// No description provided for @sets.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get sets;

  /// No description provided for @reps.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get reps;

  /// No description provided for @logSet.
  ///
  /// In en, this message translates to:
  /// **'LOG SET'**
  String get logSet;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @years_old.
  ///
  /// In en, this message translates to:
  /// **'years old'**
  String get years_old;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @manualHeightEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual Height Entry'**
  String get manualHeightEntry;

  /// No description provided for @manualWeightEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual Weight Entry'**
  String get manualWeightEntry;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @personalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal Details'**
  String get personalDetails;

  /// No description provided for @privacySecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacySecurity;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @nameEmail.
  ///
  /// In en, this message translates to:
  /// **'Name,Email'**
  String get nameEmail;

  /// No description provided for @password2fa.
  ///
  /// In en, this message translates to:
  /// **'Password, 2FA'**
  String get password2fa;

  /// No description provided for @pushEmail.
  ///
  /// In en, this message translates to:
  /// **'Push, Email'**
  String get pushEmail;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistant;

  /// No description provided for @aiCoachIntro.
  ///
  /// In en, this message translates to:
  /// **'Hi! I\'m your AI Fitness Coach. Ask me about workouts, nutrition, or motivation!'**
  String get aiCoachIntro;

  /// No description provided for @askAnything.
  ///
  /// In en, this message translates to:
  /// **'Ask anything...'**
  String get askAnything;

  /// No description provided for @bodyType.
  ///
  /// In en, this message translates to:
  /// **'Body Type'**
  String get bodyType;

  /// No description provided for @consistencyTips.
  ///
  /// In en, this message translates to:
  /// **'Consistency Tips'**
  String get consistencyTips;

  /// No description provided for @dailyQuote.
  ///
  /// In en, this message translates to:
  /// **'Daily Quote'**
  String get dailyQuote;

  /// No description provided for @restPeriodCompleted.
  ///
  /// In en, this message translates to:
  /// **'Rest period completed!'**
  String get restPeriodCompleted;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'PAUSE'**
  String get pause;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get start;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'RESET'**
  String get reset;

  /// No description provided for @quickSelect.
  ///
  /// In en, this message translates to:
  /// **'Quick Select'**
  String get quickSelect;

  /// No description provided for @totalWorkout.
  ///
  /// In en, this message translates to:
  /// **'TOTAL WORKOUT'**
  String get totalWorkout;

  /// No description provided for @totalSteps.
  ///
  /// In en, this message translates to:
  /// **'TOTAL STEPS'**
  String get totalSteps;

  /// No description provided for @weightLost.
  ///
  /// In en, this message translates to:
  /// **'WEIGHT LOST'**
  String get weightLost;

  /// No description provided for @avgCalories.
  ///
  /// In en, this message translates to:
  /// **'AVG CALORIES'**
  String get avgCalories;

  /// No description provided for @hrs.
  ///
  /// In en, this message translates to:
  /// **'HRS'**
  String get hrs;

  /// No description provided for @k.
  ///
  /// In en, this message translates to:
  /// **'K'**
  String get k;

  /// No description provided for @kg.
  ///
  /// In en, this message translates to:
  /// **'KG'**
  String get kg;

  /// No description provided for @kcal.
  ///
  /// In en, this message translates to:
  /// **'KCAL'**
  String get kcal;

  /// No description provided for @mins.
  ///
  /// In en, this message translates to:
  /// **'MINS'**
  String get mins;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @unlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get unlocked;

  /// No description provided for @macronutrients.
  ///
  /// In en, this message translates to:
  /// **'Macronutrients'**
  String get macronutrients;

  /// No description provided for @micronutrients.
  ///
  /// In en, this message translates to:
  /// **'Micronutrients'**
  String get micronutrients;

  /// No description provided for @dailyValue.
  ///
  /// In en, this message translates to:
  /// **'% Daily Value'**
  String get dailyValue;

  /// No description provided for @todayLog.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Log'**
  String get todayLog;

  /// No description provided for @addFood.
  ///
  /// In en, this message translates to:
  /// **'ADD FOOD'**
  String get addFood;

  /// No description provided for @noFoodLogged.
  ///
  /// In en, this message translates to:
  /// **'No food logged today'**
  String get noFoodLogged;

  /// No description provided for @foodName.
  ///
  /// In en, this message translates to:
  /// **'Food Name'**
  String get foodName;

  /// No description provided for @foodNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Oatmeal with Berries'**
  String get foodNameHint;

  /// No description provided for @proteinG.
  ///
  /// In en, this message translates to:
  /// **'Protein (g)'**
  String get proteinG;

  /// No description provided for @carbsG.
  ///
  /// In en, this message translates to:
  /// **'Carbs (g)'**
  String get carbsG;

  /// No description provided for @fatsG.
  ///
  /// In en, this message translates to:
  /// **'Fats (g)'**
  String get fatsG;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @presets.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get presets;

  /// No description provided for @weightG.
  ///
  /// In en, this message translates to:
  /// **'Weight (g)'**
  String get weightG;

  /// No description provided for @searchFoods.
  ///
  /// In en, this message translates to:
  /// **'Search foods...'**
  String get searchFoods;

  /// No description provided for @per100g.
  ///
  /// In en, this message translates to:
  /// **'per 100g'**
  String get per100g;

  /// No description provided for @addVitamin.
  ///
  /// In en, this message translates to:
  /// **'ADD VITAMIN'**
  String get addVitamin;

  /// No description provided for @vitaminType.
  ///
  /// In en, this message translates to:
  /// **'Vitamin Type'**
  String get vitaminType;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @primaryGoal.
  ///
  /// In en, this message translates to:
  /// **'Primary Goal'**
  String get primaryGoal;

  /// No description provided for @selectGoal.
  ///
  /// In en, this message translates to:
  /// **'Select Goal'**
  String get selectGoal;

  /// No description provided for @goalUpdatedTo.
  ///
  /// In en, this message translates to:
  /// **'Goal updated to'**
  String get goalUpdatedTo;

  /// No description provided for @chooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose Theme'**
  String get chooseTheme;

  /// No description provided for @colorTheme.
  ///
  /// In en, this message translates to:
  /// **'Color Theme'**
  String get colorTheme;

  /// No description provided for @tipDeficit.
  ///
  /// In en, this message translates to:
  /// **'Maintain a slight calorie deficit (200-500 kcal)'**
  String get tipDeficit;

  /// No description provided for @tipProtein.
  ///
  /// In en, this message translates to:
  /// **'Prioritize high-protein meals to stay full'**
  String get tipProtein;

  /// No description provided for @tipVeggies.
  ///
  /// In en, this message translates to:
  /// **'Focus on high-volume, low-calorie foods (veggies)'**
  String get tipVeggies;

  /// No description provided for @exBurpeesName.
  ///
  /// In en, this message translates to:
  /// **'Burpees'**
  String get exBurpeesName;

  /// No description provided for @exBurpeesDesc.
  ///
  /// In en, this message translates to:
  /// **'Full body burn'**
  String get exBurpeesDesc;

  /// No description provided for @exJumpRopeName.
  ///
  /// In en, this message translates to:
  /// **'Jump Rope'**
  String get exJumpRopeName;

  /// No description provided for @exJumpRopeDesc.
  ///
  /// In en, this message translates to:
  /// **'High intensity'**
  String get exJumpRopeDesc;

  /// No description provided for @exSprintingName.
  ///
  /// In en, this message translates to:
  /// **'Sprinting'**
  String get exSprintingName;

  /// No description provided for @exSprintingDesc.
  ///
  /// In en, this message translates to:
  /// **'Max calorie burn'**
  String get exSprintingDesc;

  /// No description provided for @tipOverload.
  ///
  /// In en, this message translates to:
  /// **'Focus on progressive overload each week'**
  String get tipOverload;

  /// No description provided for @tipSleep.
  ///
  /// In en, this message translates to:
  /// **'Get 7-9 hours of quality sleep for recovery'**
  String get tipSleep;

  /// No description provided for @tipProteinKg.
  ///
  /// In en, this message translates to:
  /// **'Consume 1.8g+ of protein per kg of bodyweight'**
  String get tipProteinKg;

  /// No description provided for @exSquatsName.
  ///
  /// In en, this message translates to:
  /// **'Squats'**
  String get exSquatsName;

  /// No description provided for @exSquatsDesc.
  ///
  /// In en, this message translates to:
  /// **'Leg powerhouse'**
  String get exSquatsDesc;

  /// No description provided for @exDeadliftsName.
  ///
  /// In en, this message translates to:
  /// **'Deadlifts'**
  String get exDeadliftsName;

  /// No description provided for @exDeadliftsDesc.
  ///
  /// In en, this message translates to:
  /// **'Overall strength'**
  String get exDeadliftsDesc;

  /// No description provided for @exBenchPressName.
  ///
  /// In en, this message translates to:
  /// **'Bench Press'**
  String get exBenchPressName;

  /// No description provided for @exBenchPressDesc.
  ///
  /// In en, this message translates to:
  /// **'Upper body push'**
  String get exBenchPressDesc;

  /// No description provided for @tipMileage.
  ///
  /// In en, this message translates to:
  /// **'Gradually increase your weekly mileage'**
  String get tipMileage;

  /// No description provided for @tipInterval.
  ///
  /// In en, this message translates to:
  /// **'Incorporate interval training for oxygen efficiency'**
  String get tipInterval;

  /// No description provided for @tipHydration.
  ///
  /// In en, this message translates to:
  /// **'Stay consistent with your hydration strategy'**
  String get tipHydration;

  /// No description provided for @exRunningName.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get exRunningName;

  /// No description provided for @exRunningDesc.
  ///
  /// In en, this message translates to:
  /// **'Classic cardio'**
  String get exRunningDesc;

  /// No description provided for @exCyclingName.
  ///
  /// In en, this message translates to:
  /// **'Cycling'**
  String get exCyclingName;

  /// No description provided for @exCyclingDesc.
  ///
  /// In en, this message translates to:
  /// **'Steady pace'**
  String get exCyclingDesc;

  /// No description provided for @exSwimmingName.
  ///
  /// In en, this message translates to:
  /// **'Swimming'**
  String get exSwimmingName;

  /// No description provided for @exSwimmingDesc.
  ///
  /// In en, this message translates to:
  /// **'Full body endurance'**
  String get exSwimmingDesc;

  /// No description provided for @tipHolistic.
  ///
  /// In en, this message translates to:
  /// **'Mix strength and cardio for holistic health'**
  String get tipHolistic;

  /// No description provided for @tipNeat.
  ///
  /// In en, this message translates to:
  /// **'Stay active outside the gym (NEAT)'**
  String get tipNeat;

  /// No description provided for @tipWholeFoods.
  ///
  /// In en, this message translates to:
  /// **'Eat a diverse range of whole foods'**
  String get tipWholeFoods;

  /// No description provided for @exYogaName.
  ///
  /// In en, this message translates to:
  /// **'Yoga'**
  String get exYogaName;

  /// No description provided for @exYogaDesc.
  ///
  /// In en, this message translates to:
  /// **'Flexibility & flow'**
  String get exYogaDesc;

  /// No description provided for @exPlankName.
  ///
  /// In en, this message translates to:
  /// **'Plank'**
  String get exPlankName;

  /// No description provided for @exPlankDesc.
  ///
  /// In en, this message translates to:
  /// **'Core stability'**
  String get exPlankDesc;

  /// No description provided for @exHikingName.
  ///
  /// In en, this message translates to:
  /// **'Hiking'**
  String get exHikingName;

  /// No description provided for @exHikingDesc.
  ///
  /// In en, this message translates to:
  /// **'Active recovery'**
  String get exHikingDesc;

  /// No description provided for @connectHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to Health Services'**
  String get connectHealthTitle;

  /// No description provided for @connectHealthDesc.
  ///
  /// In en, this message translates to:
  /// **'Sync your steps and workout time automatically.'**
  String get connectHealthDesc;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'CONNECT'**
  String get connect;

  /// No description provided for @healthyRecipes.
  ///
  /// In en, this message translates to:
  /// **'Healthy Recipes'**
  String get healthyRecipes;

  /// No description provided for @lowCalOptions.
  ///
  /// In en, this message translates to:
  /// **'Low Calorie Options'**
  String get lowCalOptions;

  /// No description provided for @searchLanguage.
  ///
  /// In en, this message translates to:
  /// **'Search language...'**
  String get searchLanguage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'it',
    'ja',
    'ko',
    'nl',
    'pl',
    'pt',
    'ru',
    'tr',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
