exports.handler = function (event, context, callback) {
    console.log('Function invoked at: ' + new Date());
    console.log('Event: ' + JSON.stringify(event));
    callback(null, 'success');
};