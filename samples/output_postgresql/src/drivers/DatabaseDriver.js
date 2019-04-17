/**
 * Allow classes from the upper layers to execute queries in a SQL database.
 *
 * @interface
 * @author Alibaba Cloud
 */
class DatabaseDriver {

    /**
     * Open a connection to the database.
     *
     * Important: please call the close() method in order to close the connection.
     *
     * @param {String} host
     * @param {String} port
     * @param {String} database
     * @param {String} username
     * @param {String} password
     * @returns {Promise<void>}
     */
    async connect(host, port, database, username, password) {
        return Promise.reject(new Error('Not implemented.'));
    }

    /**
     * Close the current connection.
     *
     * @returns {Promise<void>}
     */
    async close() {
        return Promise.reject(new Error('Not implemented.'));
    }

    /**
     * Start a new transaction.
     *
     * @returns {Promise<void>}
     */
    async begin() {
        return Promise.reject(new Error('Not implemented.'));
    }

    /**
     * Commit the current transaction.
     *
     * @returns {Promise<void>}
     */
    async commit() {
        return Promise.reject(new Error('Not implemented.'));
    }

    /**
     * Rollback the current transaction.
     *
     * @returns {Promise<void>}
     */
    async rollback() {
        return Promise.reject(new Error('Not implemented.'));
    }

    /**
     * Execute a SQL query into the database.
     *
     * Note: this method can only be called after a connection is established and a transaction is started.
     *
     * @param {String} sql
     *     SQL statement (e.g. 'INSERT INTO users(name, email) VALUES($1, $2) RETURNING *')
     * @param {Array<Object>?} parameters
     *     Parameters to inject in the SQL statement (e.g. ['marc', 'marc.plouhinec@alibaba-inc.com']).
     * @returns {Promise<{rows: Array<String>, rowCount: Number}>}
     *     Query results.
     */
    async query(sql, parameters) {
        return Promise.reject(new Error('Not implemented.'));
    }
}

module.exports = DatabaseDriver;