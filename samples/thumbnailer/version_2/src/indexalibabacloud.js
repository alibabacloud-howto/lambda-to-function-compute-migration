const OssObjectStorageDriver = require('./drivers/impl/alibabacloud/OssObjectStorageDriver');
const MnsMessagingDriver = require('./drivers/impl/alibabacloud/MnsMessagingDriver');
const ThumbnailService = require('./services/ThumbnailService');

/**
 * Create a thumbnail when an image is uploaded to an OSS bucket.
 *
 * The input image must be uploaded into the "/images" folder.
 * The result is saved into the "/thumbnails" folder.
 * After the operation, a message is sent to a MNS queue to notify about the result.
 *
 * Note: this implementation is only compatible with Alibaba Cloud.
 *
 * @param {Buffer} event
 * @param context
 * @param {function(error: Error?, result: Object?)} callback
 * @author Alibaba Cloud
 */
exports.handler = async (event, context, callback) => {
    // Initialize services / drivers and inject dependencies
    const objectStorageDriver = new OssObjectStorageDriver(context);
    const messagingDriver = new MnsMessagingDriver(context);
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