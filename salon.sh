#!/bin/bash

PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

echo -e "\n~~~~~ MY SALON ~~~~~\n"

echo -e "Welcome to My Salon, how can I help you?\n"

SERVICES=$($PSQL "SELECT service_id, name FROM services")

SELECT_SERVICE() {
  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi

  echo "$SERVICES" | while read SERVICE_ID BAR NAME 
    do
      echo -e "$SERVICE_ID) $NAME"
    done
  
  read SERVICE_ID_SELECTED

  #if selection is not a number
  if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
    then
      # reprompt user
      SELECT_SERVICE "I could not find that service. What would you like today?"
    else
      IFS='|' read -r SELECTION_ID SERVICE_NAME <<< "$(awk "NR==$SERVICE_ID_SELECTED" <<< "$SERVICES")"
      #if selection is not valid
      if [[ -z $SELECTION_ID ]]
      then 
        #reprompt user again
        SELECT_SERVICE "I could not find that service. What would you like today?"
      else
        #get customer info
        echo -e "\nWhat's your phone number?"
        read CUSTOMER_PHONE

        CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")

         # if customer doesn't exist
        if [[ -z $CUSTOMER_NAME ]]
        then
          # get new customer name
          echo -e "\nI don't have a record for that phone number, what's your name?"
          read CUSTOMER_NAME

          CUSTOMER_NAME=$(echo "$CUSTOMER_NAME" | tr -d "'")
          CUSTOMER_PHONE=$(echo "$CUSTOMER_PHONE" | tr -d "'")
          

          # insert new customer
          $PSQL "INSERT INTO customers(phone, name) VALUES('$CUSTOMER_PHONE', '$CUSTOMER_NAME')"
        fi

        echo -e "\nWhat time would you like your cut, $CUSTOMER_NAME?"
        read SERVICE_TIME;
        SERVICE_TIME=$(echo "$SERVICE_TIME" | tr -d "'")

        #get customer id
        CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")

        #insert appointment slot 
        $PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SELECTION_ID, '$SERVICE_TIME')"

        echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
      fi 
  fi
  
}

SELECT_SERVICE
