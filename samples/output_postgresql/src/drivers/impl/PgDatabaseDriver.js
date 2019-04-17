const {Client} = require('pg');
const DatabaseDriver = require('../DatabaseDriver');

/**
 * Implementation of {@link DatabaseDriver} for PostgreSQL.
 *
 * @implements DatabaseDriver
 * @author Alibaba Cloud
 */
class PgDatabaseDriver extends DatabaseDriver {

    constructor() {
        super();

        this.client = null;
    }

    async connect(host, port, database, username, password) {
        this.client = new Client({
            user: username,
            host: host,
            database: database,
            password: password,
            port: port,
        });

        await this.client.connect();
    }

    async close() {
        await this.client.end();
    }

    async begin() {
        await this.client.query('BEGIN');
    }

    async commit() {
        await this.client.query('COMMIT');
    }

    async rollback() {
        await this.client.query('ROLLBACK');
    }

    async query(sql, parameters) {
        return await this.client.query(sql, parameters);
    }
}

module.exports = PgDatabaseDriver;