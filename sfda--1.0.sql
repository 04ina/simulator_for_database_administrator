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
    numberExpectedRows int; 
    column_list1 TEXT;
    column_list2 TEXT;
BEGIN 
    EXECUTE 'SELECT solution FROM tasks WHERE name = $1' USING NameTask INTO QuerySolution; 
    RAISE NOTICE 'aboba %', QuerySolution;
    DROP TABLE IF EXISTS SolutionView;
    DROP TABLE IF EXISTS AnswerView;
    EXECUTE 'CREATE TABLE solutionview AS ' || QuerySolution;
    EXECUTE 'CREATE TABLE answerview AS ' || QueryAnswer;
 
    SELECT string_agg(column_name, ',') INTO column_list1
    FROM information_schema.columns
    WHERE table_name = 'solutionview'
    AND column_default IS NULL;
  
    SELECT string_agg(column_name, ',') INTO column_list2
    FROM information_schema.columns
    WHERE table_name = 'answerview'
    AND column_default IS NULL;

    IF NOT (column_list1 = column_list2) THEN 
        RAISE EXCEPTION 'Response contains different columns or a different column order';
        RETURN NULL;
    END IF;

    SELECT string_agg('a.' || column_name || ' = ' || 's.' || column_name, ' AND ' ) INTO EqualityCondition
    FROM information_schema.columns
    WHERE table_name = 'solutionview'
    AND column_default IS NULL;
    --RETURN EqualityCondition;

    -- Кол-во всех записей

    --SELECT COUNT(*) FROM SolutionView s WHERE EXISTS (SELECT * FROM AnswerView a WHERE a.aircraft_code=s.aircraft_code AND a.model=s.model AND a.range=s.range);
    
    --(SELECT count(*) FROM SolutionView) = SELECT COUNT(*) FROM 
    --Кол-во правильных записей
    QueryEqualityTest = 'SELECT COUNT(*) FROM SolutionView s WHERE EXISTS (SELECT * FROM AnswerView a WHERE ' || EqualityCondition || ')';
    --RAISE NOTICE 'test %', EqualityCondition;         
    --QueryEqualityTest = format('SELECT COUNT(*) FROM SolutionView s WHERE EXISTS (SELECT * FROM AnswerView a WHERE %I)',EqualityCondition);
    --RAISE NOTICE 'aaaa %', QueryEqualityTest;    
    EXECUTE QueryEqualityTest INTO NumberCorrectlyRows;

    EXECUTE 'SELECT COUNT(*) FROM solutionview;' INTO NumberExpectedRows;
    
    IF NOT (NumberExpectedRows = NumberCorrectlyRows) THEN
        RAISE EXCEPTION 'The answer is wrong';
        RETURN NULL;
    END IF;
    
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
RETURN NumberCorrectlyRows;
End;
$$ LANGUAGE plpgsql
