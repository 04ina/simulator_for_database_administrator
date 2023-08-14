--\echo Use "CREATE EXTENSION TasksForDBA" to load this file. \quit


DO
$$
DECLARE
    student_exists BOOLEAN;
    teacher_exists BOOLEAN;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'student') THEN
        CREATE ROLE student LOGIN;    
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'teacher') THEN
        CREATE ROLE teacher LOGIN;    
    END IF;
END;
$$;


--\i /home/o4ina/postgres/TasksForDBA/demo-small-20170815.sql

--\c - teacher

CREATE TABLE tasks (
    name text,
    description text,
    solution text,
    RunTime time
);

CREATE FUNCTION AddTask(name text, description text, solution text, RunTime time)
RETURNS void AS $$
    INSERT INTO tasks VALUES (name,description,solution,RunTime);
$$ LANGUAGE SQL;

CREATE FUNCTION SendAnswer(NameTask text, QueryAnswer text)
RETURNS int
AS $$
DECLARE
    QueryViweSolution text;
    QueryViweAnswer text;
    QuerySolution text;
    EqualityCondition text;
    QueryEqualityTest text;
    ResultEqualityTest int; 
    NumberCorrectlyRows int;
BEGIN 
    EXECUTE 'SELECT solution FROM tasks WHERE name = $1' USING NameTask INTO QuerySolution; 
    RAISE NOTICE 'aboba %', QuerySolution;
    DROP TABLE IF EXISTS SolutionView;
    DROP TABLE IF EXISTS AnswerView;
    EXECUTE 'CREATE TABLE SolutionView AS ' || QuerySolution;
    EXECUTE 'CREATE TABLE AnswerView AS ' || QueryAnswer;
 
    SELECT string_agg('a.' || column_name || ' = ' || 's.' || column_name, ' AND ' ) INTO EqualityCondition
    FROM information_schema.columns
    WHERE table_name = 'SolutionView'
    AND column_default IS NULL;
    --RETURN EqualityCondition;

    -- Кол-во всех записей

    --SELECT COUNT(*) FROM SolutionView s WHERE EXISTS (SELECT * FROM AnswerView a WHERE a.aircraft_code=s.aircraft_code AND a.model=s.model AND a.range=s.range);
    
    --(SELECT count(*) FROM SolutionView) = SELECT COUNT(*) FROM 
    --Кол-во правильных записей
    QueryEqualityTest = 'SELECT COUNT(*) FROM SolutionView s WHERE EXISTS (SELECT * FROM AnswerView a WHERE )';
    RAISE NOTICE 'aaaa %', QueryEqualityTest;    
    EXECUTE QueryEqualityTest INTO NumberCorrectlyRows;
    /* 
    QueryEqualityTest = 
    '
        CREATE TABLE 
        SELECT COUNT(*)
        FROM SolutionView s 
        WHERE NOT EXISTS 
        (
            SELECT *
            FROM AnswerView a
            WHERE $1
        )
        UNION   
        SELECT COUNT(*)
        FROM AnswerView a 
        WHERE NOT EXISTS 
        (
            SELECT *
            FROM SolutionView s
            WHERE $1
        );
    ';
    */
    DROP TABLE solutionview;
    DROP TABLE answerview;

    RAISE NOTICE 'aaaa %', NumberCorrectlyRows;
RETURNS NumberCorrectlyRows;
End;
$$ LANGUAGE plpgsql
