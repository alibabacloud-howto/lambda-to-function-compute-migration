const MNSClient = require('@alicloud/mns');

exports.handler = async function (event, context, callback) {
    const mnsClient = new MNSClient(context.accountId, {
        region: context.region,
        accessKeyId: context.credentials.accessKeyId,
        accessKeySecret: context.credentials.accessKeySecret,
        securityToken: context.credentials.securityToken
    });

    console.log('Sending a sample message to a topic...');
    try {
        const result = await mnsClient.publishMessage(process.env.topicName, {MessageBody: 'sample-content'});
        console.log(`Message sent to the topic with success! (result = ${JSON.stringify(result)})`);
    } catch (error) {
        console.log('Unable to send the message to the topic.', error);
        callback(error);
    }

    console.log('Sending a sample message to a queue...');
    try {
        const result = await mnsClient.sendMessage(process.env.queueName, {MessageBody: 'sample-content'});
        console.log(`Message sent to the queue with success! (result = ${JSON.stringify(result)})`);
    } catch (error) {
        console.log('Unable to send the message to the queue.', error);
        callback(error);
    }

    callback(null);
};