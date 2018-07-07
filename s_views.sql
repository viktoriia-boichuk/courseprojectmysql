use supermarket;

-- якість продажу по виробниках і їхніх товарах
CREATE OR REPLACE VIEW sel_sup_manufacturers AS
    SELECT 
        m_name AS `Виробник`,
        g_name AS `Назва товару`,
        val AS `Продано/Отримано`
    FROM
        manufacturers
            JOIN
        (SELECT 
            g_m_id,
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
        GROUP BY 2) AS temp2 ON (m_id = g_m_id)
            JOIN
        goods ON (goods.g_id = temp2.g_id)
    ORDER BY 1;

SELECT * FROM sel_sup_manufacturers;


-- за якою транзакцією здобуто найбільшу виручку і що тоді продалось
CREATE OR REPLACE VIEW most_expensive_transaction AS
    SELECT 
        g_name AS 'Назва товару',
        SUM(sel_units_amount) AS 'Кількість одиниць',
        g_retail_price AS 'Вартість одиниці',
        SUM(sel_units_amount) * g_retail_price AS 'Вартість'
    FROM
        goods
            JOIN
        selling ON (g_id = sel_g_id)
            JOIN
        (SELECT 
            t_id
        FROM
            (SELECT 
            t_id,
                SUM(sel_units_amount * g_retail_price) - IF(t_dc_id IS NOT NULL, SUM(sel_units_amount * g_retail_price) * dc_percentage / 100, 0) AS `Виручка`
        FROM
            discount_cards
        RIGHT JOIN transactions ON (t_dc_id = dc_id)
        JOIN selling ON (sel_t_id = t_id)
        JOIN goods ON (sel_g_id = g_id)
        GROUP BY 1) AS temp1
        HAVING MAX(`Виручка`)) AS temp2 ON (sel_t_id = t_id)
    GROUP BY 1;

SELECT * FROM most_expensive_transaction;


-- для кожної одиниці виміру кількість проданих і отриманих товарів
CREATE VIEW unit_of_measurement AS
    SELECT 
        g_unit_of_measurement AS 'Одиниця виміру',
        IF(SUM(val) IS NULL, 0, SUM(val)) AS 'Отримано',
        IF(SUM(sel_sum) IS NULL,
            0,
            SUM(sel_sum)) AS 'Продано'
    FROM
        (SELECT 
            g_id, SUM(s_units_amount) AS val, sel_sum
        FROM
            supplies
        JOIN goods ON (s_g_id = g_id)
        LEFT JOIN (SELECT 
            sel_g_id, SUM(sel_units_amount) AS sel_sum
        FROM
            selling
        GROUP BY 1) AS temp1 ON (g_id = sel_g_id)
        GROUP BY 1) AS temp2
            RIGHT JOIN
        goods ON (temp2.g_id = goods.g_id)
    GROUP BY 1
    ORDER BY 1;
    
SELECT * FROM unit_of_measurement;


-- для кожної поставки вибрати товар, який треба найшвидше продати (найменша тривалість реалізації від поставки до кінця терміну придатності)
CREATE OR REPLACE VIEW duration AS
    SELECT 
        i_id AS 'Поставка',
        g_name AS 'Товар',
        i_date_time AS 'Дата поставки',
        s_expiration_date AS 'Термін зберігання'
    FROM
        invoice
            JOIN
        supplies ON (i_id = s_i_id)
            JOIN
        goods ON (s_g_id = g_id)
    WHERE
        s_expiration_date IS NOT NULL
    GROUP BY 1
    HAVING MIN(TO_DAYS(s_expiration_date) - TO_DAYS(i_date_time))
    ORDER BY MIN(TO_DAYS(s_expiration_date) - TO_DAYS(i_date_time));

SELECT * FROM duration;


-- 5 виробників, останні товари яких були продані і в якій кількості
CREATE OR REPLACE VIEW five_last_sold_manufacturers AS
    SELECT 
        m_name AS 'Виробник',
        g_name AS 'Товар',
        SUM(sel_units_amount) AS 'Кількість',
        t_date_time AS 'Дата і час'
    FROM
        manufacturers
            JOIN
        goods ON (m_id = g_m_id)
            JOIN
        selling ON (g_id = sel_g_id)
            JOIN
        transactions ON (sel_t_id = t_id)
    GROUP BY 4 , 2
    ORDER BY t_date_time DESC
    LIMIT 5;

SELECT * FROM five_last_sold_manufacturers;


