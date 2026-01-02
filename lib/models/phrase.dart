class Word {
  final int start;
  final int end;
  final double score;
  final String text;
  final int index;
  final bool searched;

  Word({
    required this.start,
    required this.end,
    required this.score,
    required this.text,
    required this.index,
    required this.searched,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      start: json['start'] as int,
      end: json['end'] as int,
      score: (json['score'] as num).toDouble(),
      text: json['text'] as String,
      index: json['index'] as int,
      searched: json['searched?'] as bool,
    );
  }
}

class VideoInfo {
  final String info;
  final bool wps;
  final String sourceUrl;
  final String imdb;

  VideoInfo({
    required this.info,
    required this.wps,
    required this.sourceUrl,
    required this.imdb,
  });

  factory VideoInfo.fromJson(Map<String, dynamic> json) {
    return VideoInfo(
      info: json['info'] as String,
      wps: json['wps'] as bool,
      sourceUrl: json['source-url'] as String,
      imdb: json['imdb'] as String,
    );
  }
}

class Phrase {
  final VideoInfo videoInfo;
  final int index;
  final List<Word> words;
  final int start;
  final String videoUrl;
  final String movie;
  final String id;
  final int nextPhraseStart;
  final int end;
  final String downloadFileName;
  final String text;

  Phrase({
    required this.videoInfo,
    required this.index,
    required this.words,
    required this.start,
    required this.videoUrl,
    required this.movie,
    required this.id,
    required this.nextPhraseStart,
    required this.end,
    required this.downloadFileName,
    required this.text,
  });

  factory Phrase.fromJson(Map<String, dynamic> json) {
    return Phrase(
      videoInfo: VideoInfo.fromJson(json['video-info'] as Map<String, dynamic>),
      index: json['index'] as int,
      words: (json['words'] as List<dynamic>)
          .map((w) => Word.fromJson(w as Map<String, dynamic>))
          .toList(),
      start: json['start'] as int,
      videoUrl: json['video-url'] as String,
      movie: json['movie'] as String,
      id: json['id'] as String,
      nextPhraseStart: json['next-phrase-start'] as int,
      end: json['end'] as int,
      downloadFileName: json['download-file-name'] as String,
      text: json['text'] as String,
    );
  }
}

class SearchResponse {
  final int count;
  final List<Phrase> phrases;

  SearchResponse({
    required this.count,
    required this.phrases,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      count: json['count'] as int,
      phrases: (json['phrases'] as List<dynamic>)
          .map((p) => Phrase.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Unified video item that can represent either a Phrase (with word timing) or just a video URL
class VideoItem {
  final String videoUrl;
  final Phrase? phrase;
  final String? info;

  VideoItem({
    required this.videoUrl,
    this.phrase,
    this.info,
  });

  factory VideoItem.fromPhrase(Phrase phrase) {
    return VideoItem(
      videoUrl: phrase.videoUrl,
      phrase: phrase,
      info: phrase.videoInfo.info,
    );
  }

  factory VideoItem.fromUrl(String url) {
    return VideoItem(
      videoUrl: url,
      phrase: null,
      info: null,
    );
  }

  bool get hasWordTiming => phrase != null;
}
