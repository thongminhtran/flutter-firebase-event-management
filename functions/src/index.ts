import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import { Request, Response } from "express";

admin.initializeApp();
const db = admin.firestore();

// Event interface
interface Event {
    title: string;
    description: string;
    date: FirebaseFirestore.Timestamp;
    location: string;
    organizer: string;
    eventType: string;
    updatedAt: FirebaseFirestore.FieldValue;
}

// Create Event
export const createEvent = functions.https.onRequest(async (req: Request, res: Response) => {
    const { title, description, date, location, organizer, eventType } = req.body;

    if (!title || !description || !date || !location || !organizer || !eventType) {
        functions.logger.error("Missing required fields in createEvent request");
        res.status(400).json({ error: "Missing required fields" });
        return;
    }

    try {
        const newEvent: Event = {
            title,
            description,
            date: admin.firestore.Timestamp.fromDate(new Date(date)),
            location,
            organizer,
            eventType,
            updatedAt: FieldValue.serverTimestamp(),
        };

        const eventRef = await db.collection("events").add(newEvent);
        res.status(201).json({ id: eventRef.id });
    } catch (error: any) {
        functions.logger.error("Error creating event", error);
        res.status(500).json({ error: "Failed to create event" });
    }
});

// Get All Events
export const getAllEvents = functions.https.onRequest(async (req: Request, res: Response) => {
    try {
        const snapshot = await db.collection("events").get();
        const events = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
        res.status(200).json(events);
    } catch (error: any) {
        functions.logger.error("Error fetching all events", error);
        res.status(500).json({ error: "Failed to fetch events" });
    }
});

// Get Event by ID
export const getEventById = functions.https.onRequest(async (req: Request, res: Response) => {
    const { id } = req.query;

    if (!id) {
        res.status(400).json({ error: "Event ID is required" });
        return;
    }

    try {
        const eventDoc = await db.collection("events").doc(String(id)).get();
        if (!eventDoc.exists) {
            res.status(404).json({ error: "Event not found" });
            return;
        }
        res.status(200).json({ id: eventDoc.id, ...eventDoc.data() });
    } catch (error: any) {
        functions.logger.error(`Error fetching event with ID: ${id}`, error);
        res.status(500).json({ error: "Failed to fetch event" });
    }
});

// Update Event
export const updateEvent = functions.https.onRequest(async (req: Request, res: Response) => {
    const { id } = req.query;
    const { title, description, date, location, organizer, eventType } = req.body;

    if (!id) {
        res.status(400).json({ error: "Event ID is required" });
        return;
    }

    try {
        const updatedEvent = {
            title,
            description,
            date: admin.firestore.Timestamp.fromDate(new Date(date)),
            location,
            organizer,
            eventType,
            updatedAt: FieldValue.serverTimestamp(),
        };

        await db.collection("events").doc(String(id)).update(updatedEvent);
        res.status(200).json({ message: "Event updated" });
    } catch (error: any) {
        functions.logger.error(`Error updating event with ID: ${id}`, error);
        res.status(500).json({ error: "Failed to update event" });
    }
});

// Delete Event
export const deleteEvent = functions.https.onRequest(async (req: Request, res: Response) => {
    const { id } = req.query;

    if (!id) {
        res.status(400).json({ error: "Event ID is required" });
        return;
    }

    try {
        await db.collection("events").doc(String(id)).delete();
        res.status(200).json({ message: "Event deleted" });
    } catch (error: any) {
        functions.logger.error(`Error deleting event with ID: ${id}`, error);
        res.status(500).json({ error: "Failed to delete event" });
    }
});

// Filter Events by Event Type or Date
export const filterEvents = functions.https.onRequest(async (req: Request, res: Response): Promise<void> => {
    const { eventType, date } = req.query;

    let query: FirebaseFirestore.Query<FirebaseFirestore.DocumentData> = db.collection("events");

    if (eventType) {
        query = query.where("eventType", "==", String(eventType));
    }

    if (date) {
        query = query.where("date", "==", admin.firestore.Timestamp.fromDate(new Date(String(date))));
    }

    try {
        const snapshot = await query.get();
        const events = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
        res.status(200).json(events);
    } catch (error: any) {
        functions.logger.error("Error filtering events", error);
        res.status(500).json({ error: "Failed to filter events" });
    }
});

// Firestore Trigger to update `updatedAt` field
export const updateTimestamp = functions.firestore
    .document("events/{eventId}")
    .onWrite((change, context) => {
        if (!change.after.exists) {
            return null;
        }

        return change.after.ref.set(
            {
                updatedAt: FieldValue.serverTimestamp(),
            },
            { merge: true }
        );
    });