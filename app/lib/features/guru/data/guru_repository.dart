import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'guru_models.dart';

class GuruRepository {
  Future<Map<String, dynamic>> getDashboard() async {
    try { return await ApiClient.get('/guru/dashboard') as Map<String, dynamic>; }
    on ApiException { rethrow; }
  }

  Future<List<ExamModel>> getExams({String? status, int page = 1}) async {
    final data = await ApiClient.get('/guru/exams', params: {'status': status, 'page': page, 'per_page': 15});
    final list = (data['data'] as List?) ?? (data as List? ?? []);
    return list.map((e) => ExamModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ClassRoomModel>> getClasses() async {
    final data = await ApiClient.get('/guru/classes');
    return ((data['data'] as List?) ?? []).map((e) => ClassRoomModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<QuestionModel> createQuestion(Map<String, dynamic> payload) async {
    final data = await ApiClient.post('/guru/questions', data: payload);
    return QuestionModel.fromJson(data['question'] as Map<String, dynamic>);
  }

  Future<QuestionModel> updateQuestion(int id, Map<String, dynamic> payload) async {
    final data = await ApiClient.put('/guru/questions/$id', data: payload);
    return QuestionModel.fromJson(data['question'] as Map<String, dynamic>);
  }

  Future<QuestionModel> updateQuestionWithImage({
    required int id,
    required String questionText,
    required Map<String, String> options,
    required String correctAnswer,
    required String difficulty,
    required double weight,
    String? explanation,
    String? categoryId,
    String? imagePath,
    Uint8List? imageBytes,
    String? imageName,
    bool removeImage = false,
  }) async {
    if (imagePath != null) {
      final fields = <String, dynamic>{
        'question_text': questionText,
        'correct_answer': correctAnswer,
        'difficulty': difficulty,
        'weight': weight.toString(),
        'remove_image': removeImage.toString(),
        if (explanation != null) 'explanation': explanation,
        if (categoryId != null) 'category_id': categoryId,
      };
      options.forEach((k, v) => fields['options[$k]'] = v);
      final data = await ApiClient.uploadFile('/guru/questions/$id', 'image', imagePath, fields, method: 'PUT');
      return QuestionModel.fromJson(data['question'] as Map<String, dynamic>);
    }
    if (imageBytes != null) {
      final fields = <String, dynamic>{
        'question_text': questionText,
        'correct_answer': correctAnswer,
        'difficulty': difficulty,
        'weight': weight.toString(),
        'remove_image': removeImage.toString(),
        if (explanation != null) 'explanation': explanation,
        if (categoryId != null) 'category_id': categoryId,
      };
      options.forEach((k, v) => fields['options[$k]'] = v);
      final data = await ApiClient.uploadFileBytes('/guru/questions/$id', 'image', imageBytes, imageName ?? 'image.jpg', fields, method: 'PUT');
      return QuestionModel.fromJson(data['question'] as Map<String, dynamic>);
    }
    final data = await ApiClient.put('/guru/questions/$id', data: {
      'question_text': questionText,
      'options': options,
      'correct_answer': correctAnswer,
      'difficulty': difficulty,
      'weight': weight.toString(),
      if (explanation != null) 'explanation': explanation,
      if (categoryId != null) 'category_id': categoryId,
    });
    return QuestionModel.fromJson(data['question'] as Map<String, dynamic>);
  }

  Future<QuestionModel> createQuestionWithImage({
    required String questionText,
    required Map<String, String> options,
    required String correctAnswer,
    required String difficulty,
    required double weight,
    String? explanation,
    String? categoryId,
    int? subjectId,
    String? imagePath,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    if (imagePath != null) {
      final fields = <String, dynamic>{
        'question_text': questionText,
        'correct_answer': correctAnswer,
        'difficulty': difficulty,
        'weight': weight.toString(),
        if (subjectId != null) 'subject_id': subjectId,
        if (explanation != null) 'explanation': explanation,
        if (categoryId != null) 'category_id': categoryId,
      };
      options.forEach((k, v) => fields['options[$k]'] = v);
      final data = await ApiClient.uploadFile('/guru/questions', 'image', imagePath, fields);
      return QuestionModel.fromJson(data['question'] as Map<String, dynamic>);
    }
    if (imageBytes != null) {
      final fields = <String, dynamic>{
        'question_text': questionText,
        'correct_answer': correctAnswer,
        'difficulty': difficulty,
        'weight': weight.toString(),
        if (subjectId != null) 'subject_id': subjectId,
        if (explanation != null) 'explanation': explanation,
        if (categoryId != null) 'category_id': categoryId,
      };
      options.forEach((k, v) => fields['options[$k]'] = v);
      final data = await ApiClient.uploadFileBytes('/guru/questions', 'image', imageBytes, imageName ?? 'image.jpg', fields);
      return QuestionModel.fromJson(data['question'] as Map<String, dynamic>);
    }
    final data = await ApiClient.post('/guru/questions', data: {
      'question_text': questionText,
      'options': options,
      'correct_answer': correctAnswer,
      'difficulty': difficulty,
      'weight': weight.toString(),
      if (subjectId != null) 'subject_id': subjectId,
      if (explanation != null) 'explanation': explanation,
      if (categoryId != null) 'category_id': categoryId,
    });
    return QuestionModel.fromJson(data['question'] as Map<String, dynamic>);
  }

  Future<void> deleteQuestion(int id) => ApiClient.delete('/guru/questions/$id');

  Future<ExamModel> createExam(Map<String, dynamic> payload) async {
    final data = await ApiClient.post('/guru/exams', data: payload);
    return ExamModel.fromJson(data['exam'] as Map<String, dynamic>);
  }

  Future<ExamModel> updateExam(int id, Map<String, dynamic> payload) async {
    final data = await ApiClient.put('/guru/exams/$id', data: payload);
    return ExamModel.fromJson(data['exam'] as Map<String, dynamic>);
  }

  // Aktivasi dipindah ke admin — panggil lewat repo admin
  Future<void> pauseExam(int id, {String reason = ''}) => ApiClient.patch('/guru/exams/$id/pause', data: {'reason': reason});
  Future<void> resumeExam(int id) => ApiClient.patch('/guru/exams/$id/resume');
  Future<void> endExam(int id)    => ApiClient.patch('/guru/exams/$id/end');
  Future<void> deleteExam(int id) => ApiClient.delete('/guru/exams/$id');

  Future<List<ViolationModel>> getViolations({int page = 1}) async {
    final data = await ApiClient.get('/guru/violations', params: {'page': page});
    return ((data['data'] as List?) ?? []).map((e) => ViolationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Mata Pelajaran ─────────────────────────────────────
  Future<List<SubjectModel>> getSubjects() async {
    final data = await ApiClient.get('/guru/subjects');
    return ((data['data'] as List?) ?? []).map((e) => SubjectModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<dynamic> createSubject(String name) async {
    return await ApiClient.post('/guru/subjects', data: {'name': name});
  }

  Future<dynamic> updateSubject(int id, String name) async {
    return await ApiClient.put('/guru/subjects/$id', data: {'name': name});
  }

  Future<void> deleteSubject(int id) => ApiClient.delete('/guru/subjects/$id');

  // ── Soal by Subject ────────────────────────────────────
  Future<List<QuestionModel>> getQuestions({String? search, String? difficulty, String? subjectId, int page = 1}) async {
    final data = await ApiClient.get('/guru/questions', params: {
      'search': search, 'difficulty': difficulty, 'subject_id': subjectId, 'page': page, 'per_page': 100,
    });
    return ((data['data'] as List?) ?? []).map((e) => QuestionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Import Soal ─────────────────────────────────────────
  Future<QuestionImportPreview> previewImport(String filePath, String fileName) async {
    final data = await ApiClient.uploadFile('/guru/question-imports/preview', 'file', filePath, {});
    return QuestionImportPreview.fromJson(data['preview'] as Map<String, dynamic>);
  }

  Future<QuestionImportPreview> previewImportBytes(Uint8List bytes, String fileName) async {
    final data = await ApiClient.uploadFileBytes('/guru/question-imports/preview', 'file', bytes, fileName, {});
    return QuestionImportPreview.fromJson(data['preview'] as Map<String, dynamic>);
  }

  Future<QuestionImportModel> executeImport(String filePath, String fileName, {int? categoryId, int? subjectId}) async {
    final fields = <String, dynamic>{};
    if (categoryId != null) fields['category_id'] = categoryId;
    if (subjectId != null) fields['subject_id'] = subjectId;
    final data = await ApiClient.uploadFile('/guru/question-imports', 'file', filePath, fields);
    return QuestionImportModel.fromJson(data['import'] as Map<String, dynamic>);
  }

  Future<QuestionImportModel> executeImportBytes(Uint8List bytes, String fileName, {int? categoryId, int? subjectId}) async {
    final fields = <String, dynamic>{};
    if (categoryId != null) fields['category_id'] = categoryId;
    if (subjectId != null) fields['subject_id'] = subjectId;
    final data = await ApiClient.uploadFileBytes('/guru/question-imports', 'file', bytes, fileName, fields);
    return QuestionImportModel.fromJson(data['import'] as Map<String, dynamic>);
  }

  Future<void> downloadTemplate() async {
    final dio = await ApiClient.getInstance();
    final response = await dio.get('/guru/question-imports/template',
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data as Uint8List;
    final fileName = 'template-import-soal.csv';
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Simpan Template Import',
      fileName: fileName,
      type: FileType.any,
      bytes: bytes,
    );
    if (result == null) throw Exception('Batal menyimpan file');
  }

  Future<List<QuestionImportModel>> getImportHistory() async {
    final data = await ApiClient.get('/guru/question-imports');
    return ((data['data'] as List?) ?? []).map((e) => QuestionImportModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
