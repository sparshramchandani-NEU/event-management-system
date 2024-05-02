import _ from "lodash";

const validatePassword = (password) => {
  // Regular expressions to validate password criteria
  const uppercaseRegex = /[A-Z]/; // At least one uppercase letter
  const numberRegex = /[0-9]/; // At least one number
  const specialCharRegex = /[!@#$%^&*(),.?":{}|<>]/; // At least one special character

  // Check if password meets all criteria
  return (
    uppercaseRegex.test(password) &&
    numberRegex.test(password) &&
    specialCharRegex.test(password)
  );
};

const isValidEmail = (email) => {
  // Regular expression to validate email format
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

const validateUserPostRequest = (req) => {
  const { first_name, last_name, email, password, role } = req.body;
  let isError = false;
  let errorMessage = "";

  if (_.isNil(first_name) || _.isEmpty(first_name)) {
    isError = true;
    errorMessage += "First name cannot be null or empty\n";
  }

  if (_.isNil(last_name) || _.isEmpty(last_name)) {
    isError = true;
    errorMessage += "Last name cannot be null or empty\n";
  }

  if (_.isNil(email) || !_.isString(email) || !isValidEmail(email)) {
    isError = true;
    errorMessage += "Valid email is required\n";
  }

  if (_.isNil(password) || !_.isString(password) || password.length < 6 || !validatePassword(password)) {
    isError = true;
    errorMessage += "Password is required and must be at least 6 characters long containing at least one uppercase letter, one number, and one special character\n";
  }

  const defaultRole = "user"; // Default role set to "user"

  return { isError, errorMessage, role: defaultRole };
};

const validateUserUpdateRequest = (req) => {
    const { first_name, last_name, email, password } = req.body;
    let isError = false;
    let errorMessage = "";
  
    // Check if any field other than allowed fields is provided
    const allowedFields = ['first_name', 'last_name', 'email', 'password'];
    const otherFields = Object.keys(req.body).filter(key => !allowedFields.includes(key));
    if (otherFields.length > 0) {
      isError = true;
      errorMessage += `Only the following fields can be updated: ${allowedFields.join(', ')}\n`;
    }
  
    // Validate the password field
    if (_.isNil(password) || (!_.isString(password) || password.length < 6 || !validatePassword(password))) {
      isError = true;
      errorMessage += "Password must be a string of at least 6 characters containing at least one uppercase letter, one number, and one special character\n";
    }
  
    return { isError, errorMessage };
  };
  
export default {
  validateUserPostRequest,
  validateUserUpdateRequest,
};
