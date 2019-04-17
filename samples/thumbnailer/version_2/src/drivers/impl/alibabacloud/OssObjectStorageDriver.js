const OSS = require('ali-oss').Wrapper;
const ObjectStorageDriver = require('../../ObjectStorageDriver');
const ObjectMetadata = require('../../../model/ObjectMetadata');

/**
 * Implementation of the {@link ObjectStorageDriver} for Alibaba Cloud OSS.
 *
 * @implements {ObjectStorageDriver}
 * @author Alibaba Cloud
 */
class OssObjectStorageDriver extends ObjectStorageDriver {

    /**
     * @param {{region: String, credentials: {accessKeyId: String, accessKeySecret: String, securityToken: String}}} context
     */
    constructor(context) {
        super();

        this.ossClient = new OSS({
            region: 'oss-' + context.region,
            accessKeyId: context.credentials.accessKeyId,
            accessKeySecret: context.credentials.accessKeySecret,
            stsToken: context.credentials.securityToken
        });
    }

    /**
     * @override
     * @param {Buffer} event
     * @returns {ObjectMetadata[]}
     */
    parseObjectCreatedEvent(event) {
        /** @type {{events: Array.<{oss: {bucket: {name: String, arn: String}, object: {key: String}}}>}} */
        const ossEvent = JSON.parse(event);
        return ossEvent.events.map(event => new ObjectMetadata(event.oss.bucket.name, event.oss.object.key));
    }

    async getObject(bucket, key) {
        this.ossClient.useBucket(bucket);

        try {
            const response = await this.ossClient.get(key);
            return response.content;
        } catch (error) {
            console.error(`Unable to get the object ${bucket}/${key}: ${JSON.stringify(error)}`, error);
            throw new Error(`Unable to get the object ${bucket}/${key}.`);
        }
    }

    async putObject(bucket, key, content) {
        this.ossClient.useBucket(bucket);

        try {
            await this.ossClient.put(key, content);
        } catch (error) {
            console.error(`Unable to save the object ${bucket}/${key}: ${JSON.stringify(error)}`, error);
            throw new Error(`Unable to save the object ${bucket}/${key}.`);
        }
    }

}

module.exports = OssObjectStorageDriver;