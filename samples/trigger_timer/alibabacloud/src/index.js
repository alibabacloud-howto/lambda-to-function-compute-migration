exports.handler = function (event, context, callback) {
    console.log('Function invoked at: ' + new Date());
    console.log('Event: ' + event.toString());
    callback(null, 'success');
};