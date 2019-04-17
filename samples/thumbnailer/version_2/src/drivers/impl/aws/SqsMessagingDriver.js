const AWS = require('aws-sdk');
const MessagingDriver = require('../../MessagingDriver');

/**
 * Implementation of the {@link MessagingDriver} for AWS SQS.
 *
 * @implements {MessagingDriver}
 * @author Alibaba Cloud
 */
class SqsMessagingDriver extends MessagingDriver {

    constructor() {
        super();

        this.sqs = new AWS.SQS();
        this.queueUrl = process.env.queueUrl;
    }

    async sendMessage(message) {
        try {
            await this.sqs.sendMessage({DelaySeconds: 10, MessageBody: message, QueueUrl: this.queueUrl}).promise();
        } catch (error) {
            console.error(`Unable to send the message ${message}: ${JSON.stringify(error)}`, error);
            throw new Error(`Unable to send the message ${message}: ${JSON.stringify(error)}`);
        }
    }

}

module.exports = SqsMessagingDriver;