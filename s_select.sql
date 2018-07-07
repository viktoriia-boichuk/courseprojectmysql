use supermarket;

-- 1 звільнити пенсіонерів
UPDATE workers 
SET 
    w_firing_date = DATE(NOW())
WHERE
    YEAR(NOW()) - YEAR(w_birth_date) >= 60
        AND w_firing_date IS NULL;
        
        
-- 2 середній вік працівників кожної посади
SELECT 
    w_job AS 'Посада',
    ROUND(AVG(YEAR(NOW()) - YEAR(w_birth_date)), 1) AS 'Середній вік'
FROM
    workers
WHERE
    w_firing_date IS NULL
GROUP BY 1
ORDER BY 2;


-- 3 найпопулярніші товари по відділах
SELECT 
    d_name AS 'Відділ',
    g_name AS 'Назва товару',
    MAX(val) AS 'Продано/Отримано'
FROM
    departments
        JOIN
    (SELECT 
        g_d_id,
            g_id,
            IF(sel_sum IS NULL, 0, sel_sum) / SUM(s_units_amount) AS val
    FROM
        supplies
    JOIN goods ON (s_g_id = g_id)
    LEFT JOIN (SELECT 
        sel_g_id, SUM(sel_units_amount) AS sel_sum
    FROM
        selling
    GROUP BY 1) AS temp1 ON (sel_g_id = g_id)
    GROUP BY 2) AS temp2 ON (d_id = g_d_id)
        JOIN
    goods ON (goods.g_id = temp2.g_id)
GROUP BY 1
ORDER BY 1;
    

-- 4 товари, які закінчуються і треба зробити замовлення
SELECT 
    g_name AS 'Назва товару',
    g_barcode AS 'Штрих-код'
FROM
    goods
        JOIN
    (SELECT 
        g_id, sup_sum - SUM(sel_units_amount) AS amount
    FROM
        selling
    JOIN goods ON (sel_g_id = g_id)
    JOIN (SELECT 
        s_g_id, SUM(s_units_amount) AS sup_sum
    FROM
        supplies
    GROUP BY 1) AS temp1 ON (s_g_id = g_id)
    GROUP BY 1) AS temp2 ON (goods.g_id = temp2.g_id)
WHERE
    amount <= 5;
    

-- 5 для кожного виробника найбільш і найменш вигідний товар
SELECT 
    manufacturer AS `Виробник`,
    max_good AS `Найбільш вигідний`,
    min_good AS `Найменш вигідний`
FROM
    (SELECT 
        sel_sup_manufacturers.`Виробник` AS manufacturer,
            `Назва товару` AS max_good,
            max_val
    FROM
        (SELECT 
        `Виробник`,
            MAX(`Продано/Отримано`) AS max_val
    FROM
        sel_sup_manufacturers
    GROUP BY 1) AS temp
    JOIN sel_sup_manufacturers ON (temp.max_val = sel_sup_manufacturers.`Продано/Отримано`)
    GROUP BY 1) AS max_table
        JOIN
    (SELECT 
        sel_sup_manufacturers.`Виробник`,
            `Назва товару` AS min_good,
            min_val
    FROM
        (SELECT 
        `Виробник`,
            MIN(`Продано/Отримано`) AS min_val
    FROM
        sel_sup_manufacturers
    GROUP BY 1) AS temp
    JOIN sel_sup_manufacturers ON (temp.min_val = sel_sup_manufacturers.`Продано/Отримано`)
    GROUP BY 1) AS min_table ON (max_table.manufacturer = min_table.`Виробник`);


-- 6 перелік виробників за кількістю поставлених товарів
SELECT 
    m_name AS 'Виробник',
    m_country AS 'Країна',
    m_city AS 'Місто'
FROM
    manufacturers
        JOIN
    goods ON (m_id = g_m_id)
        JOIN
    supplies ON (g_id = s_g_id)
GROUP BY 1
ORDER BY SUM(s_units_amount) DESC;


