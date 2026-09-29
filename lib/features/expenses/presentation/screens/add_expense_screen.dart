import 'package:flutter/material.dart';

/// The "add an expense" screen.
///
/// Step 1 placeholder — in step 5 this becomes a Form with title, amount,
/// category dropdown, date picker and an optional note.
class AddExpenseScreen extends StatelessWidget {
  const AddExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // go_router gives this screen a back button automatically, because it
      // was pushed onto the stack by the list screen.
      appBar: AppBar(title: const Text('Add expense')),
      body: const Center(child: Text('The expense form goes here (step 5).')),
    );
  }
}
