import 'package:flutter/material.dart';
import '../models/event_model.dart'; // Import the Event model
import 'create_edit_event_screen.dart'; // Import Create/Edit Event screen
import 'package:cloud_firestore/cloud_firestore.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;

  EventDetailScreen({required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              // Navigate to the Edit Event screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateEditEventScreen(event: event),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () async {
              // Delete the event
              await FirebaseFirestore.instance.collection('events').doc(event.id).delete();
              Navigator.pop(context); // Go back after deletion
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${event.title}', style: TextStyle(fontSize: 20)),
            SizedBox(height: 8),
            Text('Description: ${event.description}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Date: ${event.date.toDate()}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Location: ${event.location}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Organizer: ${event.organizer}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Type: ${event.eventType}', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}