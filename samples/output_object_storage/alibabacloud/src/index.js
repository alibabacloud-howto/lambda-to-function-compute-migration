const OSS = require('ali-oss').Wrapper;

exports.handler = async (event, context, callback) => {
    const ossClient = new OSS({
        region: 'oss-' + context.region,
        accessKeyId: context.credentials.accessKeyId,
        accessKeySecret: context.credentials.accessKeySecret,
        stsToken: context.credentials.securityToken,
        bucket: process.env.bucketName
    });

    // Read a file
    console.log('Read the test file...');
    let getObjectResponse;
    try {
        getObjectResponse = await ossClient.get('test.txt');
    } catch (error) {
        console.log('Unable to read the test file.', error);
        callback(error);
    }
    console.log(`Test file read with success (body = ${getObjectResponse.content.toString()})!`);

    // Write a file
    console.log('Write a new test file...');
    let putObjectResponse;
    try {
        putObjectResponse = await ossClient.put(`generated_${+new Date()}.txt`, new Buffer('Sample content.'));
    } catch (error) {
        console.log('Unable to write a test file.', error);
        callback(error);
    }
    console.log(`Test file written with success (putObject response = ${JSON.stringify(putObjectResponse)})!`);
    callback(null);
};
