import { Router } from "express";
import brcrypt from 'bcryptjs';
import db from "../dbSetup.js";
import basicAuthenticator from "../middleware/basicAuthenticator.js";
import _ from "lodash";
import assignmentValidator from "../validators/assignment.validator.js";
import userValidator from "../validators/user.validator.js";
import queryParameterValidators from "../validators/queryParameterValidators.js";
import urlValidator from "../validators/urlValidator.js";
import nodemailer from 'nodemailer';
import { v4 as uuidv4 } from 'uuid';



const userRouter = Router();
const userDB = db.users;

userRouter.use("/", async(req,res,next)=>{
    if(req.method !== "GET" && req.method!=="POST" && req.method!=="DELETE" && req.method!=="PUT"){
        return res.status(405).send();
    }
    next();
})

userRouter.get("/login", basicAuthenticator,queryParameterValidators, async (req, res) => {
    const authUser = req.authUser;

    if (authUser) {
        if(authUser.role === "admin"){
            return res.status(200).json({message: "Admin logged in successfully", role: authUser.role});
        }
        res.status(200).json({message: authUser.user_id, role: authUser.role});
    }
});

userRouter.get("/",basicAuthenticator, queryParameterValidators, async (req, res) => {
    const users = await userDB.findAll();
    res.send(users);
}   
);

userRouter.get("/:id",basicAuthenticator, queryParameterValidators, async (req, res) => {
    const user = await userDB.findByPk(req.params.id);
    if (user) {
        res.send(user);
    } else {
        res.status(404).send();
    }
}
);

userRouter.post("/", queryParameterValidators, async (req, res) => {
    try {
      const { first_name, last_name, email, password, role } = req.body;
  
      // Validate user creation request
      const { isError: isNotValid, errorMessage } = userValidator.validateUserPostRequest(req);
  
      if (isNotValid) {
        return res.status(400).json({ errorMessage });
      }
  
      // Check if a user with the same email already exists in the database
      const existingUser = await userDB.findOne({ where: { email } });
  
      if (existingUser) {
        return res.status(400).json({ errorMessage: "Email address already exists" });
      }
  
      // If role is not provided in request, set default role to "user"
      const userRole = role || "user";
  
      // Encrypt the password using bcrypt with salt 10
      const hashedPassword = await brcrypt.hash(password, 10);
  
      // Insert the data into the database
      const newUser = await userDB.create({
        first_name,
        last_name,
        email,
        password: hashedPassword,
        role: userRole,
      });
  
      res.status(201).json(newUser);
    } catch (error) {
      console.error("Error creating user:", error);
      res.status(500).json({ errorMessage: "Error creating user" });
    }
  });  

  userRouter.put("/:id",basicAuthenticator, async (req, res) => {
    try {
      // Extract user ID from request parameters
      const { id: userId } = req.params;
  
      // Extract fields from request body
      let { first_name, last_name, email, password, role } = req.body;
  
      // Validate the request body
      const { isError: isNotValid, errorMessage } =
        userValidator.validateUserUpdateRequest(req);
  
      // If validation fails, return error response
      if (isNotValid) {
        return res.status(400).json({ errorMessage });
      }
      // If existing user found and it's not the same user being updated, return error response
      const userInfo = await db.users.findOne({
        where: { user_id: userId },
      });
 
    if (_.isEmpty(userInfo)) {
        return res.status(400).send();
      } else if (userInfo.user_id !== req?.authUser?.user_id && req?.authUser?.role !== "admin") {
        return res.status(403).json({ error: "Your are not authorized user" });
      }
  
      // Construct updatedUser object with valid fields
      const updatedUser = {
        first_name,
        last_name,
        email,
        role: role || userInfo.role,  // If role is not provided in request, use existing role
      };
  
      // If password is provided in the request, hash it and include it in updatedUser object
      if (password) {
        const hashedPassword = await brcrypt.hash(password, 10); // Hash the password
        updatedUser.password = hashedPassword; // Include hashed password in updatedUser object
      }
  
      // Update the user in the database
      await userDB.update(updatedUser, { where: { user_id: userId } });
  
      // Fetch and return the updated user from the database
      const updatedUserInfo = await userDB.findByPk(userId);
      return res.status(200).json(updatedUserInfo);
    } catch (error) {
      console.error("Error updating user:", error);
      return res.status(500).json({ errorMessage: error.message });
    }
  });

// Create a transporter for sending emails
const transporter = nodemailer.createTransport({
  service: 'gmail',
  host: 'smtp.gmail.com',
    port: 587,
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASSWORD,
  },
});

userRouter.post("/forgot-password", async (req, res) => {
  try {
    const { email } = req.body;

    // Check if the user exists
    const user = await userDB.findOne({ where: { email } });
    if (!user) {
      return res.status(404).json({ errorMessage: "User not found" });
    }

    // Generate a new password
    const newPassword = generateRandomPassword(); // Implement this function to generate a random password

    // Encrypt the new password
    const hashedPassword = await brcrypt.hash(newPassword, 10);

    // Update the user's password in the database
    await user.update({ password: hashedPassword });

    // Send the user their new password via email
    const mailOptions = {
        from: '"Events App" <' + process.env.EMAIL_USER + '>',
        to: email,
        subject: 'Your New Password',
        text: `Your new password is: ${newPassword}`
      };
      

    transporter.sendMail(mailOptions, (error, info) => {
      if (error) {
        console.error('Error sending email:', error);
        return res.status(500).json({ errorMessage: error.message });
      } else {
        console.log('Email sent:', info.response);
        return res.status(200).json({ message: "New password sent successfully" });
      }
    });
  } catch (error) {
    console.error("Error sending new password:", error);
    return res.status(500).json({ errorMessage: error.message });
  }
});

  function generateRandomPassword(length = 10) {
    const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    let password = "";
    for (let i = 0; i < length; i++) {
      const randomIndex = Math.floor(Math.random() * charset.length);
      password += charset[randomIndex];
    }
    return password;
  }

export default userRouter;