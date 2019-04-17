/**
 * Entity corresponding to the TASK table.
 *
 * @author Alibaba Cloud
 */
class Task {

    /**
     * @param {String} uuid
     * @param {String} description
     * @param {Date} creationDate
     * @param {Number} priority
     */
    constructor(uuid, description, creationDate, priority) {
        /** @type {String} */
        this.uuid = uuid;

        /** @type {String} */
        this.description = description;

        /** @type {Date} */
        this.creationDate = creationDate;

        /** @type {Number} */
        this.priority = priority;
    }

}

module.exports = Task;