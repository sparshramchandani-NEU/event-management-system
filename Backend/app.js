import express from 'express';
import appRoute from './routes/app.route.js';
// import assignmentRoute from './routes/assignment.route.js';
import userRoute from './routes/users.route.js';
import eventRoute from './routes/events.route.js';
import eventTransactionRoute from './routes/event_transactions.route.js';
import dotenv from 'dotenv';

const app=express();
const PORT= process.env.PORT || 3000;
app.use(express.json());
app.use("/healthz",appRoute);
app.use("/users",userRoute);
app.use("/events", eventRoute);
app.use("/transactions", eventTransactionRoute);
// app.use("/v1/assignments", assignmentRoute);
app.use("/",(req,res)=>res.status(503).send())
app.listen(PORT,(err)=>{
    if(err){
        console.log("Failed to start the application")
    }else{
        console.log("Application running on port number ",PORT);
        console.log("PGHOST: ", process.env.PGHOST);
        console.log("PGUSER: ", process.env.PGUSER);
        console.log("PGDATABASE: ", process.env.PGDATABASE);
        console.log("PGPASSWORD: ", process.env.PGPASSWORD);
        console.log("PGPORT: ", process.env.PGPORT);
        console.log("Email: ", process.env.EMAIL_USER);
        console.log("Password: ", process.env.EMAIL_PASSWORD);
    }
})
