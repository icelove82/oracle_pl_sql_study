SELECT SYSDATE FROM DUAL;

-- 1. select & insert
DECLARE
    c_id PEOPLE.ID%type := 1;
    c_name PEOPLE.NAME%type;
    c_age PEOPLE.AGE%type;
BEGIN
    SELECT ID, NAME, AGE INTO c_id, c_name, c_age FROM PEOPLE WHERE ID = 261;

    INSERT INTO PEOPLE (NAME, AGE) VALUES ('ygc', 68);

    DBMS_OUTPUT.PUT_LINE('anonymous block run :' || c_id || c_name || c_age);

    COMMIT;
END;
/

-- 2. condition
DECLARE
    name VARCHAR2(128);
    age INT := 0;
    BIRTH_DAY CONSTANT INT := 18;
BEGIN
    IF BIRTH_DAY < 18 THEN
        name := 'Child';
        age := 3;
    ELSIF BIRTH_DAY = 18 THEN
        name := 'Adult';
        age := BIRTH_DAY;
    ELSE
        name := 'Man';
        age := 40;
    END IF;

    INSERT INTO PEOPLE (NAME, AGE)  VALUES (name, age);

    COMMIT;
END;
/

-- 3. cursor, varray list, row type
DECLARE
    CURSOR c_people is SELECT * FROM PEOPLE;
    TYPE type_people_list IS VARRAY(20) OF PEOPLE%rowtype;
    people_list type_people_list := type_people_list();
    counter INT := 1;
    val varchar2(512);
BEGIN
    FOR n IN c_people
        LOOP
            people_list.extend;
            people_list(counter) := n;

--         insert value
            val := people_list(counter).ID || ' | ' || people_list(counter).NAME || ' | ' || people_list(counter).AGE;
            INSERT INTO RESULT (RESVAL) VALUES (val);

            counter := counter + 1;
        END LOOP;

    COMMIT;
END;
/

-- 4. create procedure
CREATE OR REPLACE PROCEDURE greetings
AS
BEGIN
    INSERT INTO RESULT(RESVAL) VALUES ('HI~');
    COMMIT;
END;

-- call a procedure
BEGIN
    greetings;
END;
/

-- 5. create standalone param procedure
CREATE OR REPLACE PROCEDURE findMax(x IN int, y IN int, z OUT int)
AS
BEGIN
    IF x < y THEN
        z := y;
    ELSIF x > y THEN
        z := x;
    ELSE
        z := x;
    END IF;
END;
/

DECLARE
    a int;
    b int;
    c int;
BEGIN
    a := 3;
    b := 5;
    findMax(a, b, c);
    INSERT INTO RESULT(RESVAL) VALUES ('Maximum of (3, 5) : ' || c);
    COMMIT;
    BEGIN
        INSERT INTO RESULT(RESVAL) VALUES ('Maximum of (3, 5) : ' || c);
        COMMIT;
    end;
END;
/

-- 6. create anonymous param procedure
DECLARE
    a number;
    b number;
    c number;
    PROCEDURE findMin(x IN number, y IN number, z OUT number) IS
    BEGIN
        IF x < y THEN
            z:= x;
        ELSE
            z:= y;
        END IF;
    END;
BEGIN
    a:= 23;
    b:= 45;
    findMin(a, b, c);
    INSERT INTO RESULT(RESVAL) VALUES ('Minimum of (23, 45) : ' || c);
    COMMIT;
END;
/

-- 7. create standalone function
CREATE OR REPLACE FUNCTION totalPeople
    RETURN number AS
    total number := 0;
BEGIN
    SELECT COUNT(*) INTO total FROM PEOPLE;

    RETURN total;
END;

BEGIN
    INSERT INTO RESULT (RESVAL) VALUES (TOTALPEOPLE());
    COMMIT;
END;

DECLARE
    total number := 0;
BEGIN
    total := TOTALPEOPLE();
    INSERT INTO RESULT (RESVAL) VALUES (total);
    COMMIT;
END;
/

-- 8. create anonymous param function
DECLARE
    a number;
    b number;
    c number;
    FUNCTION funMax(x IN number, y IN number)
        RETURN number
        IS
        z number;
    BEGIN
        IF x > y THEN
            z := x;
        ELSE
            z := y;
        END IF;

        RETURN z;
    END;
BEGIN
    a := 23;
    b := 45;
    c := funMax(a, b);

    INSERT INTO RESULT (RESVAL) VALUES ('function find max : ' || c);
    COMMIT;
END;
/

-- 9. recode, row type
DECLARE
    people_rec PEOPLE%rowtype;
BEGIN
    SELECT * INTO people_rec
    FROM PEOPLE
    WHERE ID = 45;

    INSERT INTO RESULT (RESVAL) VALUES ('recode of id = 45 : ' || people_rec.NAME || people_rec.AGE);
    COMMIT;
END;
/

-- 10. cursor-based recode
DECLARE
    CURSOR people_cur IS SELECT *
                         FROM PEOPLE;
    people_rec PEOPLE%rowtype;

