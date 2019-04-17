const S3ObjectStorageDriver = require('./drivers/impl/aws/S3ObjectStorageDriver');
const SqsMessagingDriver = require('./drivers/impl/aws/SqsMessagingDriver');
const ThumbnailService = require('./services/ThumbnailService');

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
    // Initialize services / drivers and inject dependencies
    const objectStorageDriver = new S3ObjectStorageDriver();
    const messagingDriver = new SqsMessagingDriver();
    const thumbnailService = new ThumbnailService(objectStorageDriver, messagingDriver);

    // Transform the images and send a message with the results
    const remoteImages = objectStorageDriver.parseObjectCreatedEvent(event);
    const result = await thumbnailService.transformImagesToThumbnails(remoteImages);
    await thumbnailService.sendTransformationResult(result);

    // Return a response
    if (result.problematicImages.length > 0) {
        callback(new Error(`Error when processing images: ${JSON.stringify(result.problematicImages)}.`));
    } else {
        callback(null);
    }
};