-- 7 який працівник і коли прийняв поставку з найбільшою кількістю товарів
SELECT 
    secondd.i_id AS 'Накладна',
    w_name AS 'Працівник',
    max_val AS 'Кількість товарів'
FROM
    (SELECT 
        i_w_id, MAX(amount) AS max_val
    FROM
        (SELECT 
        i_w_id, i_id, SUM(s_units_amount) AS amount
    FROM
        invoice
    JOIN supplies ON (i_id = s_i_id)
    GROUP BY 1 , 2) AS firstt
    GROUP BY 1) AS temp
        LEFT JOIN
    (SELECT 
        i_w_id, i_id, SUM(s_units_amount) AS amount
    FROM
        invoice
    JOIN supplies ON (i_id = s_i_id)
    GROUP BY 1 , 2) AS secondd ON (temp.max_val = secondd.amount)
        JOIN
    workers ON (secondd.i_w_id = w_id)
GROUP BY 1
ORDER BY 3 DESC
LIMIT 1;


SELECT 
    i_id AS 'Накладна',
    w_name AS 'Працівник',
    SUM(s_units_amount) AS 'Кількість товарів'
FROM
    workers
        JOIN
    invoice ON (w_id = i_w_id)
        JOIN
    supplies ON (i_id = s_i_id)
GROUP BY 1 , 2
ORDER BY 3 DESC
LIMIT 1;


-- 8 скільки в середньому своїх товарів постачає кожен виробник за 1 поставку (1 накладна)
SELECT 
    m_name AS 'Виробник',
    ROUND(SUM(s_units_amount) / COUNT(DISTINCT s_i_id),
            0) AS 'Середня кількість товарів'
FROM
    manufacturers
        JOIN
    goods ON (m_id = g_m_id)
        JOIN
    supplies ON (g_id = s_g_id)
GROUP BY 1;


-- 9 товар, який продався найменше (продано/отримано) від часу останньої поставки
SELECT 
    g_name AS 'Товар',
    g_barcode AS 'Штрих-код',
    IF(sel_amount IS NULL, 0, sel_amount) AS 'Продано',
    sup_amount AS 'Отримано'
FROM
    (SELECT 
        s_g_id, SUM(sel_units_amount) AS sel_amount
    FROM
        (SELECT 
        s_g_id,
            s_units_amount AS sup_amount,
            MAX(i_date_time) AS last_date
    FROM
        invoice
    JOIN supplies ON (i_id = s_i_id)
    GROUP BY 1
    ORDER BY 1) AS temp1
    JOIN selling ON (s_g_id = sel_g_id)
    JOIN transactions ON (sel_t_id = t_id)
    WHERE
        t_date_time >= last_date
    GROUP BY 1
    ORDER BY 1) AS temp
        RIGHT JOIN
    (SELECT 
        s_g_id AS good,
            s_units_amount AS sup_amount,
            MAX(i_date_time) AS last_date
    FROM
        invoice
    JOIN supplies ON (i_id = s_i_id)
    GROUP BY 1
    ORDER BY 1) AS temp1 ON (s_g_id = good)
        JOIN
    goods ON (good = g_id);


-- 10 скільки % всіх поставлених товарів з кожної країни продано
SELECT 
    m_country AS `Країна`,
    IF(SUM(sel_sum) IS NULL,
        0,
        SUM(sel_sum)) * 100 / general_sup_sum AS `%`
FROM
    (SELECT 
        sel_g_id, SUM(sel_units_amount) AS sel_sum
    FROM
        selling
    GROUP BY 1) AS temp
        RIGHT JOIN
    (SELECT DISTINCT
        s_g_id
    FROM
        supplies) AS sup ON (sel_g_id = s_g_id)
        JOIN
    goods ON (s_g_id = g_id)
        JOIN
    manufacturers ON (g_m_id = m_id)
        JOIN
    (SELECT 
        SUM(s_units_amount) AS general_sup_sum
    FROM
        supplies) AS gss
GROUP BY 1
ORDER BY 2 DESC;


-- 11 скільки транзакцій в середньому проводить один касир за день і скільки в середньому товарів при цьому продається 
SELECT 
    w_name AS 'Працівник',
    ROUND(tr_amount / days_amount, 0) AS 'Транзакцій за день',
    ROUND(SUM(sel_units_amount) / tr_amount, 0) AS 'Одиниць товару за транзакцію'
FROM
    (SELECT 
        t_w_id,
            COUNT(t_id) AS tr_amount,
            COUNT(DISTINCT t_date_time) days_amount
    FROM
        transactions
    GROUP BY 1) AS temp
        JOIN
    workers ON (temp.t_w_id = w_id)
        JOIN
    transactions ON (w_id = transactions.t_w_id)
        LEFT JOIN
    selling ON (t_id = sel_t_id)
GROUP BY 1;


-- 12 скільки відсотків всіх проданих товарів припало на вихідні?
SELECT 
    ROUND(IF(sel5 IS NULL, 0, sel5) * 100 / gen, 1) AS 'Субота',
    ROUND(IF(sel6 IS NULL, 0, sel6) * 100 / gen, 1) AS 'Неділя'
FROM
    (SELECT 5 AS wkd) AS five
        LEFT JOIN
    (SELECT 
        WEEKDAY(t_date_time) AS wdy, SUM(sel_units_amount) AS sel5
    FROM
        transactions
    JOIN selling ON (t_id = sel_t_id)
    WHERE
        WEEKDAY(t_date_time) = 5
    GROUP BY 1) AS saturday ON (wkd = wdy)
        JOIN
    (SELECT 6 AS weekd) AS six
        LEFT JOIN
    (SELECT 
        WEEKDAY(t_date_time) AS wd, SUM(sel_units_amount) AS sel6
    FROM
        transactions
    JOIN selling ON (t_id = sel_t_id)
    WHERE
        WEEKDAY(t_date_time) = 6
    GROUP BY 1) AS sunday ON (weekd = wd)
        JOIN
    (SELECT 
        SUM(sel_units_amount) AS gen
    FROM
        selling) AS temp3;


-- 13 збільшити зарплату за максимальний стаж
UPDATE workers 
SET 
    w_salary = w_salary + w_salary / 100 * 5
WHERE
    w_name = (SELECT 
            `Працівник`
        FROM
            (SELECT 
                w_name AS `Працівник`,
                    TO_DAYS(NOW()) - TO_DAYS(w_employment_date) - ROUND((TO_DAYS(NOW()) - TO_DAYS(w_employment_date)) / 365.25 * 104, 0) AS 'Якість'
            FROM
                workers
            WHERE
                w_firing_date IS NULL
            GROUP BY 1
            ORDER BY 2 DESC
            LIMIT 1) AS temp);

 
-- 14 товар на складі по виробниках
SELECT 
    m_name AS `Виробник`,
    SUM(sup_val) - SUM(sel_val) AS `На складі`
FROM
    (SELECT 
        g_m_id,
            g_id,
            IF(sel_sum IS NULL, 0, sel_sum) AS sel_val,
            SUM(s_units_amount) AS sup_val
    FROM
        supplies
    JOIN goods ON (s_g_id = g_id)
    LEFT JOIN (SELECT 
        sel_g_id, SUM(sel_units_amount) AS sel_sum
    FROM
        selling
    GROUP BY 1) AS temp1 ON (sel_g_id = g_id)
    GROUP BY 2) AS temp
        JOIN
    manufacturers ON (g_m_id = m_id)
GROUP BY 1
ORDER BY 2 DESC;
    
    
-- 15 кількість поставок у відділ (рейтинг)
SELECT 
    d_name AS 'Назва відділу',
    COUNT(DISTINCT i_id) AS 'Кількість поставок',
    SUM(s_units_amount) AS 'Кількість одиниць'
FROM
    invoice
        JOIN
    supplies ON (i_id = s_i_id)
        JOIN
    goods ON (s_g_id = g_id)
        JOIN
    departments ON (g_d_id = d_id)
GROUP BY 1
ORDER BY 2 DESC , 3 DESC;