const PgDatabaseDriver = require('./drivers/impl/PgDatabaseDriver');
const TaskRepositoryImpl = require('./repositories/impl/TaskRepositoryImpl');
const SampleService = require('./services/SampleService');

/**
 * Example about how to access to PostgreSQL database from AWS lambda and Alibaba Cloud Function Compute.
 *
 * @param event
 * @param context
 * @param {function(error: Error?, result: Object?)} callback
 *
 * @author Alibaba Cloud
 */
exports.handler = async (event, context, callback) => {
    // Initialize services / drivers and inject dependencies
    const databaseDriver = new PgDatabaseDriver();
    const taskRepository = new TaskRepositoryImpl(databaseDriver);
    const sampleService = new SampleService(taskRepository);

    // Run the service within a database connection
    try {
        await databaseDriver.connect(
            process.env.host,
            process.env.port,
            process.env.database,
            process.env.username,
            process.env.password);

        // Run the service within a database transaction
        try {
            await databaseDriver.begin();

            await sampleService.doStuff();

            await databaseDriver.commit();
        } catch (error) {
            await databaseDriver.rollback();
            throw error;
        }
    } finally {
        await databaseDriver.close();
    }


    callback(null, 'success');
};