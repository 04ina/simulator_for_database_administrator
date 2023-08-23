--\echo Use "CREATE EXTENSION TasksForDBA" to load this file. \quit


DO
$$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'sfda_student') THEN
        CREATE ROLE sfda_student LOGIN;    
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'sfda_teacher') THEN
        CREATE ROLE teacher LOGIN;    
    END IF;

    GRANT USAGE ON SCHEMA bookings TO student;
    GRANT USAGE ON SCHEMA bookings TO teacher;

    GRANT SELECT ON ALL tABLES IN SCHEMA bookings TO student;
    GRANT SELECT ON ALL tABLES IN SCHEMA bookings TO teacher;
END;
$$;


--\i /home/o4ina/postgres/TasksForDBA/demo-small-20170815.sql

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

/*
GRANT SELECT ON tasks TO sfda_privileged_role;
REVOKE ALL PRIVILEGES ON tasks TO public;
GRANT SET ROLE TO student;
*/

CREATE FUNCTION grant_privileges(namschema text)
RETURNS VOID AS $$
BEGIN
EXECUTE 'GRANT USAGE ON SCHEMA ' || namschema || ' TO sfda_student';
EXECUTE 'GRANT USAGE ON SCHEMA ' || namschema || ' TO sfda_teacher';

EXECUTE 'GRANT SELECT ON ALL TABLES IN SCHEMA ' || namschema || ' TO sfda_student';
EXECUTE 'GRANT SELECT ON ALL TABLES IN SCHEMA ' || namschema ||' TO sfda_teacher';
END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION equalitycheck()
RETURNS void AS $$
DECLARE 
    AnsCursor CURSOR FOR SELECT * FROM answer;
    SolCursor CURSOR FOR SELECT * FROM solution;
    val RECORD;
BEGIN
    OPEN AnsCursor;
    OPEN SolCursor;
    FETCH NEXT FROM AnsCursor INTO val;
    RAISE NOTICE 'val % val %', val.range, val.model; 

    WHILE FOUND LOOP
        RAISE NOTICE 'val % val %', val.range, val.model; 
        FETCH NEXT FROM AnsCursor INTO val;
    END LOOP;



    CLOSE AnsCursor;
    CLOSE SolCursor;
END;
$$ LANGUAGE plpgsql;

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
    test TEXT; 
    aaa CURSOR FOR SELECT * FROM aircrafts;
BEGIN 
    --SET LOCAL ROLE sfda_privileged_role;
    -- Creating tables with solution and answer

    EXECUTE 'SELECT solution FROM tasks WHERE name = $1' USING NameTask INTO QuerySolution; 
    EXECUTE 'SELECT execute_time FROM tasks WHERE name = $1' USING NameTask INTO MaxExeTime; 
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
  
    --DECLARE AnsCursor CURSOR FOR SELECT * FROM answer;
    --DECLARE SolCursor CURSOR FOR SELECT * FROM solution;

    EXECUTE 'SELECT equalitycheck()';

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
    
    EXECUTE 'SELECT $1::timestamp - $2::timestamp' USING EndTime, StartTime INTO test;
    
    RAISE NOTICE 'aboab %', ExeTime; 

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
    --REVOKE ALL PRIVILEGES ON tasks FROM sfda_student;
    GRANT ALL PRIVILEGES ON tasks TO teacher;
END;
$$;


