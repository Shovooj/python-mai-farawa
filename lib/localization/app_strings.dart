class AppStrings {
  static const Map<String, Map<String, String>> values = {
    'en': {
      'appTitle': 'Python Mai Farawa',
      'appTagline': 'Learn basic Python in Hausa language',

      'loginEmptyFields': 'Please enter your email and password.',
      'loginSuccessful': 'Login successful.',
      'welcomeBack': 'Welcome Back!',
      'loginSubtitle': 'Log in to continue learning',
      'continueWith': 'Continue with ',
      'google': 'Google',
      'continueWithApple': 'Continue with Apple',
      'or': 'or',
      'enterEmail': 'Please enter your email',
      'enterPassword': 'Please enter your password',
      'logIn': 'Log In',
      'noAccount': 'Don\'t have an account?',
      'signUp': 'Sign Up',

      'signupEmptyFields': 'Please fill in all fields.',
      'accountCreated': 'Account created successfully.',
      'startLearning': 'Start Learning!',
      'signupSubtitle': 'Create an account to begin today',
      'orEnterDetails': 'or enter your details',
      'fullName': 'Full name',
      'email': 'Email',
      'password': 'Password',
      'createAccount': 'Create Account',
      'alreadyHaveAccount': 'Already have an account?',

      'english': 'English',
      'hausa': 'Hausa',
      'languageDisplay': 'English | Hausa',

      // Home screen
      'errorLoadingLessons': 'Error loading lessons: ',
      'errorLoadingProgress': 'Error loading progress: ',
      'noLessonsAvailable': 'No lessons available right now.',
      'helloLearner': 'Hello, Learner!',
      'trackYourLearning': 'Track your learning',
      'completedSuffix': 'completed',
      'continueLearning': 'Continue Learning',
      'lessons': 'Lessons',
      'lesson': 'Lesson ',
      'home': 'Home',
      'progress': 'Progress',
      'settings': 'Settings',

      // Settings screen
      'defaultUser': 'User',
      'noEmailAvailable': 'No email available',
      'defaultInitial': 'U',
      'defaultLanguage': 'English',

      'selectLanguage': 'Select language',
      'language': 'Language',
      'languageChangedTo': 'Language changed to ',

      'aboutApp': 'About App',
      'aboutAppDescription':
          'Python Mai Farawa is a beginner friendly mobile learning application '
          'designed to help users learn basic Python programming step by step in a simple '
          'and accessible way.\n\n'
          'The app provides lessons, quizzes, practice exercises, learning progress '
          'tracking, and Hausa language support to improve the learning experience.\n\n'
          'This application was developed as part of a BSc software engineering '
          'project.',
      'close': 'Close',

      'logoutTitle': 'Logout?',
      'logoutConfirmation': 'Are you sure you want to logout?',
      'no': 'No',
      'yes': 'Yes',
      'logout': 'Logout',
      'deleteAccountTitle': 'Delete account?',
      'deleteAccountWarning':
          'This will permanently delete your account and profile data. '
          'This action cannot be undone.',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'deleteAccount': 'Delete account',

      'accountDeletedSuccessfully': 'Account deleted successfully',
      'failedToDeleteAccount': 'Failed to delete account. Please try again.',
      'requiresRecentLogin':
          'For security reasons, please log out, log in again, then try deleting your account.',
      'unexpectedDeleteError':
          'An unexpected error occurred while deleting the account.',
      'translateAllLessonsToHausa': 'Translate all lessons to Hausa',
      'translateAllQuizzesToHausa': 'Translate all quizzes to Hausa',
      'translateAllQuestionsToHausa': 'Translate all questions to Hausa',
      'translateAllPracticesToHausa': 'Translate all practices to Hausa',

      // Lesson List Screen
      'findALesson': 'Find a lesson',
      'allLessons': 'All lessons',
      'noLessonsFound': 'No lessons found.',

      // Progress Screen
      'completedLessons': 'Completed Lessons',
      'totalLessons': 'Total Lessons',
      'totalProgress': 'Total Progress',
      'videoTime': 'Video Time',
      'min': 'min',
      'ofCoursesCompleted': ' of the lessons completed',
      'noProgressYet': 'No progress yet. Start a lesson to see your progress.',
      'unknownLesson': 'Unknown Lesson',
      'quiz': 'Quiz',
      'practice': 'Practice',
      'video': 'Video',
      'done': 'Done',
      'notDone': 'Not done',

      // Lesson Detail Screen
      'noSignedInUserFound': 'No signed-in user found.',
      'videoDownloadedForOfflineUse': 'Video downloaded for offline use.',
      'videoDownloadFailed': 'Video download failed: ',
      'activeTabVideo': 'video',
      'offlineVideoNotAvailable': 'Offline video not available',
      'videoNotAvailableDownloadOnline':
          'Video not available. Download it while online for offline use.',
      'description': 'Description',
      'startQuiz': 'Start Quiz',
      'videoDownloadedOfflineLabel': 'Video Downloaded for Offline Use',
      'downloadVideoOfflineLabel': 'Download Video for Offline Use',

      // Quiz Screen
      'errorLoadingQuiz': 'Error loading quiz: ',
      'noQuizFoundForLesson': 'No quiz found for this lesson.',
      'errorLoadingQuestions': 'Error loading questions: ',
      'noQuestionsFoundForQuiz': 'No questions found for this quiz.',
      'question': 'Question',
      'of': 'of',
      'previousQuestion': 'Previous question',
      'submit': 'Submit',
      'nextQuestion': 'Next question',

      //Quiz result Screen
      'activeTabQuiz': 'quiz',
      'youPassed': 'You passed!',
      'youDidNotPass': 'You did not pass',
      'youScored': 'You scored',
      'outOf': 'out of',
      'passMark': 'Pass mark',
      'moveToPractice': 'Move to Practice',
      'tryAgain': 'Try Again',

      // Practice Screen
      'resultingCodeWillAppearHere': 'The resulting code will appear here.',
      'loadingPythonRunner': 'Loading Python runner...',
      'codeExecutedSuccessfullyWithNoOutput':
          'Code executed successfully with no output.',
      'failedToReadRunnerResponse': 'Failed to read runner response: ',
      'failedToInitializePythonRunner': 'Failed to initialize Python runner: ',
      'pythonRunnerStillLoading':
          'Python runner is still loading. Please wait a moment.',
      'pleaseWritePythonCodeBeforeRun':
          'Please write Python code before clicking Run.',
      'runningCode': 'Running code...',
      'pythonRunnerNotReadyYet': 'Python runner is not ready yet.',
      'failedToRunCode': 'Failed to run code: ',
      'yourCodeHasBeenCleared': 'Your code has been cleared.',
      'starterCodeRestored': 'Starter code restored.',
      'practiceTaskMarkedCompleted': 'Practice task marked as completed.',
      'noNextLessonFound':
          'No next lesson found. You have reached the last lesson.',
      'couldNotOpenNextLessonOfflineYet':
          'Could not open the next lesson offline yet. Please reconnect once to cache the next lesson.',
      'writePythonCodeHere': 'Write Python code here...',
      'output': 'Output',
      'expectedOutputPrefix': 'Expected output: ',
      'clearCode': 'Clear Code',
      'resetCode': 'Reset Code',
      'runCode': 'Run Code',
      'practiceCompleted': 'Practice Completed',
      'markPracticeCompleted': 'Mark Practice Completed',
      'nextLesson': 'Next Lesson',
      'goToHome': 'Go to Home',
      'lessonPrefix': 'Lesson ',
      'activeTabPractice': 'practice',
      'errorLoadingPractice': 'Error loading practice: ',
      'noPracticeFoundForThisLesson': 'No practice found for this lesson.',

      //lesson completion
      'lessonAlreadyCompleted': 'You already completed this lesson.',
    },

    'ha': {
      'appTitle': 'Python Mai Farawa',
      'appTagline': 'Koyi Python na asali a cikin harshen Hausa',

      'loginEmptyFields':
          'Da fatan a shigar da adireshin imel da kalmar sirri.',
      'loginSuccessful': 'Shiga ya yi nasara.',
      'welcomeBack': 'Barka da dawowa!',
      'loginSubtitle': 'Shiga don ci gaba da koyo',
      'continueWith': 'Ci gaba da',
      'google': 'Google',
      'continueWithApple': 'Ci gaba da Apple',
      'or': 'or',
      'enterEmail': 'Da fatan a shigar da imel ɗinka',
      'enterPassword': 'Da fatan a shigar da kalmar sirrinku',
      'logIn': 'Shiga',
      'noAccount': 'Ba ku da asusu?',
      'signUp': 'Yi Rijista',

      'signupEmptyFields': 'Da fatan za a cike dukkan filayen.',
      'accountCreated': 'An ƙirƙiri asusu cikin nasara.',
      'startLearning': 'Fara Koyo!',
      'signupSubtitle': 'Ƙirƙiri asusu don farawa a yau',
      'orEnterDetails': 'ko kuma shigar da bayananka',
      'fullName': 'Cikakken suna',
      'email': 'Imel',
      'password': 'Kalmar sirri',
      'createAccount': 'Kirkira ajiya',
      'alreadyHaveAccount': 'Kun riga kuna da asusu?',

      'english': 'Turanci',
      'hausa': 'Hausa',
      'languageDisplay': 'Turanci | Hausa',

      // Home screen
      'errorLoadingLessons': 'Kuskuren loda darussa: ',
      'errorLoadingProgress': 'Kuskuren ci gaban lodawa: ',
      'noLessonsAvailable': 'Babu darussa da ake da su a yanzu.',
      'helloLearner': 'Sannu, Ɗalibi!',
      'trackYourLearning': 'Bibiyar koyowarka',
      'completedSuffix': 'an kammala',
      'continueLearning': 'Ci gaba da Koyo',
      'lessons': 'Darussa',
      'lesson': 'Darasi ',
      'home': 'Gida',
      'progress': 'Ci gaba',
      'settings': 'Saituna',

      // Settings screen
      'defaultUser': 'Mai amfani',
      'noEmailAvailable': 'Babu imel da ake samu',
      'defaultInitial': 'M',
      'defaultLanguage': 'Turanci',

      'selectLanguage': 'Zaɓi harshe',
      'language': 'Harshe',
      'languageChangedTo': 'An canza harshe zuwa ',

      'aboutApp': 'Game da aikace-aikacen',
      'aboutAppDescription':
          'Python Mai Farawa manhaja ce ta koyon wayar hannu mai sauƙin farawa'
          'an tsara ta ne don taimaka wa masu amfani su koyi shirye-shiryen Python na asali mataki-mataki cikin sauƙi'
          'kuma ta hanya mai sauƙin isa.\n\n'
          'Manhajar tana ba da darussa, tambayoyi, darussan atisaye, ci gaban koyo'
          'bin diddigi, da tallafin harshen Hausa don inganta ƙwarewar koyo.\n\n'
          'An ƙirƙiri wannan manhajar a matsayin wani ɓangare na injiniyan software na BSc'
          'aikin.',
      'close': 'Rufe',

      'logoutTitle': 'Fita daga?',
      'logoutConfirmation': 'Shin ka tabbata kana son fita?',
      'no': 'A\'a',
      'yes': 'Ee',
      'logout': 'Fita daga',
      'deleteAccountTitle': 'Share asusu?',
      'deleteAccountWarning':
          'Wannan zai share asusunka da bayanan martaba na dindindin.'
          'Ba za a iya soke wannan aikin ba.',
      'cancel': 'Soke',
      'delete': 'goge',
      'deleteAccount': 'goge asusu',

      'accountDeletedSuccessfully': 'An goge asusu cikin nasara',
      'failedToDeleteAccount': 'Failed to delete account. Please try again.',
      'requiresRecentLogin':
          'For security reasons, please log out, log in again, then try deleting your account.',
      'unexpectedDeleteError':
          'An sami kuskuren da ba a zata ba yayin share asusun.',
      'translateAllLessonsToHausa': 'Translate all lessons to Hausa',
      'translateAllQuizzesToHausa': 'Fassara dukkan gwaje-gwaje zuwa Hausa',
      'translateAllQuestionsToHausa': 'Translate all questions to Hausa',
      'translateAllPracticesToHausa': 'Translate all practices to Hausa',

      // Lesson List Screen
      'findALesson': 'Find a lesson',
      'allLessons': 'Duk darussa',
      'noLessonsFound': 'Ba a sami darussa ba.',

      // Progress Screen
      'completedLessons': 'Darussa da aka kammala',
      'totalLessons': 'Jimlar Darussa',
      'totalProgress': 'Jimlar Ci gaba',
      'videoTime': 'Video Time',
      'min': 'min',
      'ofCoursesCompleted': ' na darussan da aka kammala',
      'noProgressYet': 'Babu ci gaba tukuna. Fara darasi don ganin ci gabanka.',
      'unknownLesson': 'Darasi da ba a sani ba',
      'quiz': 'Tambayoyi',
      'practice': 'Aiki',
      'video': 'bidiyo',
      'done': 'An gama',
      'notDone': 'Ba a yi ba',

      // Lesson Detail Screen
      'noSignedInUserFound': 'Babu wani mai amfani da aka shiga da aka samu.',
      'videoDownloadedForOfflineUse': 'an sauke bidiyo',
      'videoDownloadFailed': 'Ba a yi nasarar sauke bidiyo ba: ',
      'activeTabVideo': 'bidiyo',
      'offlineVideoNotAvailable':
          'Bidiyon da ba a haɗa shi da intanet ba ya samuwa',
      'videoNotAvailableDownloadOnline':
          'Bidiyo ba ya samuwa. Sauke shi yayin da ake amfani da shi a intanet don amfani da shi ba tare da intanet ba.',
      'description': 'Bayani',
      'startQuiz': 'Fara Tambayoyi',
      'videoDownloadedOfflineLabel':
          'An Sauke Bidiyo Don Amfani Ba Tare da Intanet Ba',
      'downloadVideoOfflineLabel':
          'Sauke Bidiyo don Amfani ba tare da Intanet ba',

      // Quiz Screen
      'errorLoadingQuiz': 'Kuskuren loda tambayoyin: ',
      'noQuizFoundForLesson': 'Ba a sami tambayoyi ba don wannan darasin.',
      'errorLoadingQuestions': 'Kuskuren loda tambayoyi: ',
      'noQuestionsFoundForQuiz':
          'Babu tambayoyi da aka samu don wannan jarabawar.',
      'question': 'Tambaya',
      'of': 'na',
      'previousQuestion': 'Tambayar da ta gabata',
      'submit': 'Aika',
      'nextQuestion': 'Tambaya ta gaba',

      //Quiz result Screen
      'activeTabQuiz': 'Tambayoyi',
      'youPassed': 'Ka wuce!',
      'youDidNotPass': 'Ba ka wuce ba',
      'youScored': 'Ka zira kwallaye',
      'outOf': 'daga',
      'passMark': 'Alamar wucewa:',
      'moveToPractice': 'Matsar zuwa Aiki',
      'tryAgain': 'Gwada kuma',

      // Practice Screen
      'resultingCodeWillAppearHere': 'Lambar da ta haifar za ta bayyana a nan.',
      'loadingPythonRunner': 'Ana loda Python runner...',
      'codeExecutedSuccessfullyWithNoOutput':
          'An aiwatar da lambar cikin nasara ba tare da fitarwa ba.',
      'failedToReadRunnerResponse': 'An kasa karanta martanin mai gudu: ',
      'failedToInitializePythonRunner': 'An kasa fara mai gudu na Python: ',
      'pythonRunnerStillLoading':
          'Python runner har yanzu yana lodawa. Da fatan za a jira ɗan lokaci.',
      'pleaseWritePythonCodeBeforeRun':
          'Da fatan a rubuta lambar Python kafin a danna Run.',
      'runningCode': 'Ana gudanar da lambar...',
      'pythonRunnerNotReadyYet': 'Python runner ba a shirye shi ba tukuna.',
      'failedToRunCode': 'An kasa gudanar da lambar: ',
      'yourCodeHasBeenCleared': 'Lambarka an share.',
      'starterCodeRestored': 'Lambar farawa an dawo.',
      'practiceTaskMarkedCompleted':
          'An yiwa aikin gwaji alama a matsayin an kammala shi.',
      'noNextLessonFound':
          'Babu wani darasi da aka samu. Kun kai darasin ƙarshe.',
      'couldNotOpenNextLessonOfflineYet':
          'Ban iya buɗe darasin na gaba ba tukuna. Da fatan za a sake haɗawa sau ɗaya don adana darasin na gaba.',
      'writePythonCodeHere': 'Rubuta lambar Python a nan...',
      'output': 'Fitarwa',
      'expectedOutputPrefix': 'Fitarwa da ake tsammani: ',
      'clearCode': 'Share Lambar',
      'resetCode': 'Reset Code',
      'runCode': 'Sake saita Lambar',
      'practiceCompleted': 'Aikin gwaji an kammala',
      'markPracticeCompleted': 'Alamar Aikin Gwaji An Kammala',
      'nextLesson': 'Darasi na Gaba',
      'goToHome': 'Je zuwa Gida',
      'lessonPrefix': 'Darasi ',
      'activeTabPractice': 'Aiki',
      'errorLoadingPractice': 'Kuskuren lodawa: ',
      'noPracticeFoundForThisLesson':
          'Ba a sami aikin gwaji ba don wannan darasin.',

      //lesson completion
      'lessonAlreadyCompleted': 'You already completed this lesson.',
    },
  };

  static String text(String lang, String key) {
    return values[lang]?[key] ?? values['en']![key]!;
  }
}

class AppKeys {
  static const String appLanguage = 'app_language';
}
