--
--
--  GET EVERYONE TO A GOOD STATE
--
--

--
-- 1. delete all games cause it's easiest
--
DELETE FROM PCG_GAMEBOARD;
DELETE FROM PCG_GAMEBOARD_COLOR;
DELETE FROM PCG_GAMEBOARD_PLAYER;
DELETE FROM PCG_GAMEBOARD_TILE;

COMMIT; -- you must commit the deletion

--
-- 1.5 validate that PCG_GAMEBOARD was actually cleared, if not rerun step 1
--
SELECT * FROM PCG_GAMEBOARD;

--
-- 2. we all need to recreate a good copy of the pcg_paint_tile procedure
--
CREATE OR REPLACE PROCEDURE PCG_PAINT_TILE (
    -- Parameters: P_Gameboard_ID, P_Player_ID. P_Row_Num, P_Col_Num
    P_Gameboard_ID IN NUMBER,
    P_Player_ID    IN VARCHAR2,
    P_Row_Num      IN NUMBER,
    P_Col_Num      IN NUMBER
) IS
    e_gameboard_not_found   EXCEPTION;
    e_player_not_found      EXCEPTION;
    e_tile_not_found        EXCEPTION;
    e_color_not_selected    EXCEPTION;

    v_exists NUMBER;
    v_color  VARCHAR2(10);
BEGIN
    -- Validation: Is the P_Gameboard_ID a valid gameboard?
    SELECT COUNT(*) INTO v_exists
    FROM PCG_GAMEBOARD
    WHERE Gameboard_ID = P_Gameboard_ID;

    IF v_exists = 0 THEN
        RAISE e_gameboard_not_found;
    END IF;

    -- Validation: Is P_Player_ID a valid player?
    SELECT COUNT(*) INTO v_exists
    FROM PCG_PLAYER
    WHERE Player_ID = P_Player_ID;

    IF v_exists = 0 THEN
        RAISE e_player_not_found;
    END IF;

    -- Validation: Is tile (P_Row_Num, P_Col_Num) valid (exists for the gameboard)?
    SELECT COUNT(*) INTO v_exists
    FROM PCG_GAMEBOARD_TILE
    WHERE Gameboard_ID = P_Gameboard_ID
        AND Tile_Row = P_Row_Num
        AND Tile_Col = P_Col_Num;

    IF v_exists = 0 THEN
        RAISE e_tile_not_found;
    END IF;

    -- Validation: Does the player have a color selected to play?
    SELECT COUNT(*) INTO v_exists
    FROM PCG_GAMEBOARD_PLAYER
    WHERE Gameboard_ID = P_Gameboard_ID
        AND Player_ID = P_Player_ID
        AND Role = 'Player'
        AND Selected_Color_Name IS NOT NULL;

    IF v_exists = 0 THEN
        RAISE e_color_not_selected;
    END IF;

    -- Retrieve player's selected color
    SELECT Selected_Color_Name INTO v_color
    FROM PCG_GAMEBOARD_PLAYER
    WHERE Gameboard_ID = P_Gameboard_ID
        AND Player_ID = P_Player_ID
        AND Role = 'Player';

    -- Goal 1: Paint the tile the player selects
    UPDATE PCG_GAMEBOARD_TILE
        SET Player_ID = P_Player_ID,
        Color_Name = v_color
    WHERE Gameboard_ID = P_Gameboard_ID
        AND Tile_Row = P_Row_Num
        AND Tile_Col = P_Col_Num;


    -- Goal 2: Steal adjacent tiles (up, down, left, right)
    UPDATE PCG_GAMEBOARD_TILE
        SET Player_ID = P_Player_ID
    WHERE Gameboard_ID = P_Gameboard_ID
        AND Color_Name = v_color
        AND Player_ID IS NOT NULL
        AND Player_ID <> P_Player_ID
        AND ABS(Tile_Row - P_Row_Num) + ABS(Tile_Col - P_Col_Num) = 1;  -- manhattan distance for 1 unit of distance: https://cp-algorithms.com/geometry/manhattan-distance.html
                                                                        -- https://leetcode.com/problems/01-matrix/description/
EXCEPTION
    WHEN e_gameboard_not_found THEN
        DBMS_OUTPUT.PUT_LINE('error: gameboard not found: ' || P_Gameboard_ID);
    WHEN e_player_not_found THEN
        DBMS_OUTPUT.PUT_LINE('error: player not found for gameboard: ' || P_Player_ID);
    WHEN e_tile_not_found THEN
        DBMS_OUTPUT.PUT_LINE('error: tile not found: (' || P_Row_Num || ',' || P_Col_Num || ')');
    WHEN e_color_not_selected THEN
        DBMS_OUTPUT.PUT_LINE('error: color not selected for player: ' || P_Player_ID);
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('unexpected error: ' || SQLERRM);
END PCG_PAINT_TILE;
/


--
-- 3. recompile shared procedure with good version of `PCG_PAINT_TILE`
--
create or replace PROCEDURE PCG_PAINT(P_Gameboard_ID integer, P_Row_Num integer, P_Col_Num integer) AS 
BEGIN 
  PCG_PAINT_TILE(P_Gameboard_ID, USER, P_Row_Num, P_Col_Num); 
  COMMIT; 
END; 

