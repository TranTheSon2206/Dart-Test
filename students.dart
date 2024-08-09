import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

class Student {
  int id;
  String name;
  List<Subject> subjects;

  Student(this.id, this.name, this.subjects);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subjects': subjects.map((subject) => subject.toJson()).toList(),
    };
  }

  static Student fromJson(Map<String, dynamic> json) {
    return Student(
      json['id'] ?? 0,
      json['name'] ?? '',
      (json['subjects'] as List<dynamic>?)
          ?.map((subject) => Subject.fromJson(subject as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  @override
  String toString() {
    return 'ID: $id, Name: $name, Subjects: ${subjects.join(', ')}';
  }
}

class Subject {
  String name;
  List<int> scores;

  Subject(this.name, this.scores);

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'scores': scores,
    };
  }

  static Subject fromJson(Map<String, dynamic> json) {
    return Subject(
      json['name'] ?? '',
      (json['scores'] as List<dynamic>?)
          ?.map((score) => score as int)
          .toList() ?? [],
    );
  }

  @override
  String toString() {
    return '$name: ${scores.join(', ')}';
  }
}

void main() async {
  const String fileName = 'students.json';
  final String directoryPath = p.join(Directory.current.path, 'data');
  final Directory directory = Directory(directoryPath);

  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
  final String filePath = p.join(directoryPath, fileName);
  List<Student> studentList = await loadStudents(filePath);

  while (true) {
    print('--------Quản lý sinh viên---------');
    print('');
    print('1. Hiển thị toàn bộ sinh viên');
    print('2. Thêm sinh viên');
    print('3. Sửa thông tin sinh viên');
    print('4. Tìm kiếm sinh viên');
    print('5. Hiển thị sinh viên có điểm thi môn cao nhất');
    print('6. Thoát');
    print('');
    print('Hãy lựa chọn tùy chọn: ');
    String? choice = stdin.readLineSync();

    switch (choice) {
      case '1':
        displayStudent(studentList);
        break;
      case '2':
        await addStudent(filePath, studentList);
        break;
      case '3':
        await editStudent(filePath, studentList);
        break;
      case '4':
        searchStudent(studentList);
        break;
      case '5':
        displayTopStudentsBySubject(studentList);
        break;
      case '6':
        exit(0);
      default:
        print('Lựa chọn không hợp lệ, vui lòng chọn lại.');
    }
  }
}

Future<List<Student>> loadStudents(String filePath) async {
  File file = File(filePath);
  if (!await file.exists()) {
    await file.create();
    await file.writeAsString(jsonEncode({'students': []}));
  }

  String content = await file.readAsString();
  try {
    dynamic jsonData = jsonDecode(content);
    if (jsonData is! Map<String, dynamic>) {
      throw Exception('Invalid JSON data');
    }

    List<Student> students = [];
    if (jsonData['students'] != null) {
      for (var studentJson in jsonData['students']) {
        students.add(Student.fromJson(studentJson));
      }
    }

    return students;
  } catch (e) {
    print('Lỗi khi đọc file JSON: $e');
    return [];
  }
}

Future<void> saveStudents(String filePath, List<Student> studentList) async {
  try {
    String jsonContent = jsonEncode({'students': studentList.map((s) => s.toJson()).toList()});
    await File(filePath).writeAsString(jsonContent);
  } catch (e) {
    print('Lỗi khi viết file JSON: $e');
  }
}

Future<void> addStudent(String filePath, List<Student> studentList) async {
  print('Nhập tên sinh viên: ');
  String? name = stdin.readLineSync();
  if (name == null || name.isEmpty) {
    print('Tên không hợp lệ');
    return;
  }

  List<Subject> subjects = await inputSubjects();

  int id = studentList.isEmpty ? 1 : studentList.last.id + 1;
  Student student = Student(id, name, subjects);

  studentList.add(student);
  await saveStudents(filePath, studentList);
}

Future<void> editStudent(String filePath, List<Student> studentList) async {
  print('Nhập ID sinh viên cần sửa: ');
  String? idStr = stdin.readLineSync();
  if (idStr == null || int.tryParse(idStr) == null) {
    print('ID không hợp lệ');
    return;
  }

  int id = int.parse(idStr);
  Student studentToEdit = studentList.firstWhere(
        (student) => student.id == id,
    orElse: () {
      print('Sinh viên không tồn tại');
      throw Exception('Sinh viên không tồn tại');
    },
  );

  print('Nhập tên mới (để giữ nguyên, hãy nhấn Enter): ');
  String? newName = stdin.readLineSync();
  if (newName != null && newName.isNotEmpty) {
    studentToEdit.name = newName;
  }

  print('Nhập thông tin môn học mới (để giữ nguyên, hãy nhấn Enter): ');
  List<Subject> newSubjects = await inputSubjects();
  if (newSubjects.isNotEmpty) {
    studentToEdit.subjects = newSubjects;
  }

  await saveStudents(filePath, studentList);
}



Future<void> searchStudent(List<Student> studentList) async {
  print('Tìm kiếm theo tên hoặc ID (nhập tên hoặc ID): ');
  String? query = stdin.readLineSync();
  if (query == null || query.isEmpty) {
    print('Truy vấn không hợp lệ');
    return;
  }

  List<Student> results = [];
  int? id = int.tryParse(query);
  if (id != null) {
    results = studentList.where((student) => student.id == id).toList();
  } else {
    results = studentList.where((student) => student.name.toLowerCase().contains(query.toLowerCase())).toList();
  }

  if (results.isEmpty) {
    print('Không tìm thấy sinh viên nào');
  } else {
    results.forEach((student) => print(student));
  }
}

Future<void> displayTopStudentsBySubject(List<Student> studentList) async {
  print('Nhập tên môn học để tìm sinh viên có điểm cao nhất: ');
  String? subjectName = stdin.readLineSync();
  if (subjectName == null || subjectName.isEmpty) {
    print('Tên môn học không hợp lệ');
    return;
  }

  Student? topStudent;
  int? highestScore;

  for (var student in studentList) {
    for (var subject in student.subjects) {
      if (subject.name == subjectName) {
        int? maxScore = subject.scores.isNotEmpty ? subject.scores.reduce((a, b) => a > b ? a : b) : null;
        if (maxScore != null && (highestScore == null || maxScore > highestScore)) {
          highestScore = maxScore;
          topStudent = student;
        }
      }
    }
  }

  if (topStudent != null) {
    print('Sinh viên có điểm cao nhất trong môn "$subjectName": ${topStudent}');
  } else {
    print('Không tìm thấy môn học hoặc không có điểm nào');
  }
}

Future<List<Subject>> inputSubjects() async {
  List<Subject> subjects = [];
  while (true) {
    print('Nhập tên môn học (hoặc để trống để kết thúc): ');
    String? subjectName = stdin.readLineSync();
    if (subjectName == null || subjectName.isEmpty) {
      break;
    }

    List<int> scores = [];
    while (true) {
      print('Nhập điểm cho môn "$subjectName" (nhập điểm hoặc để trống để kết thúc): ');
      String? scoreStr = stdin.readLineSync();
      if (scoreStr == null || scoreStr.isEmpty) {
        break;
      }

      int? score = int.tryParse(scoreStr);
      if (score != null && score >= 0) {
        scores.add(score);
      } else {
        print('Điểm không hợp lệ');
      }
    }

    subjects.add(Subject(subjectName, scores));
  }
  return subjects;
}

void displayStudent(List<Student> studentList) {
  if (studentList.isEmpty) {
    print('Danh sách sinh viên trống');
  } else {
    studentList.forEach((student) => print(student));
  }
}
