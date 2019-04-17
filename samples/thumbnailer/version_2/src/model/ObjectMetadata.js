/**
 * Metadata of an object stored on a object storage service.
 *
 * @author Alibaba Cloud
 */
class ObjectMetadata {

    /**
     * @param {String} bucket
     * @param {String} key
     */
    constructor(bucket, key) {
        /** @type {String} */
        this.bucket = bucket;

        /** @type {String} */
        this.key = key;
    }

}

module.exports = ObjectMetadata;