import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  String id;
  String title;
  String description;
  Timestamp date;
  String location;
  String organizer;
  String eventType;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.organizer,
    required this.eventType,
  });

  // Create an Event from Firestore document
  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: data['date'],
      location: data['location'] ?? '',
      organizer: data['organizer'] ?? '',
      eventType: data['eventType'] ?? '',
    );
  }
}