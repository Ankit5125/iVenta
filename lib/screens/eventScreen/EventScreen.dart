import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:smart_event_explorer_frontend/apis/repository/events/EventRepository.dart';
import 'package:smart_event_explorer_frontend/models/EventModel.dart';
import 'package:smart_event_explorer_frontend/widgets/mapsWidget/MapsWidget.dart';
import 'package:smart_event_explorer_frontend/screens/splash/SplashScreen.dart';
import 'package:smart_event_explorer_frontend/theme/TextTheme.dart';
import 'package:smart_event_explorer_frontend/utils/AnimatedNavigator/AnimatedNavigator.dart';
import 'package:smart_event_explorer_frontend/utils/DateFormatter/DateFormatter.dart';

class EventScreen extends StatefulWidget {
  final Size size;
  final String eventID;
  const EventScreen({required this.eventID, required this.size, super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF000D1A),
      body: SafeArea(
        child: FutureBuilder<Event>(
          future: EventRepository().getMoreEventInfo(widget.eventID),
          builder: (_, snapshot) {
            if (snapshot.hasError) {
              if (snapshot.error.toString().contains("AUTH_EXPIRED")) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showErrorSnackBar(context, "Session Ended, Login Again!");
                  AnimatedNavigator(SplashScreen(), context);
                });
                return SizedBox.shrink();
              }
              return _buildErrorState();
            }

            if (snapshot.connectionState != ConnectionState.done) {
              return _buildLoadingState();
            }

            if (!snapshot.hasData) {
              return _buildErrorState();
            }

            Event eventData = snapshot.data!;

            return Stack(
              children: [
                // Main content
                _buildMainContent(eventData),

                // Floating action buttons
                _buildFloatingActions(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainContent(Event eventData) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF000D1A), Color(0xFF001529), Color(0xFF000D1A)],
        ),
      ),
      child: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          // Hero image header
          SliverToBoxAdapter(child: _buildHeroImage(eventData)),

          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildEventDetails(eventData),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage(Event eventData) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Stack(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            child: CachedNetworkImage(
              imageUrl: eventData.posterImage ?? "",
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              filterQuality: FilterQuality.high,
              placeholder: (context, url) => Container(
                color: Colors.grey.shade900,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.blue.shade400),
                ),
              ),
            ),
          ),

          // Gradient overlays
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Quick info overlay
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eventData.isFree)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade600],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.4),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'FREE EVENT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetails(Event eventData) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [Colors.white, Colors.blue.shade200],
            ).createShader(bounds),
            child: Text(
              eventData.name,
              style: MyTextTheme.HeadingStyle(
                color: Colors.white,
              ).copyWith(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),

          SizedBox(height: 16),

          // Description with glassmorphic container
          _buildGlassContainer(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.description_rounded,
                  color: Colors.blue.shade300,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    eventData.description,
                    style: MyTextTheme.NormalStyle(color: Colors.grey.shade300),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Time Section
          _buildInfoCard(
            icon: Icons.access_time_rounded,
            iconColor: Colors.purple.shade300,
            title: 'Event Schedule',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  Icons.play_circle_outline_rounded,
                  'Starts',
                  DateFormatter.getFormattedDateTime(eventData.startTime),
                ),
                SizedBox(height: 8),
                _buildInfoRow(
                  Icons.stop_circle_outlined,
                  'Ends',
                  DateFormatter.getFormattedDateTime(eventData.endTime),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Registration Details
          _buildInfoCard(
            icon: Icons.app_registration_rounded,
            iconColor: Colors.orange.shade300,
            title: 'Registration',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  eventData.isFree
                      ? Icons.check_circle_rounded
                      : Icons.payments_rounded,
                  'Entry Fee',
                  eventData.isFree ? 'Free' : 'Paid',
                ),
                SizedBox(height: 8),
                _buildInfoRow(
                  Icons.event_available_rounded,
                  'Deadline',
                  DateFormatter.getFormattedDateTime(
                    eventData.registrationDeadline ?? eventData.startTime,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Capacity
          _buildInfoCard(
            icon: Icons.people_rounded,
            iconColor: Colors.green.shade300,
            title: 'Capacity',
            child: Row(
              children: [
                Icon(
                  Icons.groups_rounded,
                  color: Colors.green.shade300,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  '${eventData.capacity} attendees',
                  style: MyTextTheme.NormalStyle(color: Colors.grey.shade300),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Organizer
          _buildInfoCard(
            icon: Icons.business_rounded,
            iconColor: Colors.blue.shade300,
            title: 'Organizer',
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.blue.shade300, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(23),
                    child:
                        eventData.organizer['avatar'] == null ||
                            eventData.organizer['avatar'].toString().isEmpty
                        ? Container(
                            color: Colors.blue.shade900,
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 30,
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: eventData.organizer['avatar'],
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eventData.organizer['name'] ?? 'Unknown',
                        style: MyTextTheme.NormalStyle(
                          color: Colors.white,
                        ).copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        eventData.organizer['organizationName'] ?? '-',
                        style: MyTextTheme.NormalStyle(
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Location with Map
          _buildInfoCard(
            icon: Icons.location_on_rounded,
            iconColor: Colors.red.shade300,
            title: 'Location',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eventData.location['address'] ?? 'Address not available',
                  style: MyTextTheme.NormalStyle(color: Colors.grey.shade300),
                ),
                SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: widget.size.height * 0.25,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Builder(
                      builder: (ctx) {
                        final coords =
                            (eventData.location['coordinates'] is List)
                            ? List.from(eventData.location['coordinates'])
                            : <dynamic>[];
                        double lat = 0.0, lng = 0.0;
                        if (coords.length >= 2) {
                          lat = double.tryParse("${coords[0]}") ?? 0.0;
                          lng = double.tryParse("${coords[1]}") ?? 0.0;
                        }
                        return MapsScreen(lattitude: lat, longitude: lng);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Categories
          _buildInfoCard(
            icon: Icons.category_rounded,
            iconColor: Colors.amber.shade300,
            title: 'Categories',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: eventData.category
                  .map(
                    (cat) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade700,
                            Colors.purple.shade700,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child}) {
    return Container(
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
      child: child,
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade400, size: 18),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: MyTextTheme.NormalStyle(color: Colors.grey.shade400),
        ),
        Expanded(
          child: Text(
            value,
            style: MyTextTheme.NormalStyle(
              color: Colors.grey.shade300,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActions(BuildContext context) {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          _buildActionButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),

          // Action buttons
          Row(
            children: [
              _buildActionButton(
                icon: _isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                onTap: () {
                  setState(() {
                    _isBookmarked = !_isBookmarked;
                  });
                  _showSnackBar(
                    context,
                    _isBookmarked
                        ? 'Added to bookmarks'
                        : 'Removed from bookmarks',
                  );
                },
              ),
              SizedBox(width: 12),
              _buildActionButton(
                icon: Icons.share_rounded,
                onTap: () {
                  _showSnackBar(context, 'Share feature coming soon!');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade900.withOpacity(0.2),
              Colors.purple.shade900.withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              "lib/assets/gif/loading.gif",
              height: widget.size.height * 0.15,
            ),
            SizedBox(height: 20),
            Text(
              "Loading event details...",
              style: MyTextTheme.NormalStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(32),
        margin: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.shade900.withOpacity(0.2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
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
              "Something went wrong!",
              style: MyTextTheme.NormalStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade800],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(message, style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ),
    );
  }

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
          ),
          child: Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(message, style: TextStyle(color: Colors.white)),
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
