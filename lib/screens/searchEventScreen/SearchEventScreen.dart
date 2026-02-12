import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:smart_event_explorer_frontend/apis/repository/events/EventRepository.dart';
import 'package:smart_event_explorer_frontend/models/EventModel.dart';
import 'package:smart_event_explorer_frontend/screens/eventScreen/EventScreen.dart';
import 'package:smart_event_explorer_frontend/theme/TextTheme.dart';
import 'package:smart_event_explorer_frontend/utils/DateFormatter/DateFormatter.dart';

class SearchEventScreen extends StatefulWidget {
  const SearchEventScreen({super.key});

  @override
  State<SearchEventScreen> createState() => _SearchEventScreenState();
}

class _SearchEventScreenState extends State<SearchEventScreen> {
  late TextEditingController controller;
  List<Event> searchedEvents = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    controller.addListener(() {
      setState(() {}); // Rebuild when text changes
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.04;
    final verticalPadding = screenWidth * 0.04;
    final iconSize = size.width * 0.045;

    return Column(
      children: [
        const SizedBox(height: 20),
        // Enhanced Search Bar with gradient border
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [
                Colors.purple.withOpacity(0.3),
                Colors.blue.withOpacity(0.3),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextSelectionTheme(
              data: const TextSelectionThemeData(
                cursorColor: Colors.white,
                selectionColor: Colors.grey,
                selectionHandleColor: Colors.grey,
              ),
              child: TextField(
                controller: controller,
                maxLines: 1,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            controller.clear();
                            setState(() {
                              searchedEvents = [];
                            });
                          },
                          icon: const Icon(Icons.clear, color: Colors.white70),
                        )
                      : null,
                  hintText: "Search events by name or description...",
                  hintStyle: MyTextTheme.NormalStyle(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  filled: false,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                ),
                style: MyTextTheme.NormalStyle(color: Colors.white),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    fetchEvent();
                  }
                },
              ),
            ),
          ),
        ),

        // Results count badge
        if (searchedEvents.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.withOpacity(0.3),
                      Colors.blue.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.event_available,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${searchedEvents.length} ${searchedEvents.length == 1 ? 'Event' : 'Events'} Found',
                      style: MyTextTheme.smallStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 20),

        // Content area
        if (isLoading)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("lib/assets/gif/loading.gif", fit: BoxFit.cover),
                  const SizedBox(height: 16),
                  Text(
                    "Searching events...",
                    style: MyTextTheme.NormalStyle(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (errorMessage != null)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: Colors.red.withOpacity(0.7),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage!,
                    style: MyTextTheme.NormalStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: fetchEvent,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Try Again"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.withOpacity(0.3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (searchedEvents.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 80,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Discover Amazing Events",
                    style: MyTextTheme.BigStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Search by name or description to get started",
                    style: MyTextTheme.NormalStyle(
                      color: Colors.white.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: searchedEvents.length,
              itemBuilder: (_, index) {
                return _buildEventCard(
                  context,
                  searchedEvents[index],
                  size,
                  iconSize,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    Event event,
    Size size,
    double iconSize,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventScreen(eventID: event.id, size: size),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Event Image with hero animation ready
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    width: size.width * 0.32,
                    height: size.height * 0.18,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: event.posterImage.toString(),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.event,
                        color: Colors.white.withOpacity(0.5),
                        size: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Event Details
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event Name
                      Text(
                        event.name,
                        style: MyTextTheme.BigStyle(color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Event Description
                      Text(
                        event.description,
                        style: MyTextTheme.smallStyle(
                          color: Colors.grey.shade300,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      // Date & Time
                      _buildInfoRow(
                        Icons.calendar_today_rounded,
                        DateFormatter.getFormattedDateTime(event.startTime),
                        iconSize,
                      ),
                      const SizedBox(height: 6),
                      // Capacity and Price
                      Row(
                        children: [
                          _buildInfoChip(
                            Icons.people_alt_outlined,
                            event.capacity.toString(),
                            iconSize,
                          ),
                          const SizedBox(width: 12),
                          _buildInfoChip(
                            Icons.attach_money_rounded,
                            event.isFree ? "Free" : "Paid",
                            iconSize,
                            color: event.isFree ? Colors.green : Colors.amber,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Location
                      _buildInfoRow(
                        Icons.location_on_rounded,
                        event.location['address'],
                        iconSize,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String text,
    double iconSize, {
    int? maxLines,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: iconSize, color: Colors.white.withOpacity(0.8)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: MyTextTheme.smallStyle(color: Colors.white.withOpacity(0.9)),
            maxLines: maxLines,
            overflow: maxLines != null ? TextOverflow.ellipsis : null,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String text,
    double iconSize, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.blue).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (color ?? Colors.blue).withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: color ?? Colors.white.withOpacity(0.8),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: MyTextTheme.smallStyle(color: Colors.white.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }

  void fetchEvent() async {
    if (controller.text.trim().isEmpty) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      List<Event> events = await EventRepository().searchEvent(
        controller.text.toString().trim(),
      );
      setState(() {
        searchedEvents = events;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        errorMessage = "Unable to load events. Please try again.";
        isLoading = false;
      });
    }
  }
}
