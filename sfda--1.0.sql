--\echo Use "CREATE EXTENSION jasksForDBA" to load this file. \quit

DO
$$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'sfda_student') THEN
        CREATE ROLE sfda_student LOGIN;    
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'sfda_teacher') THEN
        CREATE ROLE sfda_teacher LOGIN;    
    END IF;
END;
$$;

CREATE FUNCTION AddSchema(schema text)
RETURNS void AS $$
BEGIN
    EXECUTE 'GRANT USAGE ON SCHEMA ' || schema || ' TO sfda_student'; 
    EXECUTE 'GRANT USAGE ON SCHEMA ' || schema || ' TO sfda_teacher'; 

    EXECUTE 'GRANT SELECT ON ALL tABLES IN SCHEMA  ' || schema || ' TO sfda_student';
    EXECUTE 'GRANT SELECT ON ALL tABLES IN SCHEMA ' || schema || ' TO sfda_teacher';
END;
$$ LANGUAGE plpgsql;

CREATE TABLE tasks (
    name text,
    description text,
    solution text,
    execute_time interval,
    decided BOOLEAN
);

CREATE VIEW students_tasks
AS SELECT name, description, execute_time, decided
FROM tasks;

CREATE FUNCTION AddTask(name text, description text, solution text, maxexetime interval DEFAULT '2 sec')
RETURNS void AS $$
    INSERT INTO tasks VALUES (name,description,solution,maxexetime,'False');
$$ LANGUAGE SQL;

CREATE FUNCTION SendAnswer(NameTask text, QueryAnswer text)
RETURNS text
SECURITY DEFINER
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
    MaxExeTime interval;
BEGIN 
    EXECUTE 'SELECT solution FROM tasks WHERE name = $1 ' USING NameTask INTO QuerySolution; 
    EXECUTE 'SELECT execute_time FROM tasks WHERE name = $1 ' USING NameTask INTO MaxExeTime; 
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

    StartTime := clock_timestamp(); 
    EXECUTE QueryAnswer;
    EndTime := clock_timestamp(); 
    ExeTime := EndTime - StartTime;
    
    IF (ExeTime>MaxExeTime) THEN
        DROP TABLE solution;
        DROP TABLE answer;
        RETURN 'Request takes too long ' || ExeTime;
    END IF;

    EXECUTE 'UPDATE tasks SET decided = True WHERE name = $1' USING NameTask; 
    
RETURN 'The problem is solved correctly. time: ' || extract(sec from ExeTime) || ' seconds.';
End;
$$ LANGUAGE plpgsql;

DO
$$
BEGIN
    GRANT EXECUTE ON FUNCTION sendanswer TO public;
    GRANT ALL PRIVILEGES ON students_tasks TO public;
    GRANT ALL PRIVILEGES ON tasks TO sfda_teacher;
END;
$$;


