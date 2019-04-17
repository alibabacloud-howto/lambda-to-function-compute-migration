const TaskRepository = require('../TaskRepository');
const Task = require('../../model/Task');

/**
 * Default implementation of {@link TaskRepository}.
 *
 * @implements TaskRepository
 * @author Alibaba Cloud
 */
class TaskRepositoryImpl extends TaskRepository {

    /**
     * @param {DatabaseDriver} databaseDriver
     */
    constructor(databaseDriver) {
        super();

        /** @type {DatabaseDriver} */
        this.databaseDriver = databaseDriver;
    }

    async findAll() {
        const results = await this.databaseDriver.query(
            'SELECT uuid, description, creationdate, priority FROM task');

        if (results.rowCount === 0) {
            return [];
        }

        return this._convertRowsToTasks(results.rows);
    }

    async findByUuid(uuid) {
        const results = await this.databaseDriver.query(
            'SELECT uuid, description, creationdate, priority FROM task WHERE UUID = $1', [uuid]);

        if (results.rowCount === 0) {
            return null;
        }

        const tasks = this._convertRowsToTasks(results.rows);
        return tasks[0];
    }

    async create(task) {
        await this.databaseDriver.query(
            'INSERT INTO task(uuid, description, creationdate, priority) VALUES($1, $2, $3, $4)',
            [task.uuid, task.description, task.creationDate, task.priority]);
    }

    async update(task) {
        await this.databaseDriver.query(
            'UPDATE task SET description = $2, creationdate = $3, priority = $4 WHERE uuid = $1',
            [task.uuid, task.description, task.creationDate, task.priority]);
    }

    async deleteByUuid(uuid) {
        await this.databaseDriver.query('DELETE FROM task WHERE UUID = $1', [uuid]);
    }

    /**
     * @param {Array<Object>} rows
     * @return {Array<Task>}
     * @private
     */
    _convertRowsToTasks(rows) {
        return rows.map(row => new Task(row['uuid'], row['description'], row['creationdate'], row['priority']));
    }
}

module.exports = TaskRepositoryImpl;