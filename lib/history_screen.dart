// IM/2021/004
// Hirun Senarathna

import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  final List<String> history;
  final VoidCallback onClearHistory;// callback function to handle clearing the history.

  const HistoryScreen({
    Key? key,
    required this.history, // The list of history data.
    required this.onClearHistory,// The function to clear history.
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              onClearHistory();
              // Navigate back to the previous screen after clearing history.
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: history.isEmpty
          ? const Center(
        child: Text(
          'No history available',
          style: TextStyle(color: Colors.white),
        ),
      )
          : ListView.builder(

        itemCount: history.length,// Number of items in the history list.
        itemBuilder: (context, index) {
          // Builds each list item.
          return ListTile(
            title: Text(
              history[index],
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      ),
    );
  }
}
