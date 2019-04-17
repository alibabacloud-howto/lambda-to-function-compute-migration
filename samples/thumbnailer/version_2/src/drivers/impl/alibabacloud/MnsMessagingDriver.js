const MNSClient = require('@alicloud/mns');
const MessagingDriver = require('../../MessagingDriver');

/**
 * Implementation of the {@link MessagingDriver} for AWS MNS.
 *
 * @implements {MessagingDriver}
 * @author Alibaba Cloud
 */
class MnsMessagingDriver extends MessagingDriver {

    /**
     * @param {{accountId: String, region: String, credentials: {accessKeyId: String, accessKeySecret: String, securityToken: String}}} context
     */
    constructor(context) {
        super();

        this.mnsClient = new MNSClient(context.accountId, {
            region: context.region,
            accessKeyId: context.credentials.accessKeyId,
            accessKeySecret: context.credentials.accessKeySecret,
            securityToken: context.credentials.securityToken
        });
        this.queueName = process.env.queueName;
    }

    async sendMessage(message) {
        try {
            await this.mnsClient.sendMessage(this.queueName, {MessageBody: message});
        } catch (error) {
            console.error(`Unable to send the message ${message}: ${JSON.stringify(error)}`, error);
            throw new Error(`Unable to send the message ${message}: ${JSON.stringify(error)}`);
        }
    }

}

module.exports = MnsMessagingDriver;