<?php
require 'vendor/autoload.php';
 
 
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $name = $_POST["name"];
    $email = $_POST["email"];
    $message = $_POST["message"];

        // Insertar datos del formulario en la base de datos MySQL
        $mysqli = new mysqli(
            getenv('MYSQL_HOST'),
            getenv('MYSQL_USER'),
            getenv('MYSQL_PASSWORD'),
            getenv('MYSQL_DATABASE')
        );
 
        // Check connection
        if ($mysqli->connect_error) {
            die("Connection failed: " . $mysqli->connect_error);
        }
 
        // Prepare and bind
        $stmt = $mysqli->prepare("INSERT INTO form_data (name, email, message) VALUES (?, ?, ?)");
        $stmt->bind_param("sss", $name, $email, $message);
 
        // Execute query
        $stmt->execute();
 
        echo "Message sent successfully."; 
} else {
    http_response_code(405);
    echo "Method Not Allowed";
}
?> 

