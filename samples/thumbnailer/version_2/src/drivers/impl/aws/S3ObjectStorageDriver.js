const AWS = require('aws-sdk');
const ObjectStorageDriver = require('../../ObjectStorageDriver');
const ObjectMetadata = require('../../../model/ObjectMetadata');

/**
 * Implementation of the {@link ObjectStorageDriver} for AWS S3.
 *
 * @implements {ObjectStorageDriver}
 * @author Alibaba Cloud
 */
class S3ObjectStorageDriver extends ObjectStorageDriver {

    constructor() {
        super();

        this.s3 = new AWS.S3();
    }

    /**
     * @override
     * @param {{Records: Array.<{s3: {bucket: {name: String, arn: String}, object: {key: String}}}>}} event
     * @returns {ObjectMetadata[]}
     */
    parseObjectCreatedEvent(event) {
        return event.Records.map(record => new ObjectMetadata(record.s3.bucket.name, record.s3.object.key));
    }

    async getObject(bucket, key) {
        try {
            const response = await this.s3.getObject({Bucket: bucket, Key: key}).promise();
            return response.Body;
        } catch (error) {
            console.error(`Unable to get the object ${bucket}/${key}: ${JSON.stringify(error)}`, error);
            throw new Error(`Unable to get the object ${bucket}/${key}.`);
        }
    }

    async putObject(bucket, key, content) {
        try {
            await this.s3.putObject({Body: content, Bucket: bucket, Key: key}).promise();
        } catch (error) {
            console.error(`Unable to save the object ${bucket}/${key}: ${JSON.stringify(error)}`, error);
            throw new Error(`Unable to save the object ${bucket}/${key}.`);
        }
    }

}

module.exports = S3ObjectStorageDriver;