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
    nescription text,
    solution text,
    exetime time,
    decided BOOLEAN
);

CREATE FUNCTION AddTask(name text, description text, solution text, exetime time)
RETURNS void AS $$
    INSERT INTO tasks VALUES (name,description,solution,exetime);
$$ LANGUAGE SQL;

CREATE FUNCTION SendAnswer(NameTask text, QueryAnswer text)
RETURNS text 
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
    SolColumns TEXT;
    AnsColumns TEXT;
    StartTime timestamp;
    EndTime timestamp;
    ExeTime interval;
    test TEXT; 
BEGIN 
    -- Creating tables with solution and answer
    StartTime := clock_timestamp(); 

    EXECUTE 'SELECT solution FROM tasks WHERE name = $1' USING NameTask INTO QuerySolution; 
    --EXECUTE 'SELECT exetime FROM tasks WHERE name = $1' USING NameTask INTO ExeTime; 
    EXECUTE 'CREATE TABLE solution AS ' || QuerySolution;
    EXECUTE 'CREATE TABLE answer AS ' || QueryAnswer;
 
    -- Creating strings with answer and solution columns
    SELECT string_agg(column_name, ',') INTO SolColumns
    FROM information_schema.columns
    WHERE table_name = 'solutionview'
    AND column_default IS NULL;

    SELECT string_agg(column_name, ',') INTO AnsColumns
    FROM information_schema.columns
    WHERE table_name = 'answerview'
    AND column_default IS NULL;

    IF NOT (SolColumns = AnsColumns) THEN 
        DROP TABLE solution;
        DROP TABLE answer;
        RETURN 'Response contains different columns or a different column order';
    END IF;

    -- Creating string with equality conditions
    SELECT string_agg('a.' || column_name || ' = ' || 's.' || column_name, ' AND ' ) INTO EqualityCondition
    FROM information_schema.columns
    WHERE table_name = 'solution'
    AND column_default IS NULL;

    -- Getting correct and expected rows
    QueryEqualityTest = 'SELECT COUNT(*) FROM Solution s WHERE EXISTS (SELECT * FROM Answer a WHERE ' || EqualityCondition || ')';
    EXECUTE QueryEqualityTest INTO NumberCorrectlyRows;
    EXECUTE 'SELECT COUNT(*) FROM solution;' INTO NumberExpectedRows;
   
    -- Checking for correct answer
    IF NOT (NumberExpectedRows = NumberCorrectlyRows) THEN
        DROP TABLE solution;
        DROP TABLE answer;
        RETURN 'The answer is wrong';
    END IF;

    DROP TABLE solution;
    DROP TABLE answer;

    EXECUTE QueryAnswer;

    EndTime := clock_timestamp(); 

    ExeTime := EndTime - StartTime;
    
    EXECUTE 'SELECT $1::timestamp - $2::timestamp' USING EndTime, StartTime INTO test;
    
    RAISE NOTICE 'aboab %', ExeTime; 
    RETURN 'Request takes too long ' || ExeTime;

    IF (EndTime-StartTime<=ExeTime) THEN
    END IF;


RETURN 'The problem is solved correctly';
End;
$$ LANGUAGE plpgsql
/*
CREATE FUNCTION delSolAnsTable()
RETURN void
PRIVATE
$$
START
    
END;
$$ LANGUAGE plpgsql;
*/





