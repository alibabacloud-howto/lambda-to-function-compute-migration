const AWS = require('aws-sdk');
const Jimp = require('jimp');

/**
 * Create a thumbnail when an image is uploaded to a S3 bucket.
 *
 * The input image must be uploaded into the "/images" folder.
 * The result is saved into the "/thumbnails" folder.
 * After the operation, a message is sent to a SQS queue to notify about the result.
 *
 * Note: this implementation is only compatible with AWS.
 *
 * @param {{Records: Array.<{s3: {bucket: {name: String, arn: String}, object: {key: String}}}>}} event
 * @param context
 * @param {function(error: Error?, result: Object?)} callback
 * @author Alibaba Cloud
 */
exports.handler = async (event, context, callback) => {
    const keys = event.Records.map(record => record.s3.object.key);
    console.log(`Creating thumbnails for the files '${keys}'...`);

    // Initialize the clients
    const s3 = new AWS.S3();
    const sqs = new AWS.SQS();

    // Prepare the results to be sent
    /** @type {Array.<{bucket: String, key: String}>} */
    const savedThumbnails = [];
    /** @type {Array.<{bucket: String, key: String, error: String}>} */
    const problematicImages = [];

    // Convert each image sequentially
    for (const record of event.Records) {
        const bucketName = record.s3.bucket.name;
        const key = record.s3.object.key;

        // Download the image
        console.log(`Download the image '${key}'...`);
        /** @type {Buffer} */ let imageBuffer;
        try {
            /** @type {{ContentLength: Number, Body: Buffer}} */
            const response = await s3.getObject({Bucket: bucketName, Key: key}).promise();
            console.log(`Image ${key} downloaded with success (size = ${response.ContentLength}).`);
            imageBuffer = response.Body
        } catch (error) {
            console.error(`Unable to download the image '${key}'.`, error);
            problematicImages.push({bucket: bucketName, key: key, error: error.toString()});
            continue;
        }

        // Read the image
        console.log(`Read the image '${key}'...`);
        /** @type {Jimp} */ let imageJimp;
        try {
            imageJimp = await Jimp.read(imageBuffer);
            console.log(`Image ${key} read with success (width = ${imageJimp.getWidth()}, height = ${imageJimp.getHeight()}).`);
        } catch (error) {
            console.error(`Unable to read the image '${key}'.`, error);
            problematicImages.push({bucket: bucketName, key: key, error: error.toString()});
            continue;
        }

        // Resize the image
        console.log(`Resize the image '${key}'...`);
        const thumbnailKey = 'thumbnails/' + key.substring(key.indexOf('/') + 1);
        try {
            imageJimp = await imageJimp.cover(200, 200);
            console.log(`Image ${thumbnailKey} resized with success (width = ${imageJimp.getWidth()}, height = ${imageJimp.getHeight()}).`);
        } catch (error) {
            console.error(`Unable to resized the image '${thumbnailKey}'.`, error);
            problematicImages.push({bucket: bucketName, key: key, error: error.toString()});
            continue;
        }

        // Write the thumbnail to a buffer
        console.log(`Write the thumbnail '${thumbnailKey}' to a buffer...`);
        /** @type {Buffer} */ let thumbnailBuffer;
        try {
            thumbnailBuffer = await imageJimp.getBufferAsync(imageJimp.getMIME());
            console.log(`Thumbnail ${thumbnailKey} written with success (size = ${thumbnailBuffer.length}}).`);
        } catch (error) {
            console.error(`Unable to write the thumbnail '${thumbnailKey}'.`, error);
            problematicImages.push({bucket: bucketName, key: key, error: error.toString()});
            continue;
        }

        // Save the thumbnail to the bucket
        console.log(`Save the thumbnail '${key}' to the bucket...`);
        try {
            const response = await s3.putObject({
                Body: thumbnailBuffer,
                Bucket: bucketName,
                Key: thumbnailKey
            }).promise();
            console.error(`Thumbnail '${thumbnailKey}' saved to the bucket with success (response = ${JSON.stringify(response)}).`);
        } catch (error) {
            console.error(`Unable to save the thumbnail '${thumbnailKey}' to the bucket.`, error);
            problematicImages.push({bucket: bucketName, key: key, error: error.toString()});
            continue;
        }

        // Update the results
        savedThumbnails.push({bucket: bucketName, key: thumbnailKey});
    }

    // Send a message to the queue with the result (in case of success or error)
    const queueUrl = process.env.queueUrl;
    console.log(`Send the result message into the queue '${queueUrl}'...`);
    try {
        const response = await sqs.sendMessage({
            DelaySeconds: 10,
            MessageBody: JSON.stringify({savedThumbnails: savedThumbnails, problematicImages: problematicImages}),
            QueueUrl: queueUrl
        }).promise();
        console.log(`Result message sent with success (response = ${JSON.stringify(response)})!`);
    } catch (error) {
        console.error(`Unable send the result message into the queue '${queueUrl}'.`, error);
        callback(new Error(`Unable send the result message into the queue '${queueUrl}'.`));
    }

    if (problematicImages.length > 0) {
        callback(new Error(`Error when processing images: ${JSON.stringify(problematicImages)}.`));
    } else {
        callback(null);
    }
};