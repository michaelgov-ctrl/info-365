CREATE OR REPLACE PROCEDURE PCG_JOIN_GAMEBOARD (
    -- Parameters: P_Gameboard_ID, P_Player_ID
    P_Gameboard_ID IN NUMBER,
    P_Player_ID    IN VARCHAR2
) IS
    e_gameboard_not_found EXCEPTION;
    e_player_not_found    EXCEPTION;
    e_already_joined      EXCEPTION;
    e_game_full           EXCEPTION;

    v_max_players     PCG_GAMEBOARD.Number_Of_Players%TYPE;
    v_current_players NUMBER;
    v_exists          NUMBER;
BEGIN
    -- Validation: Is the P_Gameboard_ID a valid gameboard? 
    SELECT COUNT(*) INTO v_exists
    FROM PCG_GAMEBOARD
    WHERE Gameboard_ID = P_Gameboard_ID;
    IF v_exists = 0 THEN
        RAISE e_gameboard_not_found;
    END IF;

    SELECT Number_Of_Players INTO v_max_players
    FROM PCG_GAMEBOARD
    WHERE Gameboard_ID = P_Gameboard_ID;

    -- Validation: Is P_Player_ID a valid player? 
    SELECT COUNT(*) INTO v_exists
    FROM PCG_PLAYER
    WHERE Player_ID = P_Player_ID;
    IF v_exists = 0 THEN
        RAISE e_player_not_found;
    END IF;

    -- Validation: Is P_Player_ID allowed to join the gameboard? (Check max number of players) 
    SELECT COUNT(*) INTO v_exists
    FROM PCG_GAMEBOARD_PLAYER
    WHERE Gameboard_ID = P_Gameboard_ID
        AND Player_ID    = P_Player_ID;
    IF v_exists > 0 THEN
        RAISE e_already_joined;
    END IF;

    SELECT COUNT(*) INTO v_current_players
    FROM PCG_GAMEBOARD_PLAYER
    WHERE Gameboard_ID = P_Gameboard_ID
        AND Role = 'Player';
    IF v_current_players >= v_max_players THEN
        RAISE e_game_full;
    END IF;

    -- Goal: Create a new record in the PCG_GAMEBOARD_PLAYER table and corresponding records in the associated tables.
    INSERT INTO PCG_GAMEBOARD_PLAYER
        (Gameboard_ID, Player_ID, Role, Role_Index, Selected_Color_Name)
    SELECT
        P_Gameboard_ID,
        P_Player_ID,
        'Player',
        NVL( (SELECT MAX(p.Role_Index)
                FROM PCG_GAMEBOARD_PLAYER p
                WHERE p.Gameboard_ID = P_Gameboard_ID
                AND p.Role = 'Player'), 0) + 1,
        NULL
    FROM dual;

    DBMS_OUTPUT.PUT_LINE('player: ' || P_Player_ID || ' joined gameboard: ' || P_Gameboard_ID);

EXCEPTION
    WHEN e_gameboard_not_found THEN
        DBMS_OUTPUT.PUT_LINE('error: gameboard not found: ' || P_Gameboard_ID );
    WHEN e_player_not_found THEN
        DBMS_OUTPUT.PUT_LINE('error: player not found: ' || P_Player_ID);
    WHEN e_already_joined THEN
        DBMS_OUTPUT.PUT_LINE('error: player is already present: ' || P_Player_ID);
    WHEN e_game_full THEN
        DBMS_OUTPUT.PUT_LINE('error: gameboard is full: ' || P_Gameboard_ID);
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('unexpected error: ' || SQLERRM);
END PCG_JOIN_GAMEBOARD;
/


    -- TESTS --

-- Test: invalid P_Gameboard_ID
-- Setup:
DELETE FROM PCG_GAMEBOARD WHERE Gameboard_ID = 8675309;
MERGE INTO PCG_PLAYER p USING (SELECT 'P001' id FROM dual) s
ON (p.Player_ID = s.id)
WHEN NOT MATCHED THEN INSERT (Player_ID) VALUES (s.id);

-- Test:
BEGIN
    PCG_JOIN_GAMEBOARD(8675309, 'P001');
END;
/


-- Test: invalid P_Player_ID
-- Setup:
MERGE INTO PCG_GAMEBOARD g USING (SELECT 100042 gb, 3 maxp, 3 r, 3 c, 2 colors FROM dual) s
ON (g.Gameboard_ID = s.gb)
WHEN NOT MATCHED THEN
  INSERT (Gameboard_ID, Number_Of_Players, Number_Of_Rows, Number_Of_Cols, Number_Of_Colors)
  VALUES (s.gb, s.maxp, s.r, s.c, s.colors);

DELETE FROM PCG_PLAYER WHERE Player_ID = 'DOUGLAS_ADAMS';
DELETE FROM PCG_GAMEBOARD_PLAYER WHERE Gameboard_ID = 100042;

-- Test:
BEGIN
  PCG_JOIN_GAMEBOARD(100042, 'DOUGLAS_ADAMS');
END;


-- Test: valid P_Player_ID join gameboard successfully
-- Setup:
MERGE INTO PCG_GAMEBOARD g USING (SELECT 420002 gb, 3 maxp, 3 r, 3 c, 2 colors FROM dual) s
ON (g.Gameboard_ID = s.gb)
WHEN NOT MATCHED THEN
  INSERT (Gameboard_ID, Number_Of_Players, Number_Of_Rows, Number_Of_Cols, Number_Of_Colors)
  VALUES (s.gb, s.maxp, s.r, s.c, s.colors);

DELETE FROM PCG_GAMEBOARD_PLAYER WHERE Gameboard_ID = 420002;

MERGE INTO PCG_PLAYER p USING (SELECT 'P001' id FROM dual) s
ON (p.Player_ID = s.id)
WHEN NOT MATCHED THEN INSERT (Player_ID) VALUES (s.id);

-- Test:
BEGIN
    PCG_JOIN_GAMEBOARD(420002, 'P001');
END;


-- Test: valid P_Player_ID NOT allowed to join – max number of players already
-- Setup:
MERGE INTO PCG_GAMEBOARD g USING (SELECT 420001 gb, 2 maxp, 3 r, 3 c, 2 colors FROM dual) s
ON (g.Gameboard_ID = s.gb)
WHEN NOT MATCHED THEN
  INSERT (Gameboard_ID, Number_Of_Players, Number_Of_Rows, Number_Of_Cols, Number_Of_Colors)
  VALUES (s.gb, s.maxp, s.r, s.c, s.colors);

DELETE FROM PCG_GAMEBOARD_PLAYER WHERE Gameboard_ID = 420001;

MERGE INTO PCG_PLAYER p USING (
  SELECT 'P001' id FROM dual UNION ALL
  SELECT 'P002' FROM dual UNION ALL
  SELECT 'P003' FROM dual
) s ON (p.Player_ID = s.id)
WHEN NOT MATCHED THEN INSERT (Player_ID) VALUES (s.id);

-- Test:
BEGIN
    -- Fill game
    PCG_JOIN_GAMEBOARD(420001, 'P001');
    PCG_JOIN_GAMEBOARD(420001, 'P002');
    -- Should fail
    PCG_JOIN_GAMEBOARD(420001, 'P003');
END;
/
