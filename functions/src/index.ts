import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import { Request, Response } from "express";

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

admin.initializeApp();
const db = admin.firestore();

// Create Event
export const createEvent = functions.https.onRequest(async (req: Request, res: Response) => {
    const { title, description, date, location, organizer, eventType } = req.body;

    if (!title || !description || !date || !location || !organizer || !eventType) {
        res.status(400).send("Missing required fields");
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
    } catch (error: any) { // Ensure error typing
        res.status(500).send(error.message);
    }
});

// Get All Events
export const getAllEvents = functions.https.onRequest(async (req: Request, res: Response) => {
    try {
        const snapshot = await db.collection("events").get();
        const events = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
        res.status(200).json(events);
    } catch (error: any) {
        res.status(500).send(error.message);
    }
});

// Get Event by ID
export const getEventById = functions.https.onRequest(async (req: Request, res: Response) => {
    const { id } = req.query;

    if (!id) {
        res.status(400).send("Event ID is required");
        return;
    }

    try {
        const eventDoc = await db.collection("events").doc(String(id)).get();
        if (!eventDoc.exists) {
            res.status(404).send("Event not found");
            return;
        }
        res.status(200).json({ id: eventDoc.id, ...eventDoc.data() });
    } catch (error: any) {
        res.status(500).send(error.message);
    }
});

// Update Event
export const updateEvent = functions.https.onRequest(async (req: Request, res: Response) => {
    const { id } = req.query;
    const { title, description, date, location, organizer, eventType } = req.body;

    if (!id) {
        res.status(400).send("Event ID is required");
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
        res.status(200).send("Event updated");
    } catch (error: any) {
        res.status(500).send(error.message);
    }
});

// Delete Event
export const deleteEvent = functions.https.onRequest(async (req: Request, res: Response) => {
    const { id } = req.query;

    if (!id) {
        res.status(400).send("Event ID is required");
        return;
    }

    try {
        await db.collection("events").doc(String(id)).delete();
        res.status(200).send("Event deleted");
    } catch (error: any) {
        res.status(500).send(error.message);
    }
});

// Filter Events by Event Type or Date
export const filterEvents = functions.https.onRequest(async (req: Request, res: Response): Promise<void> => {
    const { eventType, date } = req.query;

    // Explicitly type the query as a FirebaseFirestore.Query
    let query: FirebaseFirestore.Query<FirebaseFirestore.DocumentData> = db.collection("events");

    // Apply filters if they are present in the query
    if (eventType) {
        query = query.where("eventType", "==", String(eventType));
    }

    if (date) {
        query = query.where(
            "date",
            "==",
            admin.firestore.Timestamp.fromDate(new Date(String(date)))
        );
    }

    try {
        const snapshot = await query.get();  // Execute the query
        const events = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));  // Extract event data
        res.status(200).json(events);  // Return the events in the response
    } catch (error: any) {
        res.status(500).send(error.message);  // Handle any errors
    }
});

// Firestore Trigger to update `updatedAt` field automatically
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