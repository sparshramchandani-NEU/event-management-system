import { Router } from "express";
import db from "../dbSetup.js";
import basicAuthenticator from "../middleware/basicAuthenticator.js";
import _ from "lodash";
import assignmentValidator from "../validators/assignment.validator.js";
import queryParameterValidators from "../validators/queryParameterValidators.js";
import urlValidator from "../validators/urlValidator.js";

const assignmentRouter = Router();
const assignmentDb = db.assignments;


assignmentRouter.use("/", async(req,res,next)=>{
    if(req.method !== "GET" && req.method!=="POST" && req.method!=="DELETE" && req.method!=="PUT"){
        return res.status(405).send();
    }
    next();
})
  

assignmentRouter.get("/",basicAuthenticator, queryParameterValidators, async (req, res) => {
  // add Validation for the user who create the assignments can only see his assignments
//   queryParameterValidators(req, res);
  const assignmentList = await assignmentDb.findAll({
    attributes: { exclude: ["user_id"] },
  });
  console.log(req.authUser);
  res.status(200).json(assignmentList);
});

assignmentRouter.get("/:id",basicAuthenticator, queryParameterValidators,async (req, res) => {
  const { id: assignmentId } = req.params;
  const assignmentInfo = await db.assignments.findOne({
    attributes: { exclude: ["user_id"] },
    where: { assignment_id: assignmentId },
  });
  if (_.isEmpty(assignmentInfo)) {
    return res.status(400).send();
  } else {
    res.status(200).json(assignmentInfo);
  }
});

assignmentRouter.post("/", basicAuthenticator,queryParameterValidators, async (req, res) => {
  // add Validation for empty body and missing fields

  const expectedKeys = ["name", "points", "num_of_attemps", "deadline"];

  // Check if there are any extra keys in the request body
  const extraKeys = Object.keys(req.body).filter(
    (key) => !expectedKeys.includes(key)
  );

  if (extraKeys.length > 0) {
    return res.status(400).json({
      errorMessage: `Invalid keys in the request: ${extraKeys.join(", ")}`,
    });
  }

  let { name, points, num_of_attemps, deadline } = req.body;

  const { isError: isNotValid, errorMessage } =
    assignmentValidator.validatePostRequest(req);
  if (isNotValid) {
    return res.status(400).json({ errorMessage });
  }

  const tempAssignment = {
    name,
    points,
    num_of_attemps,
    deadline,
    user_id: req?.authUser?.user_id,
  };
  //insert the data to data base
  const newAssignment = await assignmentDb.create(tempAssignment);
  console.log(newAssignment);
  res.status(201).json(newAssignment);
});

assignmentRouter.delete("/:id", basicAuthenticator,queryParameterValidators, async (req, res) => {
  const { id: assignmentId } = req.params;
  try{
    const assignmentInfo = await db.assignments.findOne({
        where: { assignment_id: assignmentId },
      });
  
  
  
    if (_.isEmpty(assignmentInfo)) {
        return res.status(400).send();
      } else if (assignmentInfo.user_id !== req?.authUser?.user_id) {
        return res.status(403).json({ error: "Your are not authorized user" });
      }
  

  

  await db.assignments.destroy({ where: { assignment_id: assignmentId } });

  return res.status(204).json();
}catch(err){
    res.status(404).send();
  }
});

assignmentRouter.put("/:id", basicAuthenticator, async (req, res) => {
  const { id: assignmentId } = req.params;

  const { isError: isNotValid, errorMessage } =
    assignmentValidator.validateUpdateRequest(req);
  if (isNotValid) {
    return res.status(400).json({ errorMessage });
  }

  try{
    const assignmentInfo = await db.assignments.findOne({
        where: { assignment_id: assignmentId },
      });
 
    if (_.isEmpty(assignmentInfo)) {
        return res.status(400).send();
      } else if (assignmentInfo.user_id !== req?.authUser?.user_id) {
        return res.status(403).json({ error: "Your are not authorized user" });
      }

  const expectedKeys = ["name", "points", "num_of_attemps", "deadline"];

  // Check if there are any extra keys in the request body
  const extraKeys = Object.keys(req.body).filter(
    (key) => !expectedKeys.includes(key)
  );

  if (extraKeys.length > 0) {
    return res.status(400).json({
      errorMessage: `Invalid keys in the request: ${extraKeys.join(", ")}`,
    });
  }

  const { name, points, num_of_attemps, deadline } = req.body;

  let updatedAssignment = {};
  updatedAssignment = appendDataToObject(updatedAssignment, "name", name);
  updatedAssignment = appendDataToObject(updatedAssignment, "points", points);
  updatedAssignment = appendDataToObject(
    updatedAssignment,
    "num_of_attemps",
    num_of_attemps
  );
  updatedAssignment = appendDataToObject(
    updatedAssignment,
    "deadline",
    deadline
  );

  await db.assignments.update(updatedAssignment, {
    where: { assignment_id: assignmentId },
  });

  return res.status(204).end(); //add success messgae
}catch(err){
    res.status(404).send();
}

  // check Validation if the user is not entering the id itself
});

function appendDataToObject(object, field, value) {
  if (!_.isNil(value)) {
    object[field] = value;
  }
  return object;
}

export default assignmentRouter;
