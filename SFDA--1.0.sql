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
    EqualityCondition text;
    QueryEqualityTest text;
    ResultEqualityTest int; 
BEGIN 
    EXECUTE 'SELECT solution FROM tasks WHERE name = $1' USING NameTask INTO QuerySolution; 
    EXECUTE 'CREATE TABLE SolutionView AS ' || QuerySolution;
    EXECUTE 'CREATE TABLE AnswerView AS ' || QueryAnswer;
 
    SELECT string_agg('a.' || column_name || ' = ' || 's.' || column_name, ' AND ' ) INTO EqualityCondition
    FROM information_schema.columns
    WHERE table_name = tablee
    AND column_default IS NULL;
    RETURN EqualityCondition;

    EqualityTest = 
    '
        SELECT COUNT(*)
        FROM SolutionView s 
        WHERE NOT EXISTS 
        (
            SELECT *
            FROM AnswerView a
            WHERE $1
        )
        UNION ALL
        SELECT COUNT(*)
        FROM AnswerView a 
        WHERE NOT EXISTS 
        (
            SELECT *
            FROM SolutionView s
            WHERE $1
        );
    ';
    EXECUTE QueryEqualityTest USING EqualityCondition;
End;
$$ LANGUAGE plpgsql
