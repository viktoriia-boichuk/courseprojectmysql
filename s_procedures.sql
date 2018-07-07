use supermarket;

-- сумарна вартість кожного з товарів, проданих вказаного числа
DELIMITER |
CREATE PROCEDURE goods_sum_price (sold_date date)
BEGIN
SELECT 
    g_name AS 'Назва товару', g_barcode AS 'Штрих-код', SUM(sel_units_amount) * g_retail_price AS 'Сумарна вартість'
FROM
    goods
        JOIN
    selling ON (sel_g_id = g_id)
        JOIN
    transactions ON (sel_t_id = t_id)
WHERE
    DATE(t_date_time) = sold_date
GROUP BY 1;
END |
DELIMITER ;

CALL goods_sum_price ('2015-06-18');


-- кількість товарів заданої цінової категорії по відділах
DELIMITER |
CREATE PROCEDURE goods_price_category (price DECIMAL(9, 2))
BEGIN
SELECT 
    d_name AS 'Відділ',
    COUNT(g_name) AS 'Кількість товарів'
FROM
    departments
        JOIN
    goods ON (d_id = g_d_id)
WHERE
    g_retail_price IN (SELECT 
            g_retail_price
        FROM
            goods
        WHERE
            g_retail_price BETWEEN price - 2 AND price + 2)
GROUP BY 1
ORDER BY 1;
END |
DELIMITER ;

CALL goods_price_category (10);


-- в які дні найчастіше вказаний працівник приймає поставки
DELIMITER |
CREATE PROCEDURE most_often (worker_name VARCHAR(100))
BEGIN
DECLARE biggest_value INT;
DECLARE finished NUMERIC(1); 
DECLARE my_cursor CURSOR for
SELECT 
    COUNT(WEEKDAY(i_date_time))
FROM
    invoice JOIN 
    workers ON (i_w_id=w_id)
where w_name = worker_name
GROUP BY WEEKDAY(i_date_time)
ORDER BY WEEKDAY(i_date_time)
LIMIT 1;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;
set finished = 0;
OPEN my_cursor;
    FETCH my_cursor INTO biggest_value; 
    WHILE( finished != 1) DO 
		SELECT CASE WEEKDAY(i_date_time)
			WHEN 0 THEN 'Понеділок'
			WHEN 1 THEN 'Вівторок'
			WHEN 2 THEN 'Середа'
			WHEN 3 THEN 'Четвер'
			WHEN 4 THEN 'П\'ятниця'
			WHEN 5 THEN 'Субота'
			WHEN 6 THEN 'Неділя'
		END AS 'День тижня',
		COUNT(i_date_time) AS 'Кількість поставок'
		FROM
			workers JOIN
			invoice ON (w_id = i_w_id)
		WHERE w_name = worker_name
		GROUP BY 1
        HAVING COUNT(i_date_time) = biggest_value
		ORDER BY WEEKDAY(i_date_time);
		FETCH my_cursor INTO biggest_value;
	END WHILE;
    CLOSE my_cursor;
END |
DELIMITER ;

CALL most_often('Думайло Денис Романович');


-- топ Х товарів, куплених по вказаній дисконтній картці
DELIMITER |
CREATE PROCEDURE top_X_goods_by_dc (X INT, dc INT)
BEGIN
SELECT 
    g_name AS 'Назва товару',
    g_barcode AS 'Штрих-код',
    m_name AS 'Виробник',
    SUM(sel_units_amount) AS 'Кількість придбаних одиниць'
FROM
    discount_cards
        JOIN
    transactions ON (dc_id = t_dc_id)
        JOIN
    selling ON (t_id = sel_t_id)
        JOIN
    goods ON (sel_g_id = g_id)
        JOIN
    manufacturers ON (m_id = g_m_id)
WHERE
    dc_id = dc
GROUP BY 1
ORDER BY 4 DESC
LIMIT X;
END |
DELIMITER ;

CALL top_X_goods_by_dc (5, 1);


-- залишок товару по відділах
DELIMITER |
CREATE PROCEDURE remainder_by_departments (department VARCHAR(50))
BEGIN
SELECT 
    g_name AS 'Назва товару',
    g_barcode AS 'Штрих-код',
    g_category AS 'Категорія',
    SUM(s_units_amount) - IF(sel_sum IS NULL, 0, sel_sum) AS 'Залишок'
FROM
    supplies
        JOIN
    goods ON (s_g_id = g_id)
        LEFT JOIN
    (SELECT 
        sel_g_id, SUM(sel_units_amount) AS sel_sum
    FROM
        selling
    GROUP BY 1) AS temp1 ON (sel_g_id = g_id)
        JOIN
    departments ON (g_d_id = d_id)
WHERE
    d_name = department
