\echo Use "CREATE EXTENSION TasksForDBA" to load this file. \quit

CREATE ROLE student LOGIN;
CREATE ROLE teacher;
\i /home/o4ina/postgres/TasksForDBA/demo-small-20170815.sql

\c - teacher

CREATE TABLE tasks (
    name text,
    description text,
    solution text,
    RunTime time
)

CREATE FUNCTION AddTask(name text, description text, solution text, RunTime time DEFAULT 1)
AS $$
INSERT INTO tasks VALUES (name,description,solution,RunTime)
$$ LANGUAGE SQL

CREATE FUNCTION SendAnsver(NameTask integer, QueryAnswer text)
RETURNS text
AS $$
DECLARE
    QueryViweSolution text;
    QueryViweAnswer text;
    QuerySolution text;
BEGIN 
    EXECUTE 'SELECT solution FROM tasks WHERE name = $1' USING NameTask INTO QuerySolution; 
    EXECUTE 'CREATE VIEW SolutionView AS ' || QuerySolution;
    EXECUTE 'CREATE VIEW AnswerView AS ' || QueryAnswer;
 
    SELECT COUNT(*)
    FROM SolutionView 
    WHERE NOT EXISTS 
    (
        SELECT *
        FROM table2
        WHERE table1.column_name = table2.column_name
    )
    UNION ALL
    SELECT COUNT(*)
    FROM table2
    WHERE NOT EXISTS 
    (
        SELECT *
        FROM table1
        WHERE table2.column_name = table1.column_name
    );
End;
$$ LANGUAGE plpgsql
