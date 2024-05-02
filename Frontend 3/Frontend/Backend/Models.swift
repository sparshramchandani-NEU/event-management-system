//
//  Models.swift
//  Frontend
//
//  Created by Aashay Pawar on 26/04/24.
//

import Foundation

struct Event: Decodable {
    let event_id: String
    let event_name: String
    let event_description: String
    let event_venue: String
    let event_date: String
    let ticket_price: Double
    let event_created: String
    let thumbnail: String?
    let seats_left: Int
}

struct Booking: Codable {
    let transaction_id: String
    let number_of_tickets: Int
    let total_price: Double
    let transaction_created: String
    let transaction_updated: String
    let user_id: String
    let event_id: String
    let event_name: String
}

struct EventData: Codable {
    let event_name: String
    let event_description: String
    let event_venue: String
    let total_seats: Int32
    let seats_left: Int32
    let event_date: String
    let ticket_price: Float
    let thumbnail: String
}

struct UserInfo: Decodable {
    var user_id: String
    let first_name: String?
    let last_name: String?
    var email: String?
    var password: String?
    let account_created: String?
}

