import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://fxvqjqwzhqiczdgtjxth.supabase.co';
  static const String anonKey = 'sb_publishable_zr1P4UAdMfBh7e7ZFjmAZA_mN2BvYbe';
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: true,
    );
  }
}
