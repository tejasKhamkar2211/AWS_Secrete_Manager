<?php

require __DIR__ . '/vendor/autoload.php';

use Aws\SecretsManager\SecretsManagerClient;
use Aws\Exception\AwsException;

try {

    $client = new SecretsManagerClient([
        'version' => 'latest',
        'region'  => 'us-east-1'
    ]);

    $result = $client->getSecretValue([
        'SecretId' => 'facebook-prod-db'
    ]);

    $secret = json_decode($result['SecretString'], true);

    $conn = new mysqli(
        $secret['host'],
        $secret['username'],
        $secret['password'],
        $secret['dbname']
    );

    if ($conn->connect_error) {
        die("DB Connection failed: " . $conn->connect_error);
    }

} catch (AwsException $e) {
    die("AWS Error: " . $e->getMessage());
}
