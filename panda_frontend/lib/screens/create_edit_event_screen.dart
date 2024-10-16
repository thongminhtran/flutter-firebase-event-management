import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart'; // Import the Event model

class CreateEditEventScreen extends StatefulWidget {
  final Event? event; // This will be null if we are creating a new event

  CreateEditEventScreen({this.event});

  @override
  _CreateEditEventScreenState createState() => _CreateEditEventScreenState();
}

class _CreateEditEventScreenState extends State<CreateEditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late String title;
  late String description;
  late String location;
  late String organizer;
  late String eventType;

  @override
  void initState() {
    super.initState();
    // If editing an event, prefill the form with the existing data
    title = widget.event?.title ?? '';
    description = widget.event?.description ?? '';
    location = widget.event?.location ?? '';
    organizer = widget.event?.organizer ?? '';
    eventType = widget.event?.eventType ?? 'Conference'; // Default event type
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.event == null ? 'Create Event' : 'Edit Event')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: title,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                onSaved: (value) => title = value!,
              ),
              TextFormField(
                initialValue: description,
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                onSaved: (value) => description = value!,
              ),
              TextFormField(
                initialValue: location,
                decoration: InputDecoration(labelText: 'Location'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
                onSaved: (value) => location = value!,
              ),
              TextFormField(
                initialValue: organizer,
                decoration: InputDecoration(labelText: 'Organizer'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the organizer\'s name';
                  }
                  return null;
                },
                onSaved: (value) => organizer = value!,
              ),
              DropdownButtonFormField(
                value: eventType,
                decoration: InputDecoration(labelText: 'Event Type'),
                items: ['Conference', 'Workshop', 'Webinar']
                    .map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                ))
                    .toList(),
                onChanged: (value) => setState(() => eventType = value as String),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    // Create or update event in Firestore
                    if (widget.event == null) {
                      // Create a new event
                      await FirebaseFirestore.instance.collection('events').add({
                        'title': title,
                        'description': description,
                        'location': location,
                        'organizer': organizer,
                        'eventType': eventType,
                        'date': Timestamp.now(),
                      });
                    } else {
                      // Update the existing event
                      await FirebaseFirestore.instance.collection('events').doc(widget.event!.id).update({
                        'title': title,
                        'description': description,
                        'location': location,
                        'organizer': organizer,
                        'eventType': eventType,
                      });
                    }
                    Navigator.pop(context);
                  }
                },
                child: Text(widget.event == null ? 'Create Event' : 'Update Event'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}