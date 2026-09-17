import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../routing/app_router.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tic Tac Toe', style: theme.textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(
                'Play a round against the robot.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: () {
                  context.router.push(const GameRoute());
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text('Play'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
