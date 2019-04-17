/**
 * Driver responsible for reading and writing objects into an object storage service such as S3 or OSS.
 *
 * @interface
 * @author Alibaba Cloud
 */
class ObjectStorageDriver {

    /**
     * Parse the event object that has been passed to the handler function when an object has been uploaded to
     * a bucket.
     *
     * @param event
     * @returns {ObjectMetadata[]}
     */
    parseObjectCreatedEvent(event) {
        throw new Error('Not implemented.');
    }

    /**
     * Load an object from the storage service.
     *
     * @param {String} bucket
     * @param {String} key
     * @returns {Promise<Buffer>}
     */
    async getObject(bucket, key) {
        return Promise.reject(new Error('Not implemented.'));
    }

    /**
     * Save an object to the storage service.
     *
     * @param {String} bucket
     * @param {String} key
     * @param {Buffer} content
     * @returns {Promise<void>}
     */
    async putObject(bucket, key, content) {
        return Promise.reject(new Error('Not implemented.'));
    }

}

module.exports = ObjectStorageDriver;