--
-- 4. grant priveleges on our shared procedures, not sure why this has to be redone sometimes...
--
GRANT EXECUTE ON PCG_JOIN TO ame76, la584, mag574, pjp74, whf27;
GRANT EXECUTE ON PCG_SELECT_COLOR TO ame76, la584, mag574, pjp74, whf27;
GRANT EXECUTE ON PCG_PAINT TO ame76, la584, mag574, pjp74, whf27;







--
--
-- LETS PLAY SOME TILES
--
--

--
-- 1. everyone create game id 333333 game
--
CALL PCG_NEW_GAMEBOARD(333333,4,3,3,3);

--
-- 2. everyone share your colors
--
SELECT 
    Gameboard_ID,
    Color_Name
FROM PCG_GAMEBOARD_COLOR
WHERE Gameboard_ID = 333333;


---
--- REFEREE 1 - Paul
---

--- Mike, Will, and Andrew will pick the same color
--- mag574
CALL pjp74.PCG_JOIN(333333); 
CALL pjp74.PCG_SELECT(333333,'Color1'); 
CALL pjp74.PCG_PAINT(333333, 1, 2);
--- whf27
CALL pjp74.PCG_SELECT(333333); 
CALL pjp74.PCG_SELECT(333333,'Color1'); 
CALL pjp74.PCG_PAINT(333333, 2, 1);
--- ame76
CALL pjp74.PCG_SELECT(333333); 
CALL pjp74.PCG_SELECT(333333,'Color1'); 
CALL pjp74.PCG_PAINT(333333, 1, 1);
--- la584
CALL pjp74.PCG_SELECT(333333); 
CALL pjp74.PCG_SELECT(333333,'Color2'); 
CALL pjp74.PCG_PAINT(333333, 2, 2);



---
--- REFEREE 2 - Andrew
---

--- Paul and Will pick same color
--- mag574
CALL ame76.PCG_JOIN(333333); 
CALL ame76.PCG_SELECT(333333,'Color1'); 
CALL ame76.PCG_PAINT(333333, 1, 2);
--- pjp74
CALL ame76.PCG_JOIN(333333); 
CALL ame76.PCG_SELECT(333333,'Color2'); 
CALL ame76.PCG_PAINT(333333, 3, 3);
--- whf27
CALL ame76.PCG_JOIN(333333); 
CALL ame76.PCG_SELECT(333333,'Color2'); 
CALL ame76.PCG_PAINT(333333, 3, 3);
--- la584
CALL ame76.PCG_JOIN(333333); 
CALL ame76.PCG_SELECT(333333,'Color3'); 
CALL ame76.PCG_PAINT(333333, 2, 2);



---
--- REFEREE 3 - Lethe
---

--- Mike and Paul pick same color, Andrew and Will pick same color
--- mag574
CALL la584.PCG_JOIN(333333); 
CALL la584.PCG_SELECT(333333, 'Color1'); 
CALL la584.PCG_PAINT(333333, 1, 1);
--- pjp74
CALL la584.PCG_JOIN(333333); 
CALL la584.PCG_SELECT(333333,'Color1'); 
CALL la584.PCG_PAINT(333333, 1, 3);
--- ame76
CALL la584.PCG_JOIN(333333); 
CALL la584.PCG_SELECT(333333,'Color2'); 
CALL la584.PCG_PAINT(333333, 3, 1);
--- whf27
CALL la584.PCG_JOIN(333333); 
CALL la584.PCG_SELECT(333333,'Color2'); 
CALL la584.PCG_PAINT(333333, 2, 2);



---
--- REFEREE 4 - Will.I.Am
---

--- Paul and Andrew pick same color
--- mag574
CALL whf27.PCG_JOIN(333333); 
CALL whf27.PCG_SELECT(333333, 'Color1'); 
CALL whf27.PCG_PAINT(333333, 2, 2);
--- pjp74
CALL whf27.PCG_JOIN(333333); 
CALL whf27.PCG_SELECT(333333, 'Color2');
CALL whf27.PCG_PAINT(333333, 1, 2); 
--- ame76
CALL whf27.PCG_JOIN(333333); 
CALL whf27.PCG_SELECT(333333, 'Color2'); 
CALL whf27.PCG_PAINT(333333, 1, 2); 
--- la584
CALL whf27.PCG_JOIN(333333); 
CALL whf27.PCG_SELECT(333333, 'Color3'); 
CALL whf27.PCG_PAINT(333333, 3, 3);



---
--- REFEREE 5 - Mike
---

--- Will and Andrew pick same color
--- pjp74
CALL mag574.PCG_JOIN(333333); 
CALL mag574.PCG_SELECT(333333,'Color1'); 
CALL mag574.PCG_PAINT(333333, 1, 1); 
--- whf27
CALL mag574.PCG_JOIN(333333); 
CALL mag574.PCG_SELECT(333333,'Color2'); 
CALL mag574.PCG_PAINT(333333, 3, 3); 
--- ame76
CALL mag574.PCG_JOIN(333333); 
CALL mag574.PCG_SELECT(333333,'Color2'); 
CALL mag574.PCG_PAINT(333333, 3, 3); 
--- la584
CALL mag574.PCG_JOIN(333333); 
CALL mag574.PCG_SELECT(333333,'Color3'); 
CALL mag574.PCG_PAINT(333333, 2, 2); 
