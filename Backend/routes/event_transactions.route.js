import { Router } from "express";
import db from "../dbSetup.js";
import basicAuthenticator from "../middleware/basicAuthenticator.js";
import _ from "lodash";
import queryParameterValidators from "../validators/queryParameterValidators.js";
import urlValidator from "../validators/urlValidator.js";

const eventTransactionRouter = Router();
const eventTransactionDb = db.transactions;
const userDB = db.users;
const eventDB = db.events;

eventTransactionRouter.use("/", async (req, res, next) => {
  if (
    req.method !== "GET" &&
    req.method !== "POST"
  ) {
    return res.status(405).send();
  }
  next();
});

eventTransactionRouter.get("/",basicAuthenticator, queryParameterValidators, async (req, res) => {
  const eventTransactionList = await eventTransactionDb.findAll();
  console.log(req.authUser);

  try {
    if (req.authUser.role !== "admin") {
      return res.status(403).send();
    } else {
      res.status(200).json(eventTransactionList);
    }
  } catch (e) {
    return res.status(403).json({errorMessage:e.message});
  }
});

eventTransactionRouter.get("/user_transactions",basicAuthenticator, queryParameterValidators, async (req, res) => {
    const user = await userDB.findByPk(req.authUser.user_id);
    const userTransactions = await eventTransactionDb.findAll({
        where: {
          user_id: user.user_id,
        },
        });
    res.status(200).json(userTransactions);
});

eventTransactionRouter.post("/:eventId", basicAuthenticator, queryParameterValidators, async (req, res) => {
    try {
        // Retrieve the authenticated user
        const user = await userDB.findByPk(req.authUser.user_id);

        // Retrieve the event associated with the provided eventId
        const event = await eventDB.findByPk(req.params.eventId);
        if (!event) {
            return res.status(404).json({ errorMessage: "Event not found" });
        }

        // Extract relevant data from the request body
        const { number_of_tickets } = req.body;

        // Ensure the number of tickets is a positive integer
        if (number_of_tickets <= 0 || !Number.isInteger(number_of_tickets)) {
            return res.status(400).json({ errorMessage: "Number of tickets must be a positive integer" });
        }

        // Ensure there are enough tickets left for the event
        if (event.seats_left < number_of_tickets) {
            return res.status(400).json({ errorMessage: "Not enough tickets left for this event" });
        }

        // Calculate total price based on the number of tickets and ticket price of the event
        const total_price = number_of_tickets * event.ticket_price;

        // Calculate the updated number of seats left for the event
        const updatedSeatsLeft = event.seats_left - number_of_tickets;
        
        // Create the event transaction
        const newTransaction = await eventTransactionDb.create({
            number_of_tickets,
            total_price, 
            event_name : event.event_name,
        });
        
        // Associate the user and event with the transaction
        await newTransaction.setUser(user);
        await newTransaction.setEvent(event);
        
        await event.update({ seats_left: updatedSeatsLeft });
        // Send response with the created transaction
        res.status(201).json(newTransaction);
    } catch (error) {
        console.error("Error creating event transaction:", error);
        res.status(500).json({ errorMessage: error.message });
    }
});

eventTransactionRouter.get("/:transactionId", basicAuthenticator, queryParameterValidators, async (req, res) => {
    try {
        // Retrieve the authenticated user
        const user = await userDB.findByPk(req.authUser.user_id);

        // Retrieve the transaction associated with the provided transactionId
        const transaction = await eventTransactionDb.findByPk(req.params.transactionId);
        if (!transaction) {
            return res.status(404).json({ errorMessage: "Transaction not found" });
        }

        // Ensure the user is authorized to view the transaction
        if (transaction.user_id !== user.user_id && user.role !== "admin") {
            return res.status(403).json({ errorMessage: "Unauthorized to view this transaction" });
        }

        // Send response with the transaction
        res.status(200).json(transaction);
    } catch (error) {
        console.error("Error retrieving event transaction:", error);
        res.status(500).json({ errorMessage: error.message });
    }
}
);

export default eventTransactionRouter;
