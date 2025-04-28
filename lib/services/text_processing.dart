import 'dart:math';

class TfIdf {
  Map<String, double> _calculateTf(String text) {
    final words = text.split(' ');
    final wordCount = <String, double>{};
    final totalWords = words.length.toDouble();
    
    for (final word in words) {
      wordCount[word] = (wordCount[word] ?? 0) + 1;
    }
    
    return wordCount.map((word, count) => 
      MapEntry(word, count / totalWords));
  }

  double similarity(String text1, String text2) {
    final tf1 = _calculateTf(text1);
    final tf2 = _calculateTf(text2);
    
    // Calculate cosine similarity
    double dotProduct = 0.0;
    for (final word in tf1.keys) {
      if (tf2.containsKey(word)) {
        dotProduct += tf1[word]! * tf2[word]!;
      }
    }
    
    double norm1 = sqrt(tf1.values.map((v) => v * v).reduce((a, b) => a + b));
    double norm2 = sqrt(tf2.values.map((v) => v * v).reduce((a, b) => a + b));
    
    if (norm1 == 0 || norm2 == 0) return 0.0;
    return dotProduct / (norm1 * norm2);
  }
}

class Tokenizer {
  List<String> tokenize(String text) {
    // Convert to lowercase and split by non-word characters
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
  }
}