#!/bin/bash

# Connection to database
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

MAIN_FUNCTION() {
  # Input username
  echo "Enter your username:"
  read USERNAME

  # Validate username
  while [[ ! $USERNAME =~ ^[a-zA-Z][a-zA-Z0-9_]{0,21}$ ]]; do
    echo -e "\nEnter a valid username:"
    read USERNAME
  done

  # Check if username exists
  QUERY=$($PSQL "SELECT games_played, best_game FROM users WHERE username = '$USERNAME'")

  if [[ -z $QUERY ]]; then
    # If not exists, save it
    INSERT_USERNAME_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
    
    # Make sure first play is the best score
    BEST_GAME=9999
    
    echo "Welcome, $USERNAME! It looks like this is your first time here."
  else
    # If exists, retrieve data
    read GAMES_PLAYED BEST_GAME <<< "$(sed 's/|/ /g' <<< "$QUERY" )"

    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  fi

  START_GAME
  
  UPDATE_DATABASE
}

START_GAME() {
  # Generate secret number
  SECRET_NUMBER=$((RANDOM % 1000 + 1))

  # Start guesses counter
  NUMBER_OF_GUESSES=0
  
  echo "Guess the secret number between 1 and 1000:"

  while true; do
    read NUMBER_INPUT
    
    if [[ ! $NUMBER_INPUT =~ ^[0-9]+$ ]]; then
      echo 'That is not an integer, guess again:'
    elif [[ $NUMBER_INPUT -gt $SECRET_NUMBER ]]; then
      echo "It's lower than that, guess again:"
      (( NUMBER_OF_GUESSES++ ))
    elif [[ $NUMBER_INPUT -lt $SECRET_NUMBER ]]; then
      echo "It's higher than that, guess again:"
      (( NUMBER_OF_GUESSES++ ))
    elif [[ $NUMBER_INPUT -eq $SECRET_NUMBER ]]; then
      (( NUMBER_OF_GUESSES++ ))
      break    
    fi

  done
  
  echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
}

UPDATE_DATABASE() {
  # Increment games played counter
  NEW_GAMES_PLAYED=$(($GAMES_PLAYED + 1))

  # Check if new high score
  if [[ $NUMBER_OF_GUESSES -lt $BEST_GAME ]]; then
    # Update database
    INSERT_FINAL_RESULT="$($PSQL "UPDATE users SET games_played = $NEW_GAMES_PLAYED, best_game = $NUMBER_OF_GUESSES WHERE username = '$USERNAME'")"
  else
    INSERT_FINAL_RESULT="$($PSQL "UPDATE users SET games_played = $NEW_GAMES_PLAYED WHERE username = '$USERNAME'")"
  fi
}

MAIN_FUNCTION
