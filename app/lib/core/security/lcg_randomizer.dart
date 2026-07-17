import '../constants/app_constants.dart';

class LCG {
  int _state;
  final int _initial;

  LCG(int seed)
      : _state   = seed & 0xFFFFFFFF,
        _initial = seed & 0xFFFFFFFF;

  int next() {
    _state = (AppConstants.lcgA * _state + AppConstants.lcgC) % AppConstants.lcgM;
    return _state;
  }

  void reset() => _state = _initial;

  List<T> shuffle<T>(List<T> array) {
    final arr = List<T>.from(array);
    for (int i = arr.length - 1; i > 0; i--) {
      final j = next() % (i + 1);
      final tmp = arr[i]; arr[i] = arr[j]; arr[j] = tmp;
    }
    return arr;
  }

  List<int> verify(int steps) {
    final orig = _state;
    _state = _initial;
    final out = [for (int i = 0; i < steps; i++) next()];
    _state = orig;
    return out;
  }
}

class ShuffledOptions {
  final Map<String, String> options;
  final String              correctKey;
  final Map<String, String> keyMap;
  const ShuffledOptions({required this.options, required this.correctKey, required this.keyMap});
}

class ExamQuestion {
  final int                  id;
  final String               questionText;
  final String               questionType;
  final Map<String, String>? options;
  final String?              correctAnswer;
  final String?              shuffledCorrect;
  final String?              originalCorrect;
  final String?              explanation;
  final String?              imageUrl;

  const ExamQuestion({
    required this.id,
    required this.questionText,
    required this.questionType,
    this.options,
    this.correctAnswer,
    this.shuffledCorrect,
    this.originalCorrect,
    this.explanation,
    this.imageUrl,
  });

  factory ExamQuestion.fromJson(Map<String, dynamic> j) => ExamQuestion(
    id:           j['id'] as int,
    questionText: j['question_text'] as String? ?? j['text'] as String? ?? '',
    questionType: j['question_type'] as String? ?? 'multiple_choice',
    options:      ((j['options'] is Map) ? (j['options'] as Map).cast<String, String>() : null),
    correctAnswer:j['correct_answer'] as String?,
    explanation:  j['explanation']   as String?,
    imageUrl:     j['image_url']     as String?,
  );

  ExamQuestion copyWith({
    Map<String, String>? options,
    String?              shuffledCorrect,
    String?              originalCorrect,
    String?              imageUrl,
  }) => ExamQuestion(
    id: id, questionText: questionText, questionType: questionType,
    explanation: explanation,
    correctAnswer:   correctAnswer,
    options:         options         ?? this.options,
    shuffledCorrect: shuffledCorrect ?? this.shuffledCorrect,
    originalCorrect: originalCorrect ?? this.originalCorrect,
    imageUrl:        imageUrl        ?? this.imageUrl,
  );
}

class ExamRandomizer {
  final int globalSeed;
  ExamRandomizer(this.globalSeed);

  List<T> shuffleQuestions<T>(List<T> questions) => LCG(globalSeed).shuffle(questions);

  ShuffledOptions shuffleOptions(Map<String, String> options, String correctAnswer, int questionId) {
    if (options.isEmpty) return ShuffledOptions(options: options, correctKey: correctAnswer, keyMap: {});
    final seedForQ = (globalSeed + questionId) & 0xFFFFFFFF;
    final lcg      = LCG(seedForQ);
    final origKeys   = options.keys.toList();
    final origValues = options.values.toList();
    final shuffVals  = lcg.shuffle(origValues);
    final newOptions = <String, String>{};
    final keyMap     = <String, String>{};
    for (int i = 0; i < origKeys.length; i++) {
      final newKey = origKeys[i];
      newOptions[newKey] = shuffVals[i];
      final oldKey = origKeys[origValues.indexOf(shuffVals[i])];
      keyMap[oldKey] = newKey;
    }
    return ShuffledOptions(options: newOptions, correctKey: keyMap[correctAnswer] ?? correctAnswer, keyMap: keyMap);
  }

  List<ExamQuestion> process(List<ExamQuestion> questions, {bool doShuffleQ = true, bool doShuffleO = true}) {
    var processed = doShuffleQ ? shuffleQuestions(questions) : List<ExamQuestion>.from(questions);
    if (!doShuffleO) return processed;
    return processed.map((q) {
      if (q.questionType != 'multiple_choice' || q.options == null) return q;
      final s = shuffleOptions(q.options!, q.correctAnswer ?? '', q.id);
      return q.copyWith(options: s.options, shuffledCorrect: s.correctKey, originalCorrect: q.correctAnswer);
    }).toList();
  }

  static bool isCorrect(ExamQuestion q, String? answer) {
    if (answer == null || answer.isEmpty) return false;
    return answer.toUpperCase() == (q.shuffledCorrect ?? q.correctAnswer ?? '').toUpperCase();
  }

  List<int> verifySeed(int steps) => LCG(globalSeed).verify(steps);

  static int generateSeed() {
    final t = DateTime.now().millisecondsSinceEpoch;
    return (t ^ (t >> 16)) & 0x7FFFFFFF;
  }
}
