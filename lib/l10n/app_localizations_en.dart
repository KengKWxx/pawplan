// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PawPlan';

  @override
  String get pleaseLoginFirst => 'Please login first';

  @override
  String get calendar => 'Calendar';

  @override
  String get settings => 'Settings';

  @override
  String get welcomeBack => 'Welcome Back!';

  @override
  String get signInSubtitle => 'Sign in to continue to PawPlan';

  @override
  String get emailAddress => 'Email address';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get login => 'Log in';

  @override
  String get or => 'or';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get signUp => 'Sign up';

  @override
  String get loginSuccessfulTitle => 'Login Successful';

  @override
  String get loginSuccessfulMessage => 'Welcome back! You have successfully logged into your PawPlan account.';

  @override
  String get continueAction => 'Continue';

  @override
  String get emailNotFoundTitle => 'Email Not Found';

  @override
  String get emailNotFoundMessage => 'This email address is not registered in our system. Would you like to create a new account?';

  @override
  String get cancel => 'Cancel';

  @override
  String get createAccount => 'Create Account';

  @override
  String get loginFailedTitle => 'Login Failed';

  @override
  String get loginFailedMessage => 'The email address or password you entered is incorrect. Please check your credentials and try again.';

  @override
  String get forgotPasswordQuestion => 'Forgot Password?';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get tooManyRequests => 'Too many failed attempts. Please try again later.';

  @override
  String get networkError => 'Network error. Please check your internet connection.';

  @override
  String get genericLoginFailed => 'Login failed. Please try again.';

  @override
  String get unexpectedError => 'An unexpected error occurred. Please try again.';

  @override
  String get createAccountTitle => 'Create Account';

  @override
  String get createAccountSubtitle => 'Join PawPlan to take care of your pets';

  @override
  String get fullName => 'Full Name';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get signUpBtn => 'Sign Up';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get logIn => 'Log in';

  @override
  String get accountCreatedVerify => 'Account created! Please verify your email';

  @override
  String get weakPassword => 'The password provided is too weak';

  @override
  String get emailAlreadyInUse => 'An account already exists for that email';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get operationNotAllowed => 'Email/password accounts are not enabled';

  @override
  String get registrationFailed => 'Registration failed. Please try again';

  @override
  String get checkYourEmailTitle => 'Check Your Email!';

  @override
  String get passwordResetSent => '📧 Password reset link sent to your email';

  @override
  String get noAccountWithEmail => 'No account found with this email address';

  @override
  String get tooManyRequestsShort => 'Too many requests. Please try again later';

  @override
  String get errorOccurred => 'An error occurred. Please try again';

  @override
  String get enterYourEmail => 'Enter your email';

  @override
  String get resetHelper => 'We\'ll send a password reset link to this email';

  @override
  String get didntReceiveEmail => 'Didn\'t receive email? Try again';

  @override
  String get forgotPasswordTitle => 'Forgot Password?';

  @override
  String get forgotPasswordDesc => 'Don\'t worry! Enter your email address and we\'ll send you a reset link';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get checkSpam => 'Check your spam folder if you don\'t receive the email within a few minutes';

  @override
  String get rememberPassword => 'Remember your password? ';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get home => 'Home';

  @override
  String get pets => 'Pets';

  @override
  String get tasks => 'Tasks';

  @override
  String get recentPets => 'Recent Pets';

  @override
  String get noPetsYet => 'No pets yet';

  @override
  String get recentTasks => 'Recent Tasks';

  @override
  String get noTasksYet => 'No tasks yet';

  @override
  String get addPet => 'Add Pet';

  @override
  String get addTask => 'Add Task';

  @override
  String hiUser(Object name) {
    return 'Hi. $name';
  }

  @override
  String get setAsFavorite => 'Set as Favorite';

  @override
  String get viewHealthDetails => 'View Health Details';

  @override
  String get vaccinations => 'Vaccinations';

  @override
  String get deworming => 'Deworming';

  @override
  String get allergies => 'Allergies';

  @override
  String get noHealthInfoYet => 'No health info yet';

  @override
  String get close => 'Close';

  @override
  String get showQrCode => 'Show QR Code';

  @override
  String get failedToLoadTasks => 'Failed to load tasks';

  @override
  String get searchTasks => 'Search tasks...';

  @override
  String get all => 'All';

  @override
  String get today => 'Today';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get missed => 'Missed';

  @override
  String get done => 'Done';

  @override
  String get confirm => 'Confirm';

  @override
  String get delete => 'Delete';

  @override
  String get deleteSelected => 'Delete Selected';

  @override
  String deleteNTasks(Object count) {
    return 'Delete $count task(s)?';
  }

  @override
  String get markDone => 'Mark Done';

  @override
  String get petQrCode => 'Pet QR Code';

  @override
  String get pleaseLogin => 'Please login';

  @override
  String get pleaseLoginFirstShort => 'Please login first';

  @override
  String get enterEmailAddress => 'Please enter your email address';

  @override
  String get enterValidEmailAddress => 'Please enter a valid email address';

  @override
  String get enterPassword => 'Please enter your password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get enterEmail => 'Please enter your email';

  @override
  String get enterFullName => 'Please enter your full name';

  @override
  String get nameMinLength => 'Name must be at least 2 characters';

  @override
  String get enterAPassword => 'Please enter a password';

  @override
  String get passwordLettersNumbers => 'Password must contain letters and numbers';

  @override
  String get confirmYourPassword => 'Please confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get noPetProvidedQr => 'No pet provided to QR screen. Please open from a pet card.';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get saveFailed => 'Save failed';
}
