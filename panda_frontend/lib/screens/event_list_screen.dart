import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import 'create_edit_event_screen.dart';
import 'event_detail_screen.dart';

class EventListScreen extends StatefulWidget {
  @override
  _EventListScreenState createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  String? selectedEventType; // To store the selected event type
  final List<String> eventTypes = ["All", "Conference", "Workshop", "Webinar"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Events'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: PopupMenuButton<String>(
              onSelected: (String newValue) {
                setState(() {
                  selectedEventType = newValue;
                });
              },
              itemBuilder: (BuildContext context) {
                return eventTypes.map((String type) {
                  return PopupMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white, // Set background color like the dropdown
                ),
                child: Row(
                  children: [
                    Text(
                      selectedEventType ?? 'Filter',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.filter_list, color: Colors.black),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Event>>(
        stream: fetchEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load events. Please try again.',
                style: TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No events found'));
          }

          // Filter events based on the selected event type
          List<Event> filteredEvents = snapshot.data!;
          if (selectedEventType != null && selectedEventType != "All") {
            filteredEvents = filteredEvents
                .where((event) => event.eventType == selectedEventType)
                .toList();
          }

          // Sort events so the newest appear at the bottom
          filteredEvents.sort((a, b) => a.date.compareTo(b.date));

          return ListView.builder(
            itemCount: filteredEvents.length + 1,
            // +1 for the add button at the end
            itemBuilder: (context, index) {
              if (index == filteredEvents.length) {
                // Add button at the end of the list
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to CreateEditEventScreen for adding a new event
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateEditEventScreen(),
                        ),
                      );
                    },
                    icon: Icon(Icons.add),
                    label: Text('Add New Event'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
                );
              }

              final event = filteredEvents[index];
              return Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Card(
                  elevation: 2.0,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      child: Text(
                        '${index + 1}', // Display index as number on the left
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      event.title,
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      event.eventType,
                      style: TextStyle(fontSize: 14),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            // Navigate to the Edit Event screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CreateEditEventScreen(event: event),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            // Show confirmation dialog before deleting
                            _showDeleteConfirmation(context, event.id);
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      // Navigate to event detail screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventDetailScreen(event: event),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Stream<List<Event>> fetchEvents() {
    try {
      return FirebaseFirestore.instance.collection('events').snapshots().map(
            (snapshot) {
          return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
        },
      );
    } catch (e) {
      throw Exception("Error fetching events");
    }
  }

  void _showDeleteConfirmation(BuildContext context, String eventId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Event"),
          content: Text("Are you sure you want to delete this event?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("No"),
            ),
            TextButton(
              onPressed: () {
                _deleteEvent(
                    eventId, context); // Delete the event and close dialog
              },
              child: Text("Yes", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _deleteEvent(String eventId, BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .delete();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Event deleted")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete event")),
      );
    }
  }
}