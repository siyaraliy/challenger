class SupabaseConfig {
  // Supabase credentials - Production ready
  // Project: qzbmodnznfdtjyietjie
  
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qzbmodnznfdtjyietjie.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF6Ym1vZG56bmZkdGp5aWV0amllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU0ODIwNTEsImV4cCI6MjA4MTA1ODA1MX0.pX9yRNZxVmvskG9YjlBePKqkmOQMKLtLz1ThG5fZsDI',
  );

  // Validate configuration
  static bool get isConfigured {
    return supabaseUrl != 'YOUR_SUPABASE_URL_HERE' &&
        supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY_HERE' &&
        supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty;
  }
}
