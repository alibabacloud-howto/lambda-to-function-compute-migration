const Task = require('../model/Task');

/**
 * Sample service with some customer business logic.
 *
 * @author Alibaba Cloud
 */
class SampleService {

    /**
     * @param {TaskRepository} taskRepository
     */
    constructor(taskRepository) {
        this.taskRepository = taskRepository;
    }

    /**
     * Sample business logic.
     *
     * @returns {Promise<void>}
     */
    async doStuff() {
        console.log('Load existing tasks...');
        let tasks = await this.taskRepository.findAll();
        console.log(`Existing tasks: ${JSON.stringify(tasks)}`);

        console.log('Create tasks...');
        let task1 = new Task(this._generateUuid(), 'Buy new battery', new Date('2019-04-13T11:14:00.000Z'), 3);
        let task2 = new Task(this._generateUuid(), 'Bring laptop to repair', new Date('2019-04-13T11:15:00.000Z'), 1);
        await this.taskRepository.create(task1);
        await this.taskRepository.create(task2);

        console.log('Load tasks...');
        tasks = await this.taskRepository.findAll();
        console.log(`Tasks: ${JSON.stringify(tasks)}`);

        console.log('Update a task...');
        task1.description = 'Buy three batteries';
        task1.priority = 2;
        await this.taskRepository.update(task1);

        console.log('Load tasks...');
        tasks = await this.taskRepository.findAll();
        console.log(`Tasks: ${JSON.stringify(tasks)}`);

        console.log('Load first task...');
        const task = await this.taskRepository.findByUuid(task1.uuid);
        console.log(`First task: ${JSON.stringify(task)}`);

        console.log('Delete tasks...');
        await this.taskRepository.deleteByUuid(task1.uuid);
        await this.taskRepository.deleteByUuid(task2.uuid);

        console.log('Load tasks...');
        tasks = await this.taskRepository.findAll();
        console.log(`Tasks: ${JSON.stringify(tasks)}`);
    }

    /**
     * Generate a random-based UUID v4.
     * Thanks to https://stackoverflow.com/a/2117523
     *
     * @private
     * @returns {String}
     */
    _generateUuid() {
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => {
            const r = Math.random() * 16 | 0, v = c === 'x' ? r : (r & 0x3 | 0x8);
            return v.toString(16);
        });
    }
}

module.exports = SampleService;