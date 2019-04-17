exports.handler = function (event, context, callback) {
    const ossEvent = JSON.parse(event);
    console.log('Event: ' + JSON.stringify(ossEvent));
    callback(null, 'success');
};