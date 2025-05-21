import 'package:flutter/material.dart';
import 'package:flutter_reaction_button/flutter_reaction_button.dart';

final List<Reaction<String>> flagsReactions = [
  Reaction<String>(
    value: 'en',
    previewIcon: _buildFlagPreviewIcon(
      Icons.language,
      'English',
    ),
    icon: _buildFlagIcon(Icons.language),
  ),
  Reaction<String>(
    value: 'ar',
    previewIcon: _buildFlagPreviewIcon(
      Icons.translate,
      'Arabic',
    ),
    icon: _buildFlagIcon(Icons.translate),
  ),
  Reaction<String>(
    value: 'gr',
    previewIcon: _buildFlagPreviewIcon(
      Icons.flag,
      'German',
    ),
    icon: _buildFlagIcon(Icons.flag),
  ),
  Reaction<String>(
    value: 'sp',
    previewIcon: _buildFlagPreviewIcon(
      Icons.g_translate,
      'Spanish',
    ),
    icon: _buildFlagIcon(Icons.g_translate),
  ),
  Reaction<String>(
    value: 'ch',
    previewIcon: _buildFlagPreviewIcon(
      Icons.public,
      'Chinese',
    ),
    icon: _buildFlagIcon(Icons.public),
  ),
];

const defaultInitialReaction = Reaction<String>(
  value: null,
  icon: Text('No reaction'),
);

final List<Reaction<String>> reactions = [
  Reaction<String>(
    value: 'Happy',
    title: _buildEmojiTitle('Happy'),
    previewIcon: _buildEmojiPreviewIcon(Icons.sentiment_satisfied_alt),
    icon: _buildReactionsIcon(
      Icons.sentiment_satisfied_alt,
      const Text('Happy', style: TextStyle(color: Color(0XFF3b5998))),
    ),
  ),
  Reaction<String>(
    value: 'Angry',
    title: _buildEmojiTitle('Angry'),
    previewIcon: _buildEmojiPreviewIcon(Icons.sentiment_very_dissatisfied),
    icon: _buildReactionsIcon(
      Icons.sentiment_very_dissatisfied,
      const Text('Angry', style: TextStyle(color: Color(0XFFed5168))),
    ),
  ),
  Reaction<String>(
    value: 'In love',
    title: _buildEmojiTitle('In love'),
    previewIcon: _buildEmojiPreviewIcon(Icons.favorite),
    icon: _buildReactionsIcon(
      Icons.favorite,
      const Text('In love', style: TextStyle(color: Color(0XFFffda6b))),
    ),
  ),
  Reaction<String>(
    value: 'Sad',
    title: _buildEmojiTitle('Sad'),
    previewIcon: _buildEmojiPreviewIcon(Icons.sentiment_dissatisfied),
    icon: _buildReactionsIcon(
      Icons.sentiment_dissatisfied,
      const Text('Sad', style: TextStyle(color: Color(0XFFffda6b))),
    ),
  ),
  Reaction<String>(
    value: 'Surprised',
    title: _buildEmojiTitle('Surprised'),
    previewIcon: _buildEmojiPreviewIcon(Icons.sentiment_neutral),
    icon: _buildReactionsIcon(
      Icons.sentiment_neutral,
      const Text('Surprised', style: TextStyle(color: Color(0XFFffda6b))),
    ),
  ),
  Reaction<String>(
    value: 'Mad',
    title: _buildEmojiTitle('Mad'),
    previewIcon: _buildEmojiPreviewIcon(Icons.mood_bad),
    icon: _buildReactionsIcon(
      Icons.mood_bad,
      const Text('Mad', style: TextStyle(color: Color(0XFFf05766))),
    ),
  ),
];

Widget _buildFlagPreviewIcon(IconData icon, String text) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w300,
          color: Colors.black,
        ),
      ),
      const SizedBox(height: 7.5),
      Icon(icon, size: 30, color: Colors.black),
    ],
  );
}

Widget _buildEmojiTitle(String title) {
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .75),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Text(
      title,
      style: const TextStyle(
        color: Colors.blue,
        fontSize: 8,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

Widget _buildEmojiPreviewIcon(IconData icon) {
  return Icon(icon, size: 30, color: Colors.red);
}

Widget _buildFlagIcon(IconData icon) {
  return Icon(icon, size: 20);
}

Widget _buildReactionsIcon(IconData icon, Text text) {
  return Container(
    color: Colors.transparent,
    child: Row(
      children: <Widget>[
        Icon(icon, size: 20),
        const SizedBox(width: 5),
        text,
      ],
    ),
  );
}
