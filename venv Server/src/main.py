from flask import Flask, json, request, jsonify, send_file
from flask_cors import CORS
import time
from multiprocessing import Process

# tebe3 serverur socket
import socket
import json


import requests


app = Flask(__name__)
CORS(app)

hostSocket1 = "0.0.0.0"  # Listen on all available network interfaces
portSocket1 = 65431

hostSocket2 = "0.0.0.0"  # Listen on all available network interfaces
portSocket2 = 65432


# Define the host and port of the server
senderId1 = 1
senderIp1 = "10.26.13.94"  # Replace with the server's IP address amine
senderPort1 = 65431

# Define the host and port of the server
senderId2 = 2
senderIp2 = "10.25.14.172"  # Replace with the server's IP address dali
senderPort2 = 65432
position_data = []

id_list = []


# Define a function to remove the earliest element from the list every 15 seconds
def remove_oldest_data():
    global position_data, id_list
    while True:
        position_data = []
        id_list = []
        # Write the updated list to the file
        with open("position_data.json", "w") as json_file1:
            json.dump(position_data, json_file1)
        with open("received_position_data1.json", "w") as json_file2:
            json.dump(position_data, json_file2)
        with open("received_position_data2.json", "w") as json_file3:
            json.dump(position_data, json_file3)

        print("Old data removed!")
        time.sleep(45)


def socket_send(host, port):
    while True:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server_socket:
            server_socket.bind((host, port))
            server_socket.listen()
            print("Server listening on", (host, port))
            conn, addr = server_socket.accept()
            print("Connected by", addr)

            with open("position_data.json", "r") as position_json:
                position = json.load(position_json)

            # Serialize the JSON data to send
            json_message = json.dumps(position)

            try:
                # Send the JSON message to the client
                conn.sendall(json_message.encode())
                print("Sending...........")
            except Exception as e:
                print("An error occurred:", str(e))

            finally:
                conn.close()

            time.sleep(10)


def socket_receive(id, host, port):
    while True:
        try:
            # Create a socket and connect to the server
            client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            client_socket.settimeout(5)  # Set a timeout for the connection

            while True:
                try:
                    client_socket.connect((host, port))
                    break
                except (ConnectionRefusedError, TimeoutError):
                    print("Server is not available. Retrying in 5 seconds...")
                    time.sleep(5)

            # Receive the server's JSON message
            json_message = ""
            while True:
                chunk = client_socket.recv(1024).decode()
                if not chunk:
                    break  # No more data received
                json_message += chunk

            # Deserialize the JSON message
            try:
                json_data = json.loads(json_message)
                print("=====================")
                print("Received JSON message from the server:", json_data)
                print("=====================")

                # Write the updated list to the file
                file_name = f"received_position_data{str(id)}.json"
                with open(file_name, "w") as json_file:
                    json.dump(json_data, json_file)
            except json.JSONDecodeError as e:
                print("Error decoding JSON message:", str(e))
        except KeyboardInterrupt:
            print("Client interrupted. Exiting...")
            break
        except Exception as e:
            print("An error occurred:", str(e))
        finally:
            client_socket.close()
        time.sleep(10)


# flutter request
@app.route("/position", methods=["POST"])
def receive_position():
    global position_data

    # Get the JSON data from the request
    data = request.get_json()

    # Add a timestamp to the data
    data["timestamp"] = time.time()
    id_list.append(id)

    # Append the updated data to the list
    position_data.append(data)
    print("===========================")
    print("position data list: ", data)
    print("===========================")

    # Read the existing data from the file
    with open("position_data.json", "r") as json_file:
        existing_data = json.load(json_file)

    # Append the new data to the existing data
    existing_data.append(data)

    # Write the updated data to the file
    with open("position_data.json", "w") as json_file1:
        json.dump(existing_data, json_file1)

    with open("received_position_data1.json", "r") as json_file2:
        existing_data2 = json.load(json_file2)

    with open("received_position_data2.json", "r") as json_file3:
        existing_data3 = json.load(json_file3)

    return jsonify(existing_data + existing_data2 + existing_data3), 200


if __name__ == "__main__":
    # Create processes for each function
    socket_receive_process1 = Process(
        target=socket_receive, args=(senderId1, senderIp1, senderPort1)
    )
    socket_receive_process2 = Process(
        target=socket_receive, args=(senderId2, senderIp2, senderPort2)
    )
    socket_send_process1 = Process(target=socket_send, args=(hostSocket1, portSocket1))
    socket_send_process2 = Process(target=socket_send, args=(hostSocket2, portSocket2))
    remove_process = Process(target=remove_oldest_data)

    # Start the processes
    socket_receive_process1.start()
    socket_receive_process2.start()
    socket_send_process1.start()
    socket_send_process2.start()
    remove_process.start()

    # Start the Flask app in the main thread
    app.run(host=hostSocket1, port=5000)

    # Wait for the processes to finish
    socket_receive_process1.join()
    socket_receive_process2.join()
    socket_send_process1.join()
    socket_send_process2.join()
    remove_process.join()
