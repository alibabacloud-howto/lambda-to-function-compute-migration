CREATE TABLE task
(
    uuid         UUID PRIMARY KEY,
    description  VARCHAR(256) NOT NULL,
    creationdate TIMESTAMP    NOT NULL,
    priority     SMALLINT
);