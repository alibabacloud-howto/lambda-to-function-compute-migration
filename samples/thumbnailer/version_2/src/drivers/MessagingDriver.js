/**
 * Driver responsible for sending messages into a queue.
 *
 * @interface
 * @author Alibaba Cloud
 */
class MessagingDriver {

    /**
     * Send a message into the default queue.
     *
     * @param {String} message
     * @returns {Promise<void>}
     */
    async sendMessage(message) {
        return Promise.reject(new Error('Not implemented.'));
    }

}

module.exports = MessagingDriver;