import { Sequelize } from "sequelize";

export default (sequelize, DataTypes) => {
  const Event = sequelize.define(
    "event",
    {
      event_id: {
        type: DataTypes.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
      },
      event_name: {
        type: DataTypes.STRING,
        allowNull: false,
        require: true,
      },
      event_description: {
        type: DataTypes.STRING,
      },
      event_venue: {
        type: DataTypes.STRING,
        allowNull: false,
        require: true,
      },
      total_seats: {
        type: DataTypes.INTEGER,
      },
      seats_left: {
        type: DataTypes.INTEGER,
      },
      event_date: {
        type: DataTypes.DATE,
        allowNull: false,
      },
      ticket_price: {
        type: DataTypes.FLOAT,
      },
      thumbnail: {
        type: DataTypes.STRING,
      },
    },
    {
      timestamps: true,
      createdAt: "event_created",
      updatedAt: "event_updated",
    }
  );
  return Event;
};
