import _ from 'lodash';

const validatePostRequest = (req) => {
    const { event_name, event_description, event_venue, total_seats, seats_left, event_date, ticket_price } = req.body;
    let isError = false;
    let errorMessage = '';
    if (_.isNil(event_name) || _.isEmpty(event_name)) {
        isError = true;
        errorMessage += 'Event name cannot be null or empty\n';
    }
    if (_.isNil(event_description) || _.isEmpty(event_description)) {
        isError = true;
        errorMessage += 'Event description cannot be null or empty\n';
    }
    if (_.isNil(event_venue) || _.isEmpty(event_venue)) {
        isError = true;
        errorMessage += 'Event venue cannot be null or empty\n';
    }
    if (_.isNil(total_seats) || !_.inRange(total_seats, 1, 1001)) {
        isError = true;
        errorMessage += 'Total seats need to be in range of 1-1000\n';
    }
    if (_.isNil(seats_left) || !_.inRange(seats_left, 1, 1001)) {
        isError = true;
        errorMessage += 'Seats left need to be in range of 1-1000\n';
    }
    if (_.isNil(event_date) || !_.isString(event_date) || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/.test(event_date)) {
        isError = true;
        errorMessage += 'The event date is required and should be in the format 16-08-29T09:12:33.001Z';
    }
    if (_.isNil(ticket_price) || !_.inRange(ticket_price, 1, 10001)) {
        isError = true;
        errorMessage += 'Ticket price need to be in range of 1-10000\n';
    }
    const currentTimestamp = new Date().toISOString();
    if (event_date <= currentTimestamp) {
        isError = true;
        errorMessage += 'The event date should be ahead of the current date\n';
    }
    return { isError, errorMessage };
}

const validateUpdateRequest = (req) => {
    const { event_name, event_description, event_venue, total_seats, seats_left, event_date, ticket_price } = req.body;
    let isError = false;
    let errorMessage = '';
    if (_.isNil(event_name) || _.isEmpty(event_name)) {
        isError = true;
        errorMessage += 'Event name cannot be null or empty\n';
    }
    if (_.isNil(event_description) || _.isEmpty(event_description)) {
        isError = true;
        errorMessage += 'Event description cannot be null or empty\n';
    }
    if (_.isNil(event_venue) || _.isEmpty(event_venue)) {
        isError = true;
        errorMessage += 'Event venue cannot be null or empty\n';
    }
    if (!_.isNil(total_seats) && !_.inRange(total_seats, 1, 1001)) {
        isError = true;
        errorMessage += 'Total seats need to be in range of 1-1000\n';
    }
    if (!_.isNil(seats_left) && !_.inRange(seats_left, 1, 1001)) {
        isError = true;
        errorMessage += 'Seats left need to be in range of 1-1000\n';
    }
    if (!_.isNil(event_date) && (!_.isString(event_date) || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/.test(event_date))) {
        isError = true;
        errorMessage += 'The event date is required and should be in the format 16-08-29T09:12:33.001Z';
    }
    if (!_.isNil(ticket_price) && !_.inRange(ticket_price, 1, 10001)) {
        isError = true;
        errorMessage += 'Ticket price need to be in range of 1-10000\n';
    }
    const currentTimestamp = new Date().toISOString();
    if (event_date <= currentTimestamp) {
        isError = true;
        errorMessage += 'The event date should be ahead of the current date\n';
    }
    return { isError, errorMessage };
}

export default { validatePostRequest, validateUpdateRequest };