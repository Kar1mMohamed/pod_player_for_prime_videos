# Pod Player (For prime_videos_pkg)

```dart
import 'package:flutter/material.dart';
import 'package:pod_player_for_prime_videos/pod_player.dart';

class PrimeVideosPlayer extends StatefulWidget {
  const PrimeVideosPlayer({super.key});

  @override
  State<PrimeVideosPlayer> createState() => _PrimeVideosPlayerHomeState();
}

class _PrimeVideosPlayerHomeState extends State<PrimeVideosPlayer> {
  late final PodPlayerController controller;

  @override
  void initState() {
    controller = PodPlayerController(
      playVideoFrom: PlayVideoFrom.primeVideo(
        'https://primevideosapi.kar1mmohamed.com/videoD/1RQ12rg4w2DUsdwepeIQYerfNqsWOsZ49',
      ),
    )..initialise();

    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PodVideoPlayer(controller: controller),
          ],
        ),
      ),
    );
  }
}

