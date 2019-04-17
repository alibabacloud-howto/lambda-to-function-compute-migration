exports.handler = function (event, context, callback) {
    console.log('Event: ' + JSON.stringify(event));
    callback(null, 'success');
};