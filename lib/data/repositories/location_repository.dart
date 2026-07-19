import '../../models/store_location.dart';
import '../db/app_database.dart';

class LocationRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<StoreLocation>> getLocations() async {
    final cached = await _db.readLocations();
    if (cached.isNotEmpty) return cached;
    await _db.cacheLocations(LocationSeed.stores);
    return LocationSeed.stores;
  }

  Future<void> setSelectedCity(String cityName) => _db.setMeta('selected_city', cityName);

  Future<String?> getSelectedCity() => _db.getMeta('selected_city');
}