GROUP BY 1
ORDER BY 1;
END |
DELIMITER ;

CALL remainder_by_departments ('бакалія');


-- для вказаної транзакції вивести вартість кожного товару без і зі знижкою
DELIMITER |
CREATE PROCEDURE prices (transaction_number INT)
BEGIN
SELECT 
    g_name AS 'Товар',
    g_retail_price AS 'Роздрібна ціна',
    sel_amount AS 'Кількість одиниць',
    sum_price AS 'Загальна ціна',
    sale_price AS 'Ціна зі знижкою',
    sale_price * sel_amount AS 'Загальна ціна'
FROM
    (SELECT 
        g_name,
            SUM(sel_units_amount) AS sel_amount,
            g_retail_price,
            SUM(sel_units_amount) * g_retail_price AS sum_price,
            ROUND(IF(t_dc_id IS NULL, g_retail_price, g_retail_price - g_retail_price / 100 * dc_percentage), 2) AS sale_price
    FROM
        discount_cards
    RIGHT JOIN transactions ON (dc_id = t_dc_id)
    JOIN selling ON (t_id = sel_t_id)
    JOIN goods ON (sel_g_id = g_id)
    WHERE
        sel_t_id = transaction_number
    GROUP BY 1) AS temp;
END |
DELIMITER ;

CALL prices (2);


-- найуспішніший касир (кількість транзакцій до тривалості роботи (в днях мінус вихідні))
DELIMITER |
CREATE PROCEDURE best_cashier(holidays INT)
BEGIN
SELECT 
    worker AS 'Працівник',
    MAX(tr_amount / (work_days - weekends - holidays)) AS 'Якість'
FROM
    (SELECT 
        w_name AS worker,
            COUNT(t_id) AS tr_amount,
            TO_DAYS(NOW()) - TO_DAYS(w_employment_date) AS work_days,
            ROUND((TO_DAYS(NOW()) - TO_DAYS(w_employment_date)) / 365.25 * 104, 0) AS weekends
    FROM
        workers
    JOIN transactions ON (w_id = t_w_id)
    WHERE
        w_firing_date IS NULL
    GROUP BY 1) AS temp;
END |
DELIMITER ;

CALL best_cashier (30);


-- перелік категорій і кількість їх товарів для вказаного відділу
DELIMITER |
CREATE PROCEDURE department_categories (department VARCHAR (50))
BEGIN
SELECT 
    g_category AS 'Категорія',
    SUM(`Отримано`) - SUM(`Продано`) AS 'Залишок'
FROM
    (SELECT 
        g_id,
            SUM(s_units_amount) AS `Отримано`,
            IF(sel_sum IS NULL, 0, sel_sum) AS `Продано`
    FROM
        supplies
    JOIN goods ON (s_g_id = g_id)
    LEFT JOIN (SELECT 
        sel_g_id, SUM(sel_units_amount) AS sel_sum
    FROM
        selling
    GROUP BY 1) AS temp1 ON (g_id = sel_g_id)
    GROUP BY 1) AS temp2
        JOIN
    goods ON (goods.g_id = temp2.g_id)
        JOIN
    departments ON (g_d_id = d_id)
WHERE
    d_name = department
GROUP BY 1
ORDER BY 1;
END |
DELIMITER ;

CALL department_categories('напої');


-- до введеної категорії товарів вивести всі дати поставок
DELIMITER |
CREATE PROCEDURE goods_categories_invoices (category VARCHAR (30))
BEGIN
SELECT 
    i_id AS 'Номер поставки',
    i_date_time AS 'Дата поставки',
    SUM(s_units_amount) AS 'Кількість товарів'
FROM
    invoice
        JOIN
    supplies ON (i_id = s_i_id)
        JOIN
    goods ON (g_id = s_g_id)
WHERE
    g_category = category
GROUP BY 1;
END |
DELIMITER ;

CALL goods_categories_invoices ('Майонез');


-- оновити % знижки для покупця, в якого сумарна вартість транзакцій більша вказаної суми
DELIMITER |
CREATE PROCEDURE update_percentage (max_sum DECIMAL(9, 2))
BEGIN
UPDATE discount_cards 
SET 
    dc_percentage = dc_percentage + 1
WHERE
    dc_client_name = (SELECT 
            client_name
        FROM
            (SELECT 
                dc_client_name AS client_name,
                    SUM(sel_units_amount * g_retail_price) AS result
            FROM
                discount_cards
            JOIN transactions ON (dc_id = t_dc_id)
            JOIN selling ON (t_id = sel_t_id)
            JOIN goods ON (sel_g_id = g_id)
            GROUP BY 1
            HAVING result > max_sum
            ORDER BY 1) AS temp);
END |
DELIMITER ;

CALL update_percentage (400);