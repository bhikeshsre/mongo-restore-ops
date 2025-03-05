#!/bin/bash

# Author - Bhikesh Khute
# Date - 05 March 2025
# Version - 1.0

# Prompt user for file name
read -p "Enter the file name (with full path if not in the current directory): " FILE_PATH

read -p "Enter database name: " database
# Define remote server details
REMOTE_USER="ec2-user"
REMOTE_HOST="10.150.4.140"  # Change this to your target machine's IP or hostname
REMOTE_DIR="/home/ec2-user/"

# Copy file to remote server
scp "$FILE_PATH.bson" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR"

if [ $? -ne 0 ]; then
    echo "File copy failed. Exiting."
    exit 1
fi

echo "File copied successfully."

# Extract file name from the provided path
FILE_NAME=$(basename "$FILE_PATH")

# SSH into the remote server and execute MongoDB commands
ssh "$REMOTE_USER@$REMOTE_HOST" << EOF
    echo "Dropping collection if it exists..."
    DB_NAME=$database
    mongosh "mongodb://$database:$database@10.150.4.140:27017/$database?authMechanism=PLAIN&authSource=%24external&ssl=true&retryWrites=false&loadBalanced=true&tlsAllowInvalidCertificates=true" --eval 'db.getSiblingDB("$database").$FILE_PATH.drop()'

   echo "Restoring collection..."
   mongorestore --uri="mongodb://$database:$database@10.150.4.140:27017/$database?authMechanism=PLAIN&authSource=%24external&ssl=true&retryWrites=false&loadBalanced=true" --ssl --sslAllowInvalidCertificates --db $database --collection $FILE_PATH /home/ec2-user/$FILE_PATH.bson

EOF

echo "MongoDB Ops Completed successfully"
