<?php

require_once 'db.php'; // 👈 AWS Secrets Manager DB connection

if ($_SERVER["REQUEST_METHOD"] == "POST") {

    $name = htmlspecialchars($_POST["name"]);
    $email = htmlspecialchars($_POST["email"]);
    $message = htmlspecialchars($_POST["message"]);

    $stmt = $conn->prepare(
        "INSERT INTO contacts (name, email, message) VALUES (?, ?, ?)"
    );

    $stmt->bind_param("sss", $name, $email, $message);

    if ($stmt->execute()) {
        echo "<h2>Thank you, $name!</h2>";
        echo "<p>Your message has been received and saved.</p>";
    } else {
        echo "Error: " . $stmt->error;
    }

    $stmt->close();
}

$conn->close();

?>
