import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:projects/widgets/weather_service.dart';

class LiveWeatherCard extends StatefulWidget {
  const LiveWeatherCard({super.key});

  @override
  State<LiveWeatherCard> createState() => _LiveWeatherCardState();
}

class _LiveWeatherCardState extends State<LiveWeatherCard> {
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? _latestWeather;
  late StreamSubscription _weatherSubscription;

  @override
  void initState() {
    super.initState();

    _weatherSubscription = _weatherService.weatherStream().listen((data) {
      if (mounted) {
        setState(() {
          _latestWeather = data;
        });
      }
    });
  }

  @override
  void dispose() {
    _weatherSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.2, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _latestWeather == null
          ? const SizedBox(
        key: ValueKey('shimmer'),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: _ShimmerLoadingCard(),
        ),
      )
          : Container(
        key: ValueKey(_latestWeather.toString()),
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.sunny, color: Colors.orange, size: 30),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _latestWeather!['location'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${_latestWeather!['temperature']}, ${_latestWeather!['emoji']}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

    );
  }
}

class _ShimmerLoadingCard extends StatelessWidget {
  const _ShimmerLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
