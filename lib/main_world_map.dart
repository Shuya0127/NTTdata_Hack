import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'world_map_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  runApp(const WorldMapApp());
}

class WorldMapApp extends StatelessWidget {
  const WorldMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ワールドマップ',
      theme: ThemeData(useMaterial3: true),
      home: const WorldMapPage(),
    );
  }
}
