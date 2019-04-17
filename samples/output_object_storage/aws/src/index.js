const AWS = require('aws-sdk');

exports.handler = async (event, context, callback) => {
    const s3 = new AWS.S3();

    // Read a file
    console.log('Read the test file...');
    let getObjectResponse;
    try {
        getObjectResponse = await s3.getObject({
            Bucket: process.env.bucketName,
            Key: 'test.txt'
        }).promise();
    } catch (error) {
        console.log('Unable to read the test file.', error);
        callback(error);
    }
    console.log(`Test file read with success (body = ${getObjectResponse.Body.toString()})!`);

    // Write a file
    console.log('Write a new test file...');
    let putObjectResponse;
    try {
        putObjectResponse = await s3.putObject({
            Body: Buffer.from('Sample content.', 'utf8'),
            Bucket: process.env.bucketName,
            Key: `generated_${+new Date()}.txt`
        }).promise();
    } catch (error) {
        console.log('Unable to write a test file.', error);
        callback(error);
    }
    console.log(`Test file written with success (putObject response = ${JSON.stringify(putObjectResponse)})!`);
    callback(null);
};