BEGIN
    OPEN people_cur;
    LOOP
        FETCH people_cur INTO people_rec;
        EXIT WHEN people_cur%NOTFOUND;
        INSERT INTO RESULT (RESVAL) VALUES ('recode : ' || people_rec.ID || people_rec.NAME || people_rec.AGE);
    END LOOP;

    COMMIT;
END;
/

-- 11. exception, user define exception
DECLARE
    id int := 0;
    people_rec PEOPLE%rowtype;
    invalid_id EXCEPTION ;

BEGIN
    IF id = 0 THEN
        RAISE invalid_id;
    end if;

    SELECT *
    INTO people_rec
    FROM PEOPLE
    WHERE ID = id;

    INSERT INTO RESULT (RESVAL) VALUES ('recode of id = 1 : ' || people_rec.NAME || people_rec.AGE);
    COMMIT;

EXCEPTION
    WHEN invalid_id THEN
        INSERT INTO RESULT (RESVAL) VALUES ('recode of id = 0 : raise user define exception');
        COMMIT;
    WHEN no_data_found THEN
        INSERT INTO RESULT (RESVAL) VALUES ('recode of id = 1 : no found data');
        COMMIT;
    WHEN others THEN
        INSERT INTO RESULT (RESVAL) VALUES ('unknown error');
        COMMIT;

END;
/

-- 12. create trigger
CREATE OR REPLACE TRIGGER log_people_insert
    AFTER INSERT
    ON PEOPLE
    FOR EACH ROW
    WHEN ( NEW.ID > 0 )
DECLARE
    log varchar2(512);
BEGIN
    log := 'log | insert :' || :NEW.ID || :NEW.NAME || :NEW.AGE;
    INSERT INTO RESULT (RESVAL) VALUES (log);
END;
/

-- 13. package
-- package head
CREATE OR REPLACE PACKAGE pkg_main AS
    COUNT int := 0;

    PROCEDURE addPeople(name PEOPLE.NAME%type, age PEOPLE.AGE%type);

    PROCEDURE delPeople(delId PEOPLE.ID%type);
END pkg_main;

-- package body
CREATE OR REPLACE PACKAGE BODY pkg_main AS
    PROCEDURE addPeople(name PEOPLE.NAME%type, age PEOPLE.AGE%type)
        IS
    BEGIN
        COUNT := COUNT + 1;
        INSERT INTO PEOPLE (NAME, AGE) VALUES (name, age);

        INSERT INTO RESULT (RESVAL) VALUES ('pkg count : ' || pkg_main.COUNT);
        COMMIT;
    END;

    PROCEDURE delPeople(delId PEOPLE.ID%type)
        IS
    BEGIN
        COUNT := COUNT + 1;
        DELETE
        FROM PEOPLE
        WHERE ID = delId;

        INSERT INTO RESULT (RESVAL) VALUES ('pkg count : ' || pkg_main.COUNT);
        COMMIT;
    END;
END pkg_main;

-- use pkg
DECLARE
    delId int := 242;
BEGIN
    pkg_main.addPeople('YunMyeonghun', 40);
    pkg_main.delPeople(delId);
END;
/

-- 14. key value table
DECLARE
    TYPE salary IS TABLE OF number INDEX BY varchar2(20);
    salary_list salary;
    name        varchar2(20);
BEGIN
    salary_list('Rajnish') := 62000;
    salary_list('Minakshi') := 75000;
    salary_list('Martin') := 102000;
    salary_list('James') := 78000;

    name := salary_list.FIRST;

    WHILE name IS NOT NULL
        LOOP
            INSERT INTO RESULT (RESVAL) VALUES ('salary of : ' || name || ' is ' || salary_list(name));
            COMMIT;
            name := salary_list.NEXT(name);
        END LOOP;

EXCEPTION
    WHEN others THEN
        COMMIT;
END;
/

-- 15. value table
DECLARE
    TYPE name_table IS TABLE OF varchar2(10);
    TYPE grade_table IS TABLE OF integer;
    names  name_table;
    grades grade_table;
    total  integer;
BEGIN
    names := name_table('Kavita', 'Pritam', 'Ayan', 'Rishav', 'Aziz');
    grades := grade_table(91, 92, 93, 94, 95);
    total := names.COUNT;

    FOR i IN 1..total
        LOOP
            INSERT INTO RESULT (RESVAL) VALUES ('value table : ' || names(i) || ' is ' || grades(i));
        END LOOP;
    COMMIT;
END;
/

-- 16. type table
DECLARE
    CURSOR cur_people IS SELECT name
                         FROM PEOPLE;
    TYPE type_list IS TABLE OF PEOPLE.NAME%TYPE;
    name_list type_list := type_list();
    total     integer   := 0;
BEGIN
    FOR n IN cur_people
        LOOP
            total := total + 1;
            name_list.extend;
            name_list(total) := n.NAME;
            INSERT INTO RESULT (RESVAL) VALUES ('16. type table : ' || n.NAME);
        END LOOP;

    COMMIT;
END;
/