-- працівник, коли і на яку суму прийняв товар
CREATE OR REPLACE VIEW managers_invoices AS
    SELECT 
        CONCAT('Працівник ',
                `Працівник`,
                ' ',
                `Дата/Час`,
                ' прийняв товар на суму ',
                `Вартість поставки`) AS 'Результат'
    FROM
        (SELECT 
            `Працівник`,
                `Дата/Час`,
                SUM(`Вартість товару`) AS `Вартість поставки`
        FROM
            (SELECT 
            w_name AS `Працівник`,
                i_date_time AS `Дата/Час`,
                SUM(s_units_amount) * g_retail_price AS `Вартість товару`
        FROM
            workers
        JOIN invoice ON (w_id = i_w_id)
        JOIN supplies ON (i_id = s_i_id)
        JOIN goods ON (s_g_id = g_id)
        GROUP BY 1 , 2 , s_g_id) AS temp
        GROUP BY 1 , 2) AS result;
    
SELECT * FROM managers_invoices;


-- рейтинг покупців за кількістю і вартістю покупок
CREATE OR REPLACE VIEW clients_transactions AS
    SELECT 
        dc_client_name AS 'Клієнт',
        COUNT(DISTINCT t_id) AS 'Кількість покупок',
        SUM(sel_units_amount * g_retail_price) AS 'Вартість всіх покупок'
    FROM
        discount_cards
            JOIN
        transactions ON (dc_id = t_dc_id)
            JOIN
        selling ON (t_id = sel_t_id)
            JOIN
        goods ON (sel_g_id = g_id)
    GROUP BY 1
    ORDER BY 2 DESC , 3 DESC;

SELECT * FROM clients_transactions;


-- пік продажу (день) і які при цьому були продані товари
CREATE OR REPLACE VIEW sales_peak AS
    SELECT 
        g_name AS 'Товар',
        SUM(sel_units_amount) AS 'Кількість',
        g_retail_price AS 'Ціна за одиницю',
        SUM(sel_units_amount) * g_retail_price AS 'Вартість'
    FROM
        (SELECT 
            t_date_time, COUNT(t_id), COUNT(t_w_id)
        FROM
            transactions
        GROUP BY 1
        ORDER BY 3 DESC , 2 DESC
        LIMIT 1) AS temp
            JOIN
        transactions USING (t_date_time)
            JOIN
        selling ON (t_id = sel_t_id)
            JOIN
        goods ON (sel_g_id = g_id)
    GROUP BY 1;

SELECT * FROM sales_peak;


-- прострочені товари
CREATE OR REPLACE VIEW overdue_goods AS
    SELECT 
        CONCAT(g_name,
                ' в кількості ',
                amount,
                ' од.') AS 'Прострочені товари'
    FROM
        (SELECT 
            sel_g_id,
                s_units_amount - SUM(sel_units_amount) AS amount,
                s_expiration_date
        FROM
            (SELECT 
            s_g_id, s_units_amount, s_expiration_date, i_date_time
        FROM
            (SELECT 
            s_g_id AS good, MAX(s_i_id) AS in_id
        FROM
            supplies
        GROUP BY 1) AS temp1
        JOIN supplies ON (in_id = s_i_id AND good = s_g_id)
        JOIN invoice ON (in_id = i_id)
        WHERE
            s_expiration_date IS NOT NULL) AS temp2
        JOIN selling ON (s_g_id = sel_g_id)
        JOIN transactions ON (sel_t_id = t_id)
        WHERE
            t_date_time >= i_date_time
        GROUP BY 1) AS temp3
            JOIN
        goods ON (sel_g_id = g_id)
    WHERE
        amount > 0
            AND s_expiration_date < DATE(NOW());
            
SELECT * FROM overdue_goods;


-- скільки кожного товару (з останньої для нього поставки) продано по знижці
CREATE OR REPLACE VIEW goods_amount_by_dc AS
    SELECT 
        g_name AS 'Товар',
        i_date_time AS 'Від',
        ROUND(SUM(sel_units_amount) * 100 / s_units_amount,
                2) AS 'Частка, продана по знижці'
    FROM
        (SELECT 
            s_g_id, s_units_amount, i_date_time
        FROM
            (SELECT 
            s_g_id AS good, MAX(s_i_id) AS in_id
        FROM
            supplies
        GROUP BY 1) AS temp1
        JOIN supplies ON (in_id = s_i_id AND good = s_g_id)
        JOIN invoice ON (in_id = i_id)) AS temp2
            JOIN
        selling ON (s_g_id = sel_g_id)
            JOIN
        transactions ON (sel_t_id = t_id)
            JOIN
        goods ON (sel_g_id = g_id)
    WHERE
        t_date_time >= i_date_time
            AND t_dc_id IS NOT NULL
    GROUP BY 1;

SELECT * FROM goods_amount_by_dc;