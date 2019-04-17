exports.handler = function (event, context, callback) {
    console.log('hello world');
    console.log(process.version);
    callback(null, 'hello world');
};