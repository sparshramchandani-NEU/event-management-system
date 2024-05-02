const urlValidator = (req, res, next) => {
    if (!req.params || Object.keys(req.params).length > 0) {
        res.setHeader("Cache-Control", "no-store");
        return res.status(400).json({ message: "Assignmnet ID cannot be null" });
    }
    // Call the next middleware or route handler
    next();
}

export default urlValidator;
