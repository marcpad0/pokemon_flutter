import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PokemonProvider()),
        ChangeNotifierProvider(create: (_) => BattleProvider()),
      ],
      child: MaterialApp(
        title: 'Pokémon Battle',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.pink,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.pink,
            secondary: Colors.cyan,
          ),
          textTheme: GoogleFonts.comfortaaTextTheme(),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

// =============== MODELS ===============

class Pokemon {
  final int id;
  final String name;
  final String imageUrl;
  final List<Move> moves;
  final int hp;
  int currentHp;
  final Map<String, dynamic> stats;
  final List<String> types; // Added types property

  Pokemon({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.moves,
    required this.hp,
    required this.stats,
    required this.types, // Include types in constructor
  }) : currentHp = hp;

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    // Parse stats
    Map<String, dynamic> stats = {};
    for (var stat in json['stats']) {
      stats[stat['stat']['name']] = stat['base_stat'];
    }

    // Parse types
    List<String> types = [];
    for (var typeData in json['types']) {
      types.add(typeData['type']['name']);
    }

    // Get moves (limited to 4)
    List<Move> moves = [];
    for (var moveData in json['moves']) {
      if (moves.length >= 4) break;
      moves.add(Move(
        name: moveData['move']['name'],
        url: moveData['move']['url'],
      ));
    }

    return Pokemon(
      id: json['id'],
      name: json['name'],
      imageUrl: json['sprites']['other']['official-artwork']['front_default'] ??
          json['sprites']['front_default'],
      moves: moves,
      hp: stats['hp'] * 2, // Multiply HP for longer battles
      stats: stats,
      types: types, // Include parsed types
    );
  }

  String get formattedName => name.substring(0, 1).toUpperCase() + name.substring(1);

  String get formattedTypes => types.map((type) =>
  type.substring(0, 1).toUpperCase() + type.substring(1)).join(', ');
}

// Add a TypeEffectiveness class to manage type matchups
class TypeEffectiveness {
  // Map of attacking type to defending types with effectiveness multipliers
  static const Map<String, Map<String, double>> chart = {
    'normal': {
      'rock': 0.5,
      'ghost': 0,
      'steel': 0.5,
    },
    'fire': {
      'fire': 0.5,
      'water': 0.5,
      'grass': 2,
      'ice': 2,
      'bug': 2,
      'rock': 0.5,
      'dragon': 0.5,
      'steel': 2,
    },
    'water': {
      'fire': 2,
      'water': 0.5,
      'grass': 0.5,
      'ground': 2,
      'rock': 2,
      'dragon': 0.5,
    },
    'electric': {
      'water': 2,
      'electric': 0.5,
      'grass': 0.5,
      'ground': 0,
      'flying': 2,
      'dragon': 0.5,
    },
    'grass': {
      'fire': 0.5,
      'water': 2,
      'grass': 0.5,
      'poison': 0.5,
      'ground': 2,
      'flying': 0.5,
      'bug': 0.5,
      'rock': 2,
      'dragon': 0.5,
      'steel': 0.5,
    },
    'ice': {
      'fire': 0.5,
      'water': 0.5,
      'grass': 2,
      'ice': 0.5,
      'ground': 2,
      'flying': 2,
      'dragon': 2,
      'steel': 0.5,
    },
    'fighting': {
      'normal': 2,
      'ice': 2,
      'poison': 0.5,
      'flying': 0.5,
      'psychic': 0.5,
      'bug': 0.5,
      'rock': 2,
      'ghost': 0,
      'dark': 2,
      'steel': 2,
      'fairy': 0.5,
    },
    'poison': {
      'grass': 2,
      'poison': 0.5,
      'ground': 0.5,
      'rock': 0.5,
      'ghost': 0.5,
      'steel': 0,
      'fairy': 2,
    },
    'ground': {
      'fire': 2,
      'electric': 2,
      'grass': 0.5,
      'poison': 2,
      'flying': 0,
      'bug': 0.5,
      'rock': 2,
      'steel': 2,
    },
    'flying': {
      'electric': 0.5,
      'grass': 2,
      'fighting': 2,
      'bug': 2,
      'rock': 0.5,
      'steel': 0.5,
    },
    'psychic': {
      'fighting': 2,
      'poison': 2,
      'psychic': 0.5,
      'dark': 0,
      'steel': 0.5,
    },
    'bug': {
      'fire': 0.5,
      'grass': 2,
      'fighting': 0.5,
      'poison': 0.5,
      'flying': 0.5,
      'psychic': 2,
      'ghost': 0.5,
      'dark': 2,
      'steel': 0.5,
      'fairy': 0.5,
    },
    'rock': {
      'fire': 2,
      'ice': 2,
      'fighting': 0.5,
      'ground': 0.5,
      'flying': 2,
      'bug': 2,
      'steel': 0.5,
    },
    'ghost': {
      'normal': 0,
      'psychic': 2,
      'ghost': 2,
      'dark': 0.5,
    },
    'dragon': {
      'dragon': 2,
      'steel': 0.5,
      'fairy': 0,
    },
    'dark': {
      'fighting': 0.5,
      'psychic': 2,
      'ghost': 2,
      'dark': 0.5,
      'fairy': 0.5,
    },
    'steel': {
      'fire': 0.5,
      'water': 0.5,
      'electric': 0.5,
      'ice': 2,
      'rock': 2,
      'steel': 0.5,
      'fairy': 2,
    },
    'fairy': {
      'fire': 0.5,
      'fighting': 2,
      'poison': 0.5,
      'dragon': 2,
      'dark': 2,
      'steel': 0.5,
    },
  };

  // Calculate effectiveness multiplier of an attack type against a defending Pokémon
  static double getEffectiveness(String attackType, List<String> defenderTypes) {
    double multiplier = 1.0;

    for (String defenderType in defenderTypes) {
      // If this defender type is in the chart for this attack type
      if (chart.containsKey(attackType) && chart[attackType]!.containsKey(defenderType)) {
        multiplier *= chart[attackType]![defenderType]!;
      }
    }

    return multiplier;
  }

  // Get description of effectiveness based on multiplier
  static String getEffectivenessDescription(double multiplier) {
    if (multiplier > 1.9) { // Account for rounding errors with 2.0
      return "It's super effective!";
    } else if (multiplier < 0.1) { // Account for rounding errors with 0.0
      return "It has no effect...";
    } else if (multiplier < 0.9) { // Account for rounding errors with 0.5
      return "It's not very effective...";
    } else {
      return "";
    }
  }
}

class Move {
  final String name;
  final String url;
  int power = 0;
  String type = 'normal';
  bool isLoaded = false;

  Move({
    required this.name,
    required this.url,
  });

  String get formattedName => name
      .split('-')
      .map((word) => word.substring(0, 1).toUpperCase() + word.substring(1))
      .join(' ');
}

// =============== SERVICES ===============

class PokemonService {
  static const String baseUrl = 'https://pokeapi.co/api/v2';

  // Update the search to only match Pokémon that start with the query
  Future<List<Map<String, String>>> searchPokemon(String query) async {
    try {
      // First try to get the exact Pokémon by name
      final response = await http.get(Uri.parse('$baseUrl/pokemon/$query'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return [{
          'name': data['name'] as String,
          'url': '$baseUrl/pokemon/${data['id']}',
        }];
      }
    } catch (_) {
      // Ignore error if Pokémon not found by exact name
    }

    // If no exact match, get a list and filter for names that START WITH the query
    final response = await http.get(
      Uri.parse('$baseUrl/pokemon?limit=2000'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'] as List;

      // Filter for Pokémon names that START WITH the query
      return results
          .where((pokemon) => (pokemon['name'] as String).startsWith(query))
          .map<Map<String, String>>((pokemon) => {
        'name': pokemon['name'] as String,
        'url': pokemon['url'] as String,
      })
          .toList();
    } else {
      throw Exception('Failed to search Pokémon');
    }
  }

  // Get a list of Pokémon names and URLs (for display in selection screen)
  Future<List<Map<String, String>>> getPokemonList(int limit, int offset) async {
    final response = await http.get(
      Uri.parse('$baseUrl/pokemon?limit=$limit&offset=$offset'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['results'] as List).map<Map<String, String>>((pokemon) {
        return {
          'name': pokemon['name'] as String,
          'url': pokemon['url'] as String,
        };
      }).toList();
    } else {
      throw Exception('Failed to load Pokémon list');
    }
  }

  // Get detailed information about a specific Pokémon
  Future<Pokemon> getPokemon(String nameOrId) async {
    final response = await http.get(Uri.parse('$baseUrl/pokemon/$nameOrId'));

    if (response.statusCode == 200) {
      return Pokemon.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load Pokémon: $nameOrId');
    }
  }

  // Load move details
  Future<void> loadMoveDetails(Move move) async {
    if (move.isLoaded) return;

    final response = await http.get(Uri.parse(move.url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      move.power = data['power'] ?? 40; // Default power if not specified
      move.type = data['type']['name'] ?? 'normal';
      move.isLoaded = true;
    } else {
      throw Exception('Failed to load move details');
    }
  }
}

// =============== PROVIDERS ===============

class PokemonProvider with ChangeNotifier {
  final PokemonService _service = PokemonService();
  List<Map<String, String>> _pokemonList = [];
  List<Map<String, String>> _filteredPokemonList = [];
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isSearching = false;
  int _offset = 0;
  final int _limit = 20;

  // Add a search request token to track the latest search
  int _currentSearchToken = 0;

  List<Map<String, String>> get pokemonList => _searchQuery.isEmpty
      ? _pokemonList
      : _filteredPokemonList;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;

  // Cached Pokémon details
  final Map<String, Pokemon> _pokemonCache = {};

  Future<void> setSearchQuery(String query) async {
    _searchQuery = query.toLowerCase();

    if (_searchQuery.isEmpty) {
      _filteredPokemonList = [];
      notifyListeners();
      return;
    }

    // Generate a new token for this search request
    final int thisSearchToken = ++_currentSearchToken;

    // Set searching flag
    _isSearching = true;
    notifyListeners();

    try {
      // Search directly from API
      final results = await _service.searchPokemon(_searchQuery);

      // Check if this is still the latest search request
      if (thisSearchToken == _currentSearchToken) {
        _filteredPokemonList = results;
      } else {
        // This search was superseded by a newer one, discard the results
        return;
      }
    } catch (e) {
      // Only handle the error if this is still the latest search
      if (thisSearchToken == _currentSearchToken) {
        debugPrint('Error searching Pokémon: $e');
        // Fallback to local filtering if API search fails
        _filteredPokemonList = _pokemonList
            .where((pokemon) => pokemon['name']!.startsWith(_searchQuery))
            .toList();
      }
    } finally {
      // Only update UI state if this is still the latest search
      if (thisSearchToken == _currentSearchToken) {
        _isSearching = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchPokemonList({bool refresh = false}) async {
    if (refresh) {
      _offset = 0;
      _pokemonList = [];
    }

    _isLoading = true;
    notifyListeners();

    try {
      final newPokemon = await _service.getPokemonList(_limit, _offset);
      _pokemonList = [..._pokemonList, ...newPokemon];

      // Re-apply search if there's an active query
      if (_searchQuery.isNotEmpty) {
        _filteredPokemonList = _pokemonList
            .where((pokemon) => pokemon['name']!.contains(_searchQuery))
            .toList();
      }

      _offset += _limit;
    } catch (e) {
      debugPrint('Error fetching Pokémon: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Pokemon> getPokemonDetails(String nameOrId) async {
    Pokemon pokemon;

    if (_pokemonCache.containsKey(nameOrId)) {
      // Clone the cached Pokémon to create a new instance
      pokemon = _clonePokemon(_pokemonCache[nameOrId]!);
    } else {
      pokemon = await _service.getPokemon(nameOrId);

      // Load move details
      for (var move in pokemon.moves) {
        await _service.loadMoveDetails(move);
      }

      _pokemonCache[nameOrId] = pokemon;
      // Create a clone for returning to ensure we don't modify the cached version
      pokemon = _clonePokemon(pokemon);
    }

    return pokemon;
  }

  Pokemon _clonePokemon(Pokemon original) {
    // Create a new list of moves that copies from the original
    List<Move> clonedMoves = original.moves.map((move) =>
    Move(
      name: move.name,
      url: move.url,
    )
      ..power = move.power
      ..type = move.type
      ..isLoaded = move.isLoaded
    ).toList();

    // Create a new Pokémon with the same properties but as a separate object
    return Pokemon(
      id: original.id,
      name: original.name,
      imageUrl: original.imageUrl,
      moves: clonedMoves,
      hp: original.hp,
      stats: Map<String, dynamic>.from(original.stats),
      types: List<String>.from(original.types), // Copy types
    );
  }
}

class BattleProvider with ChangeNotifier {
  List<Pokemon> player1Pokemon = [];
  List<Pokemon> player2Pokemon = [];

  int currentPlayer1PokemonIndex = 0;
  int currentPlayer2PokemonIndex = 0;

  int currentTurn = 1; // 1 for Player 1, 2 for Player 2
  String battleLog = '';
  bool gameOver = false;
  int? winner;

  // Added flag to prevent multiple move executions
  bool isProcessingMove = false;

  // Getters
  Pokemon? get currentPlayer1Pokemon =>
      player1Pokemon.isNotEmpty
          ? player1Pokemon[currentPlayer1PokemonIndex]
          : null;

  Pokemon? get currentPlayer2Pokemon =>
      player2Pokemon.isNotEmpty
          ? player2Pokemon[currentPlayer2PokemonIndex]
          : null;

  // Setters
  void setPlayer1Pokemon(List<Pokemon> pokemon) {
    player1Pokemon = pokemon;
    notifyListeners();
  }

  void setPlayer2Pokemon(List<Pokemon> pokemon) {
    player2Pokemon = pokemon;
    notifyListeners();
  }

  void resetBattle() {
    // Reset HP for all Pokémon
    for (var pokemon in [...player1Pokemon, ...player2Pokemon]) {
      pokemon.currentHp = pokemon.hp;
    }

    currentPlayer1PokemonIndex = 0;
    currentPlayer2PokemonIndex = 0;
    currentTurn = 1;
    battleLog = '';
    gameOver = false;
    winner = null;
    isProcessingMove = false;

    notifyListeners();
  }

  Future<void> useMove(Move move) async {
    // Don't process if the game is over or a move is already being processed
    if (gameOver || isProcessingMove) return;

    // Set the processing flag to prevent multiple executions
    isProcessingMove = true;
    notifyListeners();

    final attacker = currentTurn == 1
        ? currentPlayer1Pokemon
        : currentPlayer2Pokemon;
    final defender = currentTurn == 1
        ? currentPlayer2Pokemon
        : currentPlayer1Pokemon;

    if (attacker == null || defender == null) {
      isProcessingMove = false;
      notifyListeners();
      return;
    }

    // Calculate damage with some randomness
    final attackStat = attacker.stats['attack'] ?? 50;
    final defenseStat = defender.stats['defense'] ?? 50;
    final random = Random();
    final randomFactor = 0.85 + random.nextDouble() * 0.15; // 0.85 to 1.0

    // Calculate type effectiveness
    final typeEffectiveness = TypeEffectiveness.getEffectiveness(
        move.type, defender.types);

    // Ensure move power is valid
    final movePower = move.power > 0 ? move.power : 40;

    // Calculate damage and ensure it's at least 1
    int damage = ((movePower * attackStat) / defenseStat * randomFactor *
        typeEffectiveness).round();

    // If effectiveness is 0, damage is 0
    if (typeEffectiveness == 0) {
      damage = 0;
    } else {
      damage = max(1, damage); // At least 1 damage for non-zero effectiveness
    }

    // Add a small delay to simulate move animation
    await Future.delayed(const Duration(milliseconds: 800));

    // Apply damage
    defender.currentHp -= damage;
    if (defender.currentHp < 0) defender.currentHp = 0;

    // Update battle log
    battleLog = '${attacker.formattedName} used ${move.formattedName}!\n';

    // Add effectiveness message if applicable
    String effectivenessMsg = TypeEffectiveness.getEffectivenessDescription(
        typeEffectiveness);
    if (effectivenessMsg.isNotEmpty) {
      battleLog += '$effectivenessMsg\n';
    }

    battleLog +=
    'It dealt $damage damage to ${defender.formattedName}!\n$battleLog';

    // Check if defender is fainted
    if (defender.currentHp <= 0) {
      battleLog = '${defender.formattedName} fainted!\n$battleLog';

      // Add a small delay for the fainted message
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if all Pokémon are fainted
      if (currentTurn == 1) {
        if (currentPlayer2PokemonIndex >= player2Pokemon.length - 1) {
          gameOver = true;
          winner = 1;
          battleLog = 'Player 1 wins the battle!\n$battleLog';
        } else {
          currentPlayer2PokemonIndex++;
          battleLog =
          'Player 2 sends out ${player2Pokemon[currentPlayer2PokemonIndex]
              .formattedName}!\n$battleLog';
        }
      } else {
        if (currentPlayer1PokemonIndex >= player1Pokemon.length - 1) {
          gameOver = true;
          winner = 2;
          battleLog = 'Player 2 wins the battle!\n$battleLog';
        } else {
          currentPlayer1PokemonIndex++;
          battleLog =
          'Player 1 sends out ${player1Pokemon[currentPlayer1PokemonIndex]
              .formattedName}!\n$battleLog';
        }
      }
    }

    // Switch turn if not game over
    if (!gameOver) {
      currentTurn = currentTurn == 1 ? 2 : 1;
    }

    // Reset the processing flag and notify listeners
    isProcessingMove = false;
    notifyListeners();
  }
}

// =============== SCREENS ===============

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.pink.shade100,
              Colors.cyan.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/Pokemon/Pokemon_Animation.json',
                  height: MediaQuery.of(context).size.height * 0.25,
                  width: MediaQuery.of(context).size.width * 0.9,
                ),
                const SizedBox(height: 20),
                Text(
                  'Pokémon Battle',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.pink.shade700,
                  ),
                ).animate()
                    .fadeIn(duration: 800.ms)
                    .scale(delay: 300.ms),
                const SizedBox(height: 10),
                Text(
                  'Two players, one device!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.pink.shade500,
                  ),
                ),
                const SizedBox(height: 60),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PokemonSelectionScreen(player: 1),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Start Battle', style: TextStyle(fontSize: 18)),
                ).animate()
                    .fadeIn(delay: 500.ms)
                    .slideY(begin: 0.2, end: 0)
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05)),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('How to Play'),
                          content: const SingleChildScrollView(
                            child: Text(
                              '1. Each player selects up to 3 Pokémon\n'
                                  '2. Players take turns using moves\n'
                                  '3. When a Pokémon faints, the next one is sent out\n'
                                  '4. The player who defeats all opponent\'s Pokémon wins!',
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: const Text('Close'),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Text(
                    'How to Play',
                    style: TextStyle(color: Colors.pink.shade700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PokemonSelectionScreen extends StatefulWidget {
  final int player;

  const PokemonSelectionScreen({super.key, required this.player});

  @override
  PokemonSelectionScreenState createState() => PokemonSelectionScreenState();
}

class PokemonSelectionScreenState extends State<PokemonSelectionScreen> {
  final List<Pokemon> selectedPokemon = [];
  final int maxSelection = 3;
  bool isLoading = false;
  final ScrollController _scrollController = ScrollController();
  final Set<String> loadingPokemon = {};
  bool _isLoadingMore = false;
  final TextEditingController _searchController = TextEditingController();

  // Add debounce timer for search
  Timer? _searchDebounceTimer;


  @override
  void initState() {
    super.initState();
    // Set up scroll controller
    _scrollController.addListener(_scrollListener);

    // Reset search when screen loads
    _searchController.clear();

    // Pre-fetch Pokémon list when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PokemonProvider>(context, listen: false);

      // Clear any existing search
      provider.setSearchQuery('');

      // Fetch the Pokemon list
      provider.fetchPokemonList(refresh: widget.player == 1);
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // Don't load more Pokémon when we're in search mode
    if (_isLoadingMore ||
        _searchController.text.isNotEmpty ||
        Provider.of<PokemonProvider>(context, listen: false).searchQuery.isNotEmpty) {
      return;
    }

    // Only load more when close to the bottom and not searching
    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 500) {
      _loadMorePokemon();
    }
  }

  Future<void> _loadMorePokemon() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    await Provider.of<PokemonProvider>(context, listen: false).fetchPokemonList();

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Player ${widget.player} - Select Pokémon (${selectedPokemon.length}/$maxSelection)',
          style: TextStyle(color: widget.player == 1 ? Colors.pink : Colors.cyan),
        ),
        backgroundColor: widget.player == 1 ? Colors.pink.shade100 : Colors.cyan.shade100,
        actions: [
          // Add a clear search button in the app bar
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () {
                _searchController.clear();
                Provider.of<PokemonProvider>(context, listen: false).setSearchQuery('');
              },
              tooltip: 'Clear search',
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search bar
              _buildSearchBar(),

              // Selected Pokémon preview
              if (selectedPokemon.isNotEmpty)
                _buildSelectedPokemonPreview(),

              // Pokémon grid
              Expanded(
                child: Consumer<PokemonProvider>(
                  builder: (context, provider, _) {
                    if (provider.pokemonList.isEmpty && provider.isLoading) {
                      return _buildInitialLoadingView();
                    }

                    if (provider.isSearching) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: widget.player == 1 ? Colors.pink : Colors.cyan,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Searching for "${provider.searchQuery}"...',
                              style: TextStyle(
                                color: widget.player == 1 ? Colors.pink.shade700 : Colors.cyan.shade700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return _buildPokemonGrid(provider);
                  },
                ),
              ),

              // Continue button
              SafeArea(
                child: _buildContinueButton(),
              ),
            ],
          ),

          // Global loading overlay
          if (isLoading)
            _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search Pokémon',
          prefixIcon: Provider.of<PokemonProvider>(context).isSearching
              ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: widget.player == 1 ? Colors.pink : Colors.cyan,
            ),
          )
              : Icon(
            Icons.search,
            color: widget.player == 1 ? Colors.pink : Colors.cyan,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              Provider.of<PokemonProvider>(context, listen: false).setSearchQuery('');
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: widget.player == 1 ? Colors.pink.shade200 : Colors.cyan.shade200,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: widget.player == 1 ? Colors.pink.shade200 : Colors.cyan.shade200,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: widget.player == 1 ? Colors.pink : Colors.cyan,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) {
          // Cancel previous timer if it exists
          _searchDebounceTimer?.cancel();

          // Set a new timer to delay the search
          _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
            Provider.of<PokemonProvider>(context, listen: false).setSearchQuery(value);
          });
        },
      ),
    );
  }

  Widget _buildSelectedPokemonPreview() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: selectedPokemon.isEmpty ? 0 : 100,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: widget.player == 1
            ? Colors.pink.shade50
            : Colors.cyan.shade50,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: selectedPokemon.length,
        itemBuilder: (context, index) {
          final pokemon = selectedPokemon[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: widget.player == 1 ? Colors.pink.shade200 : Colors.cyan.shade200
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CachedNetworkImage(
                        imageUrl: pokemon.imageUrl,
                        height: 45,
                        width: 50,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => SizedBox(
                          height: 50,
                          width: 50,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: widget.player == 1 ? Colors.pink : Colors.cyan,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pokemon.formattedName,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        selectedPokemon.removeAt(index);
                      });
                    },
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.red.shade300,
                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInitialLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: widget.player == 1 ? Colors.pink : Colors.cyan,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading Pokémon...',
            style: TextStyle(
              color: widget.player == 1 ? Colors.pink.shade700 : Colors.cyan.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPokemonGrid(PokemonProvider provider) {
    if (provider.pokemonList.isEmpty && provider.searchQuery.isNotEmpty) {
      return Center(
        child: Text(
          'No Pokémon found starting with "${provider.searchQuery}"',
          style: TextStyle(
            color: widget.player == 1 ? Colors.pink.shade700 : Colors.cyan.shade700,
          ),
        ),
      );
    }

    // Show a footer message for search results
    final bool isSearchActive = provider.searchQuery.isNotEmpty;
    final int itemCount = provider.pokemonList.length +
        (_isLoadingMore && !isSearchActive ? 3 : 0) +
        (isSearchActive ? 1 : 0); // Add 1 for the footer when search is active

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Show loading placeholders when loading more items
        if (!isSearchActive && index >= provider.pokemonList.length) {
          return _buildLoadingCard();
        }

        // Show a footer for search results
        if (isSearchActive && index == provider.pokemonList.length) {
          return GridTile(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Showing ${provider.pokemonList.length} results for "${provider.searchQuery}"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: widget.player == 1 ? Colors.pink : Colors.cyan,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          );
        }

        final pokemonData = provider.pokemonList[index];
        final pokemonId = pokemonData['url']!.split('/')[6];
        final imageUrl =
            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$pokemonId.png';

        // Check if this Pokemon is currently loading
        final isLoading = loadingPokemon.contains(pokemonData['name']);
        final isDisabled = selectedPokemon.length >= maxSelection || isLoading;

        return PokemonCard(
          name: pokemonData['name']!,
          imageUrl: imageUrl,
          onTap: () => _selectPokemon(pokemonData['name']!),
          isDisabled: isDisabled,
          isLoading: isLoading,
          player: widget.player,
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return PokemonCard(
      name: "loading",
      imageUrl: "",
      onTap: () {},
      isDisabled: true,
      isLoading: true,
      player: widget.player,
    );
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedPokemon.isNotEmpty
              ? (widget.player == 1 ? Colors.pink : Colors.cyan)
              : Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: selectedPokemon.isEmpty || isLoading
            ? null
            : () => _continueToNextStep(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Continue (${selectedPokemon.length}/$maxSelection)',
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: widget.player == 1 ? Colors.pink : Colors.cyan,
              ),
              const SizedBox(height: 16),
              const Text('Loading Pokémon...'),
            ],
          ),
        ),
      ),
    );
  }

  // The remaining methods stay the same
  Future<void> _selectPokemon(String name) async {
    // Don't allow selection if we've reached the max, or if this pokemon is already being loaded
    if (selectedPokemon.length >= maxSelection || loadingPokemon.contains(name)) return;

    // Add to loading set to prevent double-selection
    setState(() {
      loadingPokemon.add(name);
      isLoading = true;
    });

    try {
      final pokemon = await Provider.of<PokemonProvider>(context, listen: false)
          .getPokemonDetails(name);

      // Check again that we haven't exceeded max selection (in case of multiple parallel requests)
      if (selectedPokemon.length < maxSelection) {
        setState(() {
          selectedPokemon.add(pokemon);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load Pokémon: $e')),
      );
    } finally {
      setState(() {
        loadingPokemon.remove(name);
        isLoading = loadingPokemon.isNotEmpty;
      });
    }
  }

  void _continueToNextStep() {
    // Disable button during loading
    if (isLoading) return;

    if (widget.player == 1) {
      // Player 1 is done selecting, move to Player 2 selection
      Provider.of<BattleProvider>(context, listen: false)
          .setPlayer1Pokemon(List.from(selectedPokemon));

      // Reset search query when moving to Player 2
      final pokemonProvider = Provider.of<PokemonProvider>(context, listen: false);
      pokemonProvider.setSearchQuery('');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            // Clear the search controller in the new screen
            return const PokemonSelectionScreen(player: 2);
          },
        ),
      );
    } else {
      // Player 2 is done selecting, start battle
      Provider.of<BattleProvider>(context, listen: false)
          .setPlayer2Pokemon(List.from(selectedPokemon));

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const BattleScreen()),
            (route) => route.isFirst,
      );
    }
  }
}

class PokemonCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final VoidCallback onTap;
  final bool isDisabled;
  final bool isLoading;
  final int player;

  const PokemonCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.onTap,
    required this.isDisabled,
    this.isLoading = false,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    final String formattedName =
        name.substring(0, 1).toUpperCase() + name.substring(1);

    return InkWell(
      onTap: isDisabled ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: (player == 1 ? Colors.pink : Colors.cyan).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: (player == 1 ? Colors.pink : Colors.cyan).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              if (isDisabled)
                Container(
                  color: Colors.grey.withOpacity(0.3),
                  width: double.infinity,
                  height: double.infinity,
                ),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center, // Added for better centering
                children: [
                  Center( // Added explicit Center widget
                    child: Container(
                      height: 80,
                      width: 80,
                      alignment: Alignment.center, // Ensure alignment
                      child: isLoading
                          ? _buildShimmerPlaceholder()
                          : CachedNetworkImage(
                        imageUrl: imageUrl,
                        placeholder: (context, url) => _buildShimmerPlaceholder(),
                        errorWidget: (context, url, error) =>
                        const Icon(Icons.catching_pokemon, size: 40, color: Colors.red),
                        fit: BoxFit.contain, // Use contain to maintain aspect ratio
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      formattedName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: player == 1 ? Colors.pink.shade700 : Colors.cyan.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              if (isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withOpacity(0.7),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: player == 1 ? Colors.pink : Colors.cyan,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key});

  @override
  BattleScreenState createState() => BattleScreenState();
}

class BattleScreenState extends State<BattleScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));

    // Reset battle when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BattleProvider>(context, listen: false).resetBattle();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<BattleProvider>(
        builder: (context, battleProvider, _) {
          final player1Pokemon = battleProvider.currentPlayer1Pokemon;
          final player2Pokemon = battleProvider.currentPlayer2Pokemon;

          if (player1Pokemon == null || player2Pokemon == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Start confetti if there's a winner
          if (battleProvider.gameOver && battleProvider.winner != null) {
            _confettiController.play();
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.pink.shade50,
                  Colors.cyan.shade50,
                ],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      // Player 2's Pokemon
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: PokemonBattleView(
                          pokemon: player2Pokemon,
                          isOpponent: true,
                          isActive: battleProvider.currentTurn == 2 && !battleProvider.gameOver,
                        ),
                      ),

                      // Battle info
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Turn indicator
                              if (!battleProvider.gameOver)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: battleProvider.currentTurn == 1
                                        ? Colors.pink.shade100
                                        : Colors.cyan.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.3),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'Player ${battleProvider.currentTurn}\'s Turn',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: battleProvider.currentTurn == 1
                                          ? Colors.pink.shade700
                                          : Colors.cyan.shade700,
                                    ),
                                  ),
                                ).animate()
                                    .fadeIn()
                                    .then()
                                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                                    .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05)),

                              // Battle log
                              Container(
                                height: 100,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: SingleChildScrollView(
                                  child: Text(
                                    battleProvider.battleLog.isEmpty
                                        ? 'The battle begins!'
                                        : battleProvider.battleLog,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Player 1's Pokemon
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: PokemonBattleView(
                          pokemon: player1Pokemon,
                          isOpponent: false,
                          isActive: battleProvider.currentTurn == 1 && !battleProvider.gameOver,
                        ),
                      ),

                      // Moves for active player
                      if (!battleProvider.gameOver)
                        Container(
                          height: 100,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          color: battleProvider.currentTurn == 1
                              ? Colors.pink.shade50
                              : Colors.cyan.shade50,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: (battleProvider.currentTurn == 1
                                ? player1Pokemon.moves
                                : player2Pokemon.moves)
                                .map((move) => MoveButton(
                              move: move,
                              onPressed: battleProvider.isProcessingMove
                                  ? null  // Disable button while processing a move
                                  : () => battleProvider.useMove(move),
                              playerTurn: battleProvider.currentTurn,
                              isProcessing: battleProvider.isProcessingMove,
                            ))
                                .toList(),
                          ),
                        ),

                      // Game over actions
                      if (battleProvider.gameOver)
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                'Player ${battleProvider.winner} Wins!',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: battleProvider.winner == 1
                                      ? Colors.pink.shade700
                                      : Colors.cyan.shade700,
                                ),
                              ).animate().scale(),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => battleProvider.resetBattle(),
                                    icon: const Icon(Icons.replay),
                                    label: const Text('Rematch'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                                            (route) => false,
                                      );
                                    },
                                    icon: const Icon(Icons.home),
                                    label: const Text('Home'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  // Confetti
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirection: pi / 2, // downward
                      emissionFrequency: 0.05,
                      numberOfParticles: 20,
                      maxBlastForce: 20,
                      minBlastForce: 10,
                      gravity: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class PokemonBattleView extends StatelessWidget {
  final Pokemon pokemon;
  final bool isOpponent;
  final bool isActive;

  const PokemonBattleView({
    super.key,
    required this.pokemon,
    required this.isOpponent,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isOpponent
            ? Colors.cyan.withOpacity(0.1)
            : Colors.pink.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: isActive
            ? Border.all(
          color: isOpponent ? Colors.cyan : Colors.pink,
          width: 2,
        )
            : null,
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          // Pokemon image
          Hero(
            tag: 'pokemon_${pokemon.id}_${isOpponent ? 2 : 1}',
            child: CachedNetworkImage(
              imageUrl: pokemon.imageUrl,
              height: 100,
              placeholder: (_, __) => const CircularProgressIndicator(),
              errorWidget: (_, __, ___) => const Icon(Icons.error),
            ),
          ).animate(
            target: isActive ? 1 : 0,
          ).shimmer(duration: 1000.ms, delay: 500.ms),

          const SizedBox(width: 12),

          // Pokemon info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      pokemon.formattedName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isOpponent ? Colors.cyan.shade700 : Colors.pink.shade700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'HP: ${pokemon.currentHp}/${pokemon.hp}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: pokemon.currentHp < pokemon.hp * 0.3
                            ? Colors.red
                            : pokemon.currentHp < pokemon.hp * 0.6
                            ? Colors.orange
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Type: ${pokemon.formattedTypes}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: pokemon.currentHp / pokemon.hp,
                    backgroundColor: Colors.grey.shade300,
                    color: pokemon.currentHp < pokemon.hp * 0.3
                        ? Colors.red
                        : pokemon.currentHp < pokemon.hp * 0.6
                        ? Colors.orange
                        : Colors.green,
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MoveButton extends StatelessWidget {
  final Move move;
  final VoidCallback? onPressed;
  final int playerTurn;
  final bool isProcessing;

  const MoveButton({
    super.key,
    required this.move,
    required this.onPressed,
    required this.playerTurn,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate available width based on screen size
    final screenWidth = MediaQuery.of(context).size.width;
    // Calculate button width - 4 buttons + padding
    final buttonWidth = (screenWidth - 48) / 4;

    return Container(
      width: buttonWidth,
      height: 80, // Fixed height for all buttons
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Stack(
        children: [
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: playerTurn == 1 ? Colors.pink : Colors.cyan,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              minimumSize: Size(buttonWidth, 80), // Enforce minimum size
              maximumSize: Size(buttonWidth, 80), // Enforce maximum size
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      move.formattedName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Power: ${move.power}',
                  style: const TextStyle(fontSize: 11),
                ),
                Text(
                  'Type: ${move.type}',
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
          if (isProcessing)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
