CREATE OR REPLACE PROCEDURE PCG_NEW_GAMEBOARD (
  P_Gameboard_ID NUMBER,
  P_Number_Of_Players NUMBER,
  P_Number_Of_Rows NUMBER,
  P_Number_Of_Cols NUMBER,
  P_Number_Of_Colors NUMBER
)
IS 
 c integer;
BEGIN
  -- Validation
  IF NOT P_Gameboard_ID BETWEEN 100000 AND 999999 THEN
    RAISE_APPLICATION_ERROR(-20001,'Gameboard ID MUST be a 6-digit number');
  END IF;
  
  IF NOT P_Number_Of_Players BETWEEN 2 AND 5 THEN
    RAISE_APPLICATION_ERROR(-20001,'Number of players MUST be between 2 and 5');
  END IF;
  
  IF NOT P_Number_Of_Rows BETWEEN 3 AND 8 THEN
    RAISE_APPLICATION_ERROR(-20001,'Number of rows MUST be between 3 and 8');
  END IF;
  
  IF NOT P_Number_Of_Cols BETWEEN 3 AND 8 THEN
    RAISE_APPLICATION_ERROR(-20001,'Number of cols MUST be between 3 and 8');
  END IF;
  
  IF NOT P_Number_Of_Colors BETWEEN 2 AND 8 THEN
    RAISE_APPLICATION_ERROR(-20001,'Number of colors MUST be between 2 and 8');
  END IF;
  
  SELECT count(*) 
    INTO c 
    FROM PCG_GAMEBOARD g
   WHERE g.GAMEBOARD_ID = P_Gameboard_ID;
  IF c > 0 THEN
    RAISE_APPLICATION_ERROR(-20001,'Gameboard ID ('||P_Gameboard_ID||') already exists.');
  END IF; 
  
  
  -- Create Gameboard
  INSERT INTO PCG_GAMEBOARD (GAMEBOARD_ID,NUMBER_OF_PLAYERS,NUMBER_OF_ROWS,NUMBER_OF_COLS,NUMBER_OF_COLORS)
  VALUES (P_Gameboard_ID,P_Number_Of_Players,P_Number_Of_Rows,P_Number_Of_Cols,P_Number_Of_Colors);

   -- Create Referee
  INSERT INTO PCG_GAMEBOARD_PLAYER (GAMEBOARD_ID,PLAYER_ID,ROLE,ROLE_INDEX)
  VALUES (P_Gameboard_ID,USER,'Referee',0);
  
  -- Random Colors
  INSERT INTO PCG_GAMEBOARD_COLOR (GAMEBOARD_ID,COLOR_NAME)
  SELECT P_Gameboard_ID, COLOR_NAME FROM (
    SELECT COLOR_NAME, RANK() over(ORDER BY dbms_random.value) COLOR_RANK FROM PCG_COLOR
  ) WHERE COLOR_RANK <= P_Number_Of_Colors;
  
  -- Random Colors (validation)
  SELECT count(*) into c FROM PCG_GAMEBOARD_COLOR gc WHERE gc.GAMEBOARD_ID = P_Gameboard_ID;
  IF c <> P_Number_Of_Colors THEN
    RAISE_APPLICATION_ERROR(-20001,'Incorrect number of colors ('||c||'), when '||P_Number_Of_Colors||' colors are required.');
  END IF;
  
  -- Create Gameboard tiles (rows x cols)
  FOR r in 1..P_Number_Of_Rows LOOP
    FOR c in 1..P_Number_Of_Cols LOOP
      INSERT INTO PCG_GAMEBOARD_TILE (GAMEBOARD_ID,TILE_ROW,TILE_COL)
      VALUES (P_Gameboard_ID, r, c); 
    END LOOP;
  END LOOP;
  
END;
/
































call PCG_NEW_GAMEBOARD(123456,3,4,5,6);

--Test Validation
--1.
call PCG_NEW_GAMEBOARD(1234560,3,4,5,6);
call PCG_NEW_GAMEBOARD(123456,3,4,5,10);
call PCG_NEW_GAMEBOARD(123456,3,4,5,10);



call PCG_NEW_GAMEBOARD(123456,3,5,5,6);

SELECT * FROM PCG_GAMEBOARD WHERE GAMEBOARD_ID = '123456';
SELECT * FROM PCG_GAMEBOARD_PLAYER WHERE GAMEBOARD_ID = '123456';
SELECT * FROM PCG_GAMEBOARD_COLOR WHERE GAMEBOARD_ID = '123456';
SELECT * FROM PCG_GAMEBOARD_TILE WHERE GAMEBOARD_ID = '123456';
ROLLBACK;


SELECT * FROM PCG_COLOR;
--Random: dbms_random.value

--1. FETCH FIRST # ROW ONLY (Oracle)
SELECT COLOR_NAME FROM PCG_COLOR ORDER BY dbms_random.value 
FETCH FIRST 5 ROW ONLY;

--2. WHERE ROWNUM <= # (Oracle)
SELECT COLOR_NAME 
FROM PCG_COLOR 
WHERE ROWNUM <= 5
ORDER BY dbms_random.value ;


--3. RANK() over(ORDER BY dbms_random.value)
SELECT COLOR_NAME, RANK() over(ORDER BY dbms_random.value) COLOR_RANK FROM PCG_COLOR
