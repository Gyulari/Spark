import 'package:supabase_flutter/supabase_flutter.dart';
export 'package:supabase_flutter/supabase_flutter.dart';

// Supabase API Data
const SUPABASE_URL = 'https://nqwinljaateluurkozda.supabase.co';
const SUPABASE_API_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5xd2lubGphYXRlbHV1cmtvemRhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE4OTU4NTMsImV4cCI6MjA3NzQ3MTg1M30.v6P0Hxa0aMPKAWYVYL4Y1aEecFxyLgAFBgM1x_9cS-o';

class SupabaseManager {
  static final SupabaseClient client = Supabase.instance.client;

  static Future<void> init() async {
    await Supabase.initialize(
      url: SUPABASE_URL,
      anonKey: SUPABASE_API_KEY,
    );
  }
}