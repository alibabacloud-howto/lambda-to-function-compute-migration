const Jimp = require('jimp');
const ThumbnailTransformationResult = require('../model/ThumbnailTransformationResult');

/**
 * Transform images into thumbnails.
 *
 * @author Alibaba Cloud
 */
class ThumbnailService {

    /**
     * @param {ObjectStorageDriver} objectStorageDriver
     * @param {MessagingDriver} messagingDriver
     */
    constructor(objectStorageDriver, messagingDriver) {
        /** @type {ObjectStorageDriver} */
        this.objectStorageDriver = objectStorageDriver;

        /** @type {MessagingDriver} */
        this.messagingDriver = messagingDriver;
    }

    /**
     * Load, transform and store images into thumbnails.
     *
     * @param {ObjectMetadata[]} remoteImages
     * @returns {Promise<ThumbnailTransformationResult>}
     */
    async transformImagesToThumbnails(remoteImages) {
        const keys = remoteImages.map(remoteImage => remoteImage.key);
        console.log(`Creating thumbnails for the files '${keys}'...`);

        // Prepare the results to be sent
        /** @type {Array.<{bucket: String, key: String}>} */
        const savedThumbnails = [];
        /** @type {Array.<{bucket: String, key: String, error: String}>} */
        const problematicImages = [];

        // Convert each image sequentially
        for (const remoteImage of remoteImages) {
            const bucket = remoteImage.bucket;
            const key = remoteImage.key;

            // Download the image
            console.log(`Download the image '${key}'...`);
            /** @type {Buffer} */ let imageBuffer;
            try {
                imageBuffer = await this.objectStorageDriver.getObject(bucket, key);
                console.log(`Image ${key} downloaded with success (size = ${imageBuffer.length}).`);
            } catch (error) {
                console.error(`Unable to download the image '${key}'.`, error);
                problematicImages.push({bucket: bucket, key: key, error: error.toString()});
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
                problematicImages.push({bucket: bucket, key: key, error: error.toString()});
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
                problematicImages.push({bucket: bucket, key: key, error: error.toString()});
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
                problematicImages.push({bucket: bucket, key: thumbnailKey, error: error.toString()});
                continue;
            }

            // Save the thumbnail to the bucket
            console.log(`Save the thumbnail '${thumbnailKey}' to the bucket...`);
            try {
                await this.objectStorageDriver.putObject(remoteImage.bucket, thumbnailKey, thumbnailBuffer);
                console.log(`Thumbnail '${thumbnailKey}' saved to the bucket with success.`);
            } catch (error) {
                console.error(`Unable to save the thumbnail '${thumbnailKey}' to the bucket.`, error);
                problematicImages.push({bucket: bucket, key: thumbnailKey, error: error.toString()});
                continue;
            }

            // Update the results
            savedThumbnails.push({bucket: bucket, key: thumbnailKey});
        }

        return new ThumbnailTransformationResult(savedThumbnails, problematicImages);
    }

    /**
     * Send a message with the results into the default queue.
     *
     * @param {ThumbnailTransformationResult} result
     * @returns {Promise<void>}
     */
    async sendTransformationResult(result) {
        console.log(`Send the result message into the default queue...`);
        try {
            await this.messagingDriver.sendMessage(JSON.stringify(result));
            console.log(`Result message sent with success!`);
        } catch (error) {
            console.error(`Unable send the result message into the default queue.`, error);
            callback(new Error(`Unable send the result message into the default queue.`));
        }
    }
}

module.exports = ThumbnailService;