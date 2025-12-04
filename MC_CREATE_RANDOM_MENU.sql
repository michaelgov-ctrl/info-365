CREATE OR REPLACE PROCEDURE MC_CREATE_RANDOM_MENU
(
    p_day_number IN MC_90_DAYS_MENU.DAY_NUMBER%TYPE
) IS
    v_breakfast_id  MC_90_DAYS_MEAL_TYPE.MEAL_TYPE_ID%TYPE;
    v_lunch_id  MC_90_DAYS_MEAL_TYPE.MEAL_TYPE_ID%TYPE;
    v_snack_id  MC_90_DAYS_MEAL_TYPE.MEAL_TYPE_ID%TYPE;
    v_dinner_id MC_90_DAYS_MEAL_TYPE.MEAL_TYPE_ID%TYPE;

    -- sweet sweet helpers
    FUNCTION rand RETURN NUMBER IS
    BEGIN
        RETURN TRUNC(DBMS_RANDOM.VALUE(0, 2));
    END rand;

    PROCEDURE insert_rand_food_for
    (
        p_meal_type_id  IN MC_90_DAYS_MENU_ITEM.MEAL_TYPE_ID%TYPE,
        p_category_name IN MC_MENU_CATEGORY.CATEGORY_NAME%TYPE
    ) IS
        v_menu_item_id MC_MENU_ITEM.MENU_ITEM_ID%TYPE;
    BEGIN
        -- get random item from category
        SELECT menu_item_id
        INTO v_menu_item_id
        FROM (
                SELECT i.menu_item_id
                FROM MC_MENU_ITEM i
                JOIN MC_MENU_CATEGORY c
                    ON c.category_id = i.category_id
                WHERE c.category_name = p_category_name
                ORDER BY DBMS_RANDOM.VALUE
            )
        WHERE ROWNUM = 1;

        INSERT INTO MC_90_DAYS_MENU_ITEM
            (DAY_NUMBER, MEAL_TYPE_ID, MENU_ITEM_ID)
        VALUES
            (
                p_day_number,
                p_meal_type_id,
                v_menu_item_id
            );
    END insert_rand_food_for;

BEGIN
    -- validate day
    IF p_day_number < 1 OR p_day_number > 90 THEN
        RAISE_APPLICATION_ERROR(-20190, 'day number must be between 1 and 90.');
    END IF;

    -- find meals by name
    SELECT meal_type_id INTO v_breakfast_id
        FROM MC_90_DAYS_MEAL_TYPE
        WHERE meal_type_name = 'Breakfast';

    SELECT meal_type_id INTO v_lunch_id
        FROM MC_90_DAYS_MEAL_TYPE
        WHERE meal_type_name = 'Lunch';

    SELECT meal_type_id INTO v_snack_id
        FROM MC_90_DAYS_MEAL_TYPE
        WHERE meal_type_name = 'Afternoon snack';

    SELECT meal_type_id INTO v_dinner_id
        FROM MC_90_DAYS_MEAL_TYPE
        WHERE meal_type_name = 'Dinner';

    -- clear menu
    DELETE FROM MC_90_DAYS_MENU_ITEM
        WHERE day_number = p_day_number;

    DELETE FROM MC_90_DAYS_MENU
        WHERE day_number = p_day_number;

    -- seed the days menu
    INSERT INTO MC_90_DAYS_MENU
    (
        DAY_NUMBER,
        SUM_FAT_DAILY_PERC,
        SUM_SATURATED_FAT_DAILY_PERC,
        SUM_CHOLESTEROL_DAILY_PERC,
        SUM_SODIUM_DAILY_PERC,
        SUM_CARBOHYDRATES_DAILY_PERC,
        SUM_DIETARY_FIBER_DAILY_PERC,
        SUM_VITAMIN_A_DAILY_PERC,
        SUM_VITAMIN_C_DAILY_PERC,
        SUM_CALCIUM_DAILY_PERC,
        SUM_IRON_DAILY_PERC
    )
    VALUES (
        p_day_number,
        0,0,0,0,0,0,0,0,0,0
    );

    -- breakfast
    insert_rand_food_for(v_breakfast_id, 'Breakfast');
    insert_rand_food_for(v_breakfast_id, 'Coffee & Tea');

    -- lunch
    insert_rand_food_for(v_lunch_id, 'Salads');
    insert_rand_food_for(v_lunch_id, 'Beverages');

    IF rand = 0 THEN
        insert_rand_food_for(v_lunch_id, 'Beef & Pork');
    ELSE
        insert_rand_food_for(v_lunch_id, 'Chicken & Fish');
    END IF;

    IF rand = 0 THEN
        insert_rand_food_for(v_lunch_id, 'Desserts');
    END IF;

    -- snack
    IF rand = 0 THEN
        insert_rand_food_for(v_snack_id, 'Smoothies & Shakes');
    ELSE
        insert_rand_food_for(v_snack_id, 'Coffee & Tea');
        insert_rand_food_for(v_snack_id, 'Snacks & Sides');
    END IF;

    -- dinner
    insert_rand_food_for(v_dinner_id, 'Beverages');

    IF rand = 0 THEN
        insert_rand_food_for(v_dinner_id, 'Beef & Pork');
    ELSE
        insert_rand_food_for(v_dinner_id, 'Chicken & Fish');
    END IF;

    IF rand = 0 THEN
        insert_rand_food_for(v_dinner_id, 'Desserts');
    ELSE
        insert_rand_food_for(v_dinner_id, 'Coffee & Tea');
    END IF;

END MC_CREATE_RANDOM_MENU;
/
