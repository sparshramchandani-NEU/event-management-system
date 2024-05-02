import { Sequelize } from "sequelize";

export default (sequelize, DataTypes) => {
  const eventTransactions = sequelize.define(
    "event_transactions",
    {
      transaction_id: {
        type: DataTypes.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
      },
      number_of_tickets: {
        type: DataTypes.INTEGER,
        allowNull: false,
      },
      total_price: {
        type: DataTypes.FLOAT,
        allowNull: false,
      },
      event_name: {
        type: DataTypes.STRING,
        allowNull: false,
      }
    },
    {
      timestamps: true,
      createdAt: "transaction_created",
      updatedAt: "transaction_updated",
    }
  );
  return eventTransactions;
};
