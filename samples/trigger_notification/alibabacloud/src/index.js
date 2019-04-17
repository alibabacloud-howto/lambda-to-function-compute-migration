exports.handler = function (event, context, callback) {
    const mnsEvent = JSON.parse(event);
    console.log('Event: ' + JSON.stringify(mnsEvent));
    callback(null, 'success');
};