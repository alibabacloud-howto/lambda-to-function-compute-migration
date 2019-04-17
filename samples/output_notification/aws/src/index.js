const AWS = require('aws-sdk');

exports.handler = function (event, context, callback) {
    const sqs = new AWS.SQS({apiVersion: '2012-11-05'});

    const params = {
        DelaySeconds: 10,
        MessageAttributes: {
            'sample-attribute': {
                DataType: 'String',
                StringValue: 'sample-value'
            }
        },
        MessageBody: 'Sample content',
        QueueUrl: process.env.queueUrl
    };

    console.log('Sending a message...');
    sqs.sendMessage(params, (err, data) => {
        if (err) {
            console.log('Unable to send the message.', err);
            callback(err);
        } else {
            console.log(`Message sent with success (${data.MessageId})!`);
            callback(null, data.MessageId);
        }
    });
};