import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class ListViewScreen extends StatefulWidget {
  const ListViewScreen({super.key});

  @override
  State<ListViewScreen> createState() => _ListViewScreenState();
}

class _ListViewScreenState extends State<ListViewScreen> {
  String? _searchTerm;

  late final _pagingController = PagingController<int, String>(
    getNextPageKey: (state) {
      if (state.pages?.lastOrNull?.isEmpty ?? false) return null;
      return state.nextIntPageKey;
    },
    fetchPage: (pageKey) =>
        RemoteApi.getSimpleData(pageKey, search: _searchTerm),
  );

  @override
  void initState() {
    super.initState();
    _pagingController.addListener(_showError);
  }

  Future<void> _showError() async {
    if (_pagingController.value.status == PagingStatus.subsequentPageError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Something went wrong while fetching a new page.',
          ),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _pagingController.fetchNextPage(),
          ),
        ),
      );
    }
  }

  /// The controller needs to be disposed when the widget is removed.
  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text("Pagination Testing"),
        ),
        body: RefreshIndicator(
          onRefresh: () async => _pagingController.refresh(),

          /// The [PagingListener] is a widget that listens to the controller and
          /// rebuilds the UI based on the state of the controller.
          /// Its the easiest way to bind your controller to a Paged layout.
          child: PagingListener(
            controller: _pagingController,
            builder: (context, state, fetchNextPage) =>

                /// Paged layouts rely on a [PagingState] and a [fetchNextPage] function.
                PagedListView<int, String>.separated(
              reverse: true,
              state: state,
              fetchNextPage: fetchNextPage,
              itemExtent: 48,
              builderDelegate: PagedChildBuilderDelegate(
                animateTransitions: true,
                itemBuilder: (context, item, index) => Container(
                  margin: EdgeInsets.all(5),
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  child: Row(
                    children: [
                      Text(item),
                    ],
                  ),
                ),
                firstPageErrorIndicatorBuilder: (context) =>
                    CustomFirstPageError(pagingController: _pagingController),
                newPageErrorIndicatorBuilder: (context) =>
                    CustomNewPageError(pagingController: _pagingController),
              ),
              separatorBuilder: (context, index) => Container(),
            ),
          ),
        ),
      );
}

////

class CustomFirstPageError extends StatelessWidget {
  const CustomFirstPageError({
    super.key,
    required this.pagingController,
  });

  final PagingController<Object, Object> pagingController;

  @override
  Widget build(BuildContext context) {
    return PagingListener(
      controller: pagingController,
      builder: (context, state, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Something went wrong :(',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (state.error != null) ...[
              const SizedBox(
                height: 16,
              ),
              Text(
                state.error.toString(),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(
              height: 48,
            ),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: pagingController.refresh,
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomNewPageError extends StatelessWidget {
  const CustomNewPageError({
    super.key,
    required this.pagingController,
  });

  final PagingController<Object, Object> pagingController;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: pagingController.fetchNextPage,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'We didn\'t catch that. Try again?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            const Icon(
              Icons.refresh,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class RemoteApi {
  static Future<List<String>> getSimpleData(
    int page, {
    int limit = 20,
    String? search,
  }) {
    // 100 unique and realistic chat messages
    final message = [
      "Hey, how's it going?",
      "Just finished my work!",
      "Are you free this weekend?",
      "Let’s grab coffee tomorrow.",
      "That sounds perfect!",
      "I'm a bit tired today.",
      "Can't wait for the weekend.",
      "What time is the meeting?",
      "I'll send the report soon.",
      "Sorry I missed your call.",
      "Do you want to watch a movie?",
      "Let’s meet at 7 PM.",
      "That was really funny 😂",
      "No worries, take your time.",
      "Did you finish the assignment?",
      "I'm heading out now.",
      "Happy birthday! 🎉",
      "Thank you so much!",
      "It was nice talking to you.",
      "Where did you go today?",
      "I just got home.",
      "Send me the link, please.",
      "I’ll be there in 10 minutes.",
      "I'm stuck in traffic 😩",
      "Let me check and get back to you.",
      "Can we reschedule?",
      "I’m on a break now.",
      "This place is amazing!",
      "Did you see the news today?",
      "No, I haven't heard anything.",
      "Let’s play a game!",
      "I'm bored 😅",
      "That’s a great idea!",
      "I totally agree with you.",
      "What do you want for dinner?",
      "Pizza sounds good 😋",
      "I’m learning Flutter right now.",
      "Show me your code!",
      "Have you tried that new app?",
      "Looks interesting.",
      "Let’s go hiking next week!",
      "I need a vacation 🏖️",
      "Good night! Sleep well.",
      "Good morning! 🌞",
      "Wanna grab lunch?",
      "I’m not feeling well today.",
      "Take care of yourself.",
      "I'll call you later.",
      "What’s your favorite movie?",
      "Mine is Inception!",
      "Are you coming to the party?",
      "It’s going to be fun!",
      "Don't forget your umbrella ☔",
      "It’s raining heavily here.",
      "Stay safe!",
      "Guess what happened today?",
      "I'm so excited!",
      "I finally did it!",
      "Congratulations 🎉",
      "You deserve it.",
      "I'm proud of you.",
      "Let’s celebrate!",
      "I’m really sorry about that.",
      "Everything will be okay.",
      "Keep going, you got this!",
      "It’s a beautiful day.",
      "Wanna go for a walk?",
      "Send me a selfie 📸",
      "Haha that made me laugh!",
      "We should catch up soon.",
      "When are you free?",
      "Let’s do a video call.",
      "I'm working remotely today.",
      "Just finished the workout.",
      "Feeling super productive!",
      "I love this song 🎶",
      "Which book are you reading?",
      "That’s so inspiring.",
      "Mind blown 🤯",
      "Let’s order something to eat.",
      "I’m starving!",
      "Hope you're doing well.",
      "Can you help me with this?",
      "Sure, what do you need?",
      "I’ll explain it to you.",
      "Sounds confusing 😅",
      "Let’s try again.",
      "You're the best!",
      "I'm here if you need anything.",
      "Wanna play online tonight?",
      "Let’s start a new project!",
      "That’s a tough one.",
      "I’ve never done that before.",
      "Learning every day 💡",
      "Talk to you soon!",
      "Bye for now 👋",
      "That’s so kind of you.",
      "OMG 😱",
      "I miss those days.",
      "Hope to see you soon.",
      "I appreciate you!",
      "Let's keep in touch.",
      "Cheers! 🥂"
    ];

    final allMessages = message.reversed.toList();

    // Optional search filter
    final filteredMessages = (search != null && search.isNotEmpty)
        ? allMessages
            .where((msg) => msg.toLowerCase().contains(search.toLowerCase()))
            .toList()
        : allMessages;

    // Pagination logic
    final start = (page - 1) * limit;
    final end = start + limit;

    final paginated = (start < filteredMessages.length)
        ? filteredMessages.sublist(start, end.clamp(0, filteredMessages.length))
        : <String>[];

    return Future.delayed(
      const Duration(milliseconds: 500),
      () => paginated,
    );
  }
}
