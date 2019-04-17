/**
 * Data access object for the {@link Task} entity.
 *
 * @interface
 * @author Alibaba Cloud
 */
class TaskRepository {

    /**
     * Find all tasks.
     *
     * @returns {Promise<Array<Task>>}
     */
    async findAll() {
        return Promise.reject(new Error('Not implemented.'));
    }

    /**
     * Find a task by its UUID.
     *
     * @param {String} uuid
     * @returns {Promise<Task?>}
     */
    async findByUuid(uuid) {
        return Promise.reject(new Error('Not implemented.'));
    }

    /**
     * Create the given task.
     *
     * @param {Task} task
     * @returns {Promise<Task>}
     */
    async create(task) {
        return Promise.reject(new Error('Not implemented.'));
    }

    /**
     * Update the given task.
     *
     * @param {Task} task
     * @returns {Promise<Task>}
     */
    async update(task) {
        return Promise.reject(new Error('Not implemented.'));
    }

    /**
     * Delete the task with the given UUID.
     *
     * @param {String} uuid
     * @returns {Promise<Task>}
     */
    async deleteByUuid(uuid) {
        return Promise.reject(new Error('Not implemented.'));
    }
}

module.exports = TaskRepository;