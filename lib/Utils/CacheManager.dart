import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class MyCacheManager extends CacheManager {
  static const key = "myCustomCache";

  MyCacheManager()
    : super(
        Config(
          key,
          stalePeriod: const Duration(days: 1),
          maxNrOfCacheObjects: 100,
        ),
      );
}
