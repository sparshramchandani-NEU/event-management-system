import { Router } from "express";
import db from "../dbSetup.js";
import basicAuthenticator from "../middleware/basicAuthenticator.js";
import _ from "lodash";
import queryParameterValidators from "../validators/queryParameterValidators.js";
import urlValidator from "../validators/urlValidator.js";
import eventValidator from "../validators/eventValidator.js";

const eventRouter = Router();
const eventDb = db.events;
const userDB = db.users;

eventRouter.use("/", async (req, res, next) => {
  if (
    req.method !== "GET" &&
    req.method !== "POST" &&
    req.method !== "DELETE" &&
    req.method !== "PUT"
  ) {
    return res.status(405).send();
  }
  next();
});

eventRouter.get(
  "/",
  basicAuthenticator,
  queryParameterValidators,
  async (req, res) => {
    const eventList = await eventDb.findAll();
    console.log(req.authUser);
    res.status(200).json(eventList);
  }
);

eventRouter.get("/user_events", basicAuthenticator, queryParameterValidators, async (req, res) => {
  try {
    const user = await userDB.findByPk(req.authUser.user_id);
    if (!user) {
      return res.status(404).json({ errorMessage: "User not found" });
    }

    // Assuming there's an association between users and events
    const userEvents = await user.getEvents();

    res.status(200).json(userEvents);
  } catch (error) {
    console.error("Error fetching user events:", error);
    res.status(500).json({ errorMessage: "Internal server error" });
  }
});

eventRouter.get(
  "/:id",
  basicAuthenticator,
  queryParameterValidators,
  async (req, res) => {
    const { id: eventId } = req.params;
    const eventInfo = await db.events.findOne({
      where: { event_id: eventId },
    });
    if (_.isEmpty(eventInfo)) {
      return res.status(400).send();
    } else {
      res.status(200).json(eventInfo);
    }
  }
);

eventRouter.post(
  "/",
  basicAuthenticator,
  queryParameterValidators,
  async (req, res) => {
    const expectedKeys = [
      "event_name",
      "event_description",
      "event_venue",
      "total_seats",
      "seats_left",
      "event_date",
      "ticket_price",
      "thumbnail",
    ];

    // Check if there are any extra keys in the request body
    const extraKeys = Object.keys(req.body).filter(
      (key) => !expectedKeys.includes(key)
    );

    if (extraKeys.length > 0) {
      return res.status(400).json({
        errorMessage: `Invalid keys in the request: ${extraKeys.join(", ")}`,
      });
    }

    let {
      event_name,
      event_description,
      event_venue,
      total_seats,
      seats_left,
      event_date,
      ticket_price,
      thumbnail,
    } = req.body;

    const { isError: isNotValid, errorMessage } =
      eventValidator.validatePostRequest(req);
    if (isNotValid) {
      return res.status(400).json({ errorMessage });
    }

    const event = {
      event_name,
      event_description,
      event_venue,
      total_seats,
      seats_left,
      event_date,
      ticket_price,
      user_id: req?.authUser?.user_id,
    };

    if (thumbnail) {
      event.thumbnail = thumbnail; // Include thumbnail if it exists in the request body
    }

    const newEvent = await eventDb.create(event);
    res.status(201).json(newEvent);
  }
);

eventRouter.put(
  "/:id",
  basicAuthenticator,
  queryParameterValidators,
  async (req, res) => {
    const { id: eventId } = req.params;
    const event = await db.events.findOne({
      where: { event_id: eventId },
    });
    const authUser = req.authUser;

    if (_.isEmpty(event)) {
      return res.status(404).send();
    } else if (
      event.user_id !== authUser.user_id &&
      authUser.role !== "admin"
    ) {
      return res
        .status(403)
        .json({
          errorMessage: "You are not authorized to update this event test",
        });
    }

    const {
      event_name,
      event_description,
      event_venue,
      total_seats,
      seats_left,
      event_date,
      ticket_price,
      thumbnail,
    } = req.body;

    const { isError: isNotValid, errorMessage } =
      eventValidator.validateUpdateRequest(req);

    if (isNotValid) {
      return res.status(400).json({ errorMessage });
    }

    // Use the update method and capture the result
    const updateFields = {
      event_name,
      event_description,
      event_venue,
      total_seats,
      seats_left,
      event_date,
      ticket_price,
    };

    if (thumbnail) {
      updateFields.thumbnail = thumbnail; // Include thumbnail if it exists in the request body
    }

    const [rowsAffected, [updatedEvent]] = await db.events.update(
      updateFields,
      { where: { event_id: eventId }, returning: true } // Add returning: true to return the updated record
    );

    res.status(200).json(updatedEvent); // Return the updated event
  }
);

eventRouter.delete(
  "/:id",
  basicAuthenticator,
  queryParameterValidators,
  async (req, res) => {
    const { id: eventId } = req.params;
    const event = await db.events.findOne({
      where: { event_id: eventId },
    });
    const authUser = req.authUser;

    if (_.isEmpty(event)) {
      return res.status(404).send();
    } else if (
      event.user_id !== authUser.user_id &&
      authUser.role !== "admin"
    ) {
      return res
        .status(403)
        .json({
          errorMessage: "You are not authorized to delete this event",
        });
    }

    await db.events.destroy({ where: { event_id: eventId } });
    res.status(204).send();
  }
);

export default eventRouter;
