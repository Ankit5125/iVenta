import 'package:flutter/material.dart';
import 'package:smart_event_explorer_frontend/apis/repository/events/EventRepository.dart';
import 'package:smart_event_explorer_frontend/controllers/NavController.dart';
import 'package:smart_event_explorer_frontend/models/EventModel.dart';
import 'package:smart_event_explorer_frontend/screens/createEventScreen/CreateEventScreen.dart';
import 'package:smart_event_explorer_frontend/screens/profileViewScreen/profileViewScreen.dart';
import 'package:smart_event_explorer_frontend/screens/searchEventScreen/SearchEventScreen.dart';
import 'package:smart_event_explorer_frontend/screens/splash/SplashScreen.dart';
import 'package:smart_event_explorer_frontend/theme/TextTheme.dart';
import 'package:smart_event_explorer_frontend/utils/AnimatedNavigator/AnimatedNavigator.dart';
import 'package:smart_event_explorer_frontend/utils/DateFormatter/DateFormatter.dart';
import 'package:smart_event_explorer_frontend/widgets/AllEventScreenWidget/AllEventsScreen.dart';
import 'package:smart_event_explorer_frontend/widgets/CustomNavBar/CustomNavBar.dart';
import 'package:smart_event_explorer_frontend/widgets/MyAppBar/MyAppBar.dart';

class Home extends StatefulWidget {
  Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  DateTime dateTime = DateTime.now();
  TextEditingController searchController = TextEditingController();
  late Future<List<Event>> _allEvents;
  late Future<List<Event>> _trendingEvents;
  late TabController tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  int selected = 1;

  @override
  void initState() {
    super.initState();
    _allEvents = EventRepository().getAllEvents();
    _trendingEvents = EventRepository().getTrendingEvents();
    tabController = TabController(length: 2, vsync: this);

    // Add fade animation for smooth transitions
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    tabController.dispose();
    searchController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF000D1A),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF000D1A),
              const Color(0xFF001529),
              const Color(0xFF000D1A),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyAppBar(size: size),
                      SizedBox(height: 10),
                      Expanded(
                        child: ValueListenableBuilder(
                          valueListenable: NavController.selectedIndex,
                          builder: (_, index, __) => AnimatedSwitcher(
                            duration: Duration(milliseconds: 300),
                            switchInCurve: Curves.easeInOut,
                            switchOutCurve: Curves.easeInOut,
                            child: IndexedStack(
                              key: ValueKey(index),
                              index: index,
                              children: [
                                homeLayout(size),
                                SearchEventScreen(),
                                CreateEventScreen(),
                                ViewProfileScreen(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CustomNavBar(size: size),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget allEventsTab(Size size) => RefreshIndicator(
    color: Colors.white,
    backgroundColor: const Color(0xFF1A2F3F),
    strokeWidth: 3,
    onRefresh: () async {
      setState(() {
        _allEvents = EventRepository().getAllEvents();
      });
      await Future.delayed(Duration(milliseconds: 500));
    },
    child: FutureBuilder<List<Event>>(
      future: _allEvents,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          if (snapshot.error.toString().contains("AUTH_EXPIRED")) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showErrorSnackBar(context, "Session Ended, Login Again!");
              AnimatedNavigator(SplashScreen(), context);
            });
            return SizedBox.shrink();
          }
          return _buildErrorState("Something went wrong", size);
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return _buildLoadingState(size);
        }

        if (!snapshot.hasData) {
          return _buildErrorState("Something Went Wrong!", size);
        }

        final events = snapshot.data!;

        if (events.isEmpty) {
          return _buildEmptyState("No Events Right Now!", size);
        }

        return AllEventScreen(events: events, size: size);
      },
    ),
  );

  Widget trendingEventsTab(Size size) => FutureBuilder<List<Event>>(
    future: _trendingEvents,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        if (snapshot.error == "AUTH_EXPIRED") {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showErrorSnackBar(context, "Session Ended, Login Again!");
            AnimatedNavigator(SplashScreen(), context);
          });
          return SizedBox.shrink();
        }
        return _buildErrorState("Something went wrong", size);
      }

      if (snapshot.connectionState != ConnectionState.done) {
        return _buildLoadingState(size);
      }

      if (!snapshot.hasData) {
        return _buildErrorState("Something Went Wrong!", size);
      }

      final events = snapshot.data!;

      if (events.isEmpty) {
        return _buildEmptyState("No Trending Events!", size);
      }

      return AllEventScreen(events: events, size: size);
    },
  );

  Widget homeLayout(Size size) => Column(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Enhanced Header Section with Glass Effect
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.05),
              Colors.white.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.blue.shade400,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  "${DateFormatter.getMonthName(dateTime)} ${DateFormatter.getTodayDate(dateTime)}, ${DateFormatter.getFormattedTime(dateTime)}",
                  style: MyTextTheme.NormalStyle(
                    color: Colors.grey.withOpacity(0.9),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Colors.white, Colors.blue.shade300],
              ).createShader(bounds),
              child: Text(
                "Explore Events",
                style: MyTextTheme.HeadingStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),

      SizedBox(height: 20),

      // Enhanced Tab Bar
      Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: TabBar(
          controller: tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey.shade600,
          indicator: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade400],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 15,
          ),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.grid_view_rounded, size: 18),
                  SizedBox(width: 6),
                  Text("All"),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up_rounded, size: 18),
                  SizedBox(width: 6),
                  Text("Trending"),
                ],
              ),
            ),
          ],
        ),
      ),

      SizedBox(height: 20),

      Expanded(
        child: TabBarView(
          controller: tabController,
          children: [allEventsTab(size), trendingEventsTab(size)],
        ),
      ),
    ],
  );

  // Enhanced Loading State
  Widget _buildLoadingState(Size size) {
    return Center(
      child: Container(
        height: size.height * 0.5,
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900.withOpacity(0.2),
              Colors.purple.shade900.withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "lib/assets/gif/loading.gif",
              height: size.height * 0.15,
            ),
            SizedBox(height: 20),
            Text(
              "Loading Events...",
              style: MyTextTheme.NormalStyle(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced Error State
  Widget _buildErrorState(String message, Size size) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(32),
        margin: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade900.withOpacity(0.2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.red.shade300,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              message,
              style: MyTextTheme.NormalStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced Empty State
  Widget _buildEmptyState(String message, Size size) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(32),
        margin: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900.withOpacity(0.2),
              Colors.purple.shade900.withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy_rounded,
              color: Colors.blue.shade300,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              message,
              style: MyTextTheme.NormalStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              "Pull down to refresh",
              style: MyTextTheme.NormalStyle(
                color: Colors.grey.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced SnackBar
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade600, Colors.red.shade800],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: MyTextTheme.NormalStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ),
    );
  }
}
