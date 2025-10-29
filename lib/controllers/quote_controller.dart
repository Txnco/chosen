import 'dart:convert';
import 'package:chosen/utils/chosen_api.dart';
import 'package:chosen/models/motivational_quote.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class QuoteController {
  static const _storage = FlutterSecureStorage();
  static const _quoteKey = 'daily_quote';
  static const _quoteDateKey = 'daily_quote_date';
  
  /// Get the daily motivational quote
  /// Caches the quote locally and only fetches a new one once per day
  static Future<MotivationalQuote?> getDailyQuote() async {
    try {
      // Get today's date (YYYY-MM-DD format)
      final today = DateTime.now().toIso8601String().substring(0, 10);
      
      // Check if we have a cached quote for today
      final cachedDate = await _storage.read(key: _quoteDateKey);
      final cachedQuoteJson = await _storage.read(key: _quoteKey);
      
      if (cachedDate == today && cachedQuoteJson != null) {
        // We have a cached quote for today, return it
        final cachedData = jsonDecode(cachedQuoteJson);
        return MotivationalQuote.fromJson(cachedData);
      }
      
      // No cached quote for today, fetch a new one from API
      final response = await ChosenApi.get('/quotes/random', auth: true);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Cache the quote with today's date
        await _storage.write(key: _quoteKey, value: response.body);
        await _storage.write(key: _quoteDateKey, value: today);
        
        return MotivationalQuote.fromJson(data);
      } else {
        // If API fails, try to return cached quote even if it's old
        if (cachedQuoteJson != null) {
          final cachedData = jsonDecode(cachedQuoteJson);
          return MotivationalQuote.fromJson(cachedData);
        }
        return null;
      }
    } catch (e) {
      // On error, try to return cached quote
      try {
        final cachedQuoteJson = await _storage.read(key: _quoteKey);
        if (cachedQuoteJson != null) {
          final cachedData = jsonDecode(cachedQuoteJson);
          return MotivationalQuote.fromJson(cachedData);
        }
      } catch (cacheError) {
        // Ignore cache errors
      }
      return null;
    }
  }
  
  /// Clear cached quote (useful for testing or manual refresh)
  static Future<void> clearCachedQuote() async {
    await _storage.delete(key: _quoteKey);
    await _storage.delete(key: _quoteDateKey);
  }
  
  /// Force refresh the quote (bypasses cache)
  static Future<MotivationalQuote?> forceRefreshQuote() async {
    await clearCachedQuote();
    return getDailyQuote();
  }
}