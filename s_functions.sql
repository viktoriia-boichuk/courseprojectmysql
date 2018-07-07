use supermarket;

-- кількість одиниць вказаного товару на складі
DELIMITER |
CREATE FUNCTION good (id INT)
RETURNS INT
BEGIN
RETURN (SELECT 
		IF(SUM(s_units_amount) IS NULL, 0, SUM(s_units_amount)) - 
        IF(sel_sum IS NULL, 0, sel_sum) AS remainder
	FROM
		supplies
			RIGHT JOIN
		goods ON (s_g_id = g_id)
			LEFT JOIN
		(SELECT 
			sel_g_id, SUM(sel_units_amount) AS sel_sum
		FROM
			selling
		GROUP BY 1) AS temp1 ON (g_id = sel_g_id)
	WHERE
		g_id = id
	GROUP BY g_id);
END |
DELIMITER ;

SET @`Кількість по №` = good (4);
SELECT @`Кількість по №`;


-- для касира товар, який він найчастіше продає
DELIMITER |
CREATE FUNCTION cashiers_good (cashier VARCHAR(100))
RETURNS VARCHAR(100)
BEGIN
RETURN (SELECT g_name 
FROM
	(SELECT 
		g_name, MAX(tr_amount), MAX(sel_amount)
	FROM
		workers
			JOIN
		(SELECT 
			t_w_id, sel_g_id, COUNT(DISTINCT t_id) AS tr_amount
		FROM
			transactions
		JOIN selling ON (t_id = sel_t_id)
		GROUP BY 1 , 2) AS temp1 ON (w_id = temp1.t_w_id)
			JOIN
		(SELECT 
			t_w_id AS worker,
				sel_g_id AS good,
				SUM(sel_units_amount) AS sel_amount
		FROM
			transactions
		JOIN selling ON (t_id = sel_t_id)
		GROUP BY 1 , 2
		ORDER BY 1) AS temp2 ON (sel_g_id = good AND t_w_id = worker)
			JOIN
		goods ON (temp1.sel_g_id = g_id)
		WHERE w_name = cashier
		GROUP BY 1
		ORDER BY 3 DESC, 2 DESC
		LIMIT 1) AS result);
END |
DELIMITER ;

SET @`Найпопулярніший товар` = cashiers_good ('працівник1');  
SELECT @`Найпопулярніший товар`;


-- на яку суму є товарів зараз у відділі
DELIMITER |
CREATE FUNCTION balance_of_goods (department VARCHAR(50))
RETURNS DECIMAL (9, 2)
BEGIN
RETURN (SELECT 
		SUM(`Залишок`)
	FROM
		(SELECT 
			d_name,
				g_id,
				(IF(SUM(s_units_amount) IS NULL, 0, SUM(s_units_amount)) - IF(sel_sum IS NULL, 0, sel_sum)) * g_retail_price AS `Залишок`
		FROM
			supplies
		RIGHT JOIN goods ON (s_g_id = g_id)
		LEFT JOIN (SELECT 
			sel_g_id, SUM(sel_units_amount) AS sel_sum
		FROM
			selling
		GROUP BY 1) AS temp1 ON (g_id = sel_g_id)
		JOIN departments ON (g_d_id = d_id)
		GROUP BY 2) AS temp2
	WHERE
		d_name = department
	GROUP BY d_name);
END |
DELIMITER ;
    
SET @`Залишок товару` = balance_of_goods ('відділ2');  
SELECT @`Залишок товару`;


-- "втрачений" прибуток за період
DELIMITER |
CREATE FUNCTION lost_income (begin_date DATE, end_date DATE)
RETURNS DECIMAL (9, 2)
BEGIN
RETURN (SELECT 
		SUM(lost)
	FROM
		(SELECT 
			t_id,
				g_id,
				g_retail_price * SUM(sel_units_amount) - ROUND(g_retail_price * SUM(sel_units_amount) - g_retail_price * SUM(sel_units_amount) / 100 * dc_percentage, 2) AS lost
		FROM
			goods
		JOIN selling ON (sel_g_id = g_id)
		JOIN transactions ON (sel_t_id = t_id)
		JOIN discount_cards ON (t_dc_id = dc_id)
		WHERE
			DATE(t_date_time) BETWEEN begin_date AND end_date
		GROUP BY 1 , 2) AS temp);
END |
DELIMITER ;

SET @`Втрачено` = lost_income ('2016-01-01', '2016-12-31');  
SELECT @`Втрачено`;


-- товар, який продається найменше
DELIMITER |
CREATE FUNCTION worth_sold_good ()
RETURNS VARCHAR(100)
BEGIN
RETURN (SELECT 
		g_name
	FROM
		(SELECT 
			g_name,
				SUM(s_units_amount) AS sup,
				IF(sel_sum IS NULL, 0, sel_sum) AS sold,
				IF(sel_sum IS NULL, 0, sel_sum) / SUM(s_units_amount) AS quality
		FROM
			supplies
		JOIN goods ON (s_g_id = g_id)
		LEFT JOIN (SELECT 
			sel_g_id, SUM(sel_units_amount) AS sel_sum
		FROM
			selling
		GROUP BY 1) AS temp1 ON (g_id = sel_g_id)
		GROUP BY 1
		ORDER BY quality
		LIMIT 1) AS almost);
END |
DELIMITER ;

SET @`Товар` = worth_sold_good ();
SELECT @`Товар`; 


-- на яку суму продали товар вказаного відділу у вказаний день
DELIMITER |
CREATE FUNCTION sold_goods_by_dd (tr_date DATE, department VARCHAR(50))
RETURNS DECIMAL (9, 2)
BEGIN
RETURN (SELECT 
		SUM(`Продано`)
	FROM
		(SELECT 
			d_name,
				g_id,
				SUM(sel_units_amount) * g_retail_price AS `Продано`
		FROM
			departments
		JOIN goods ON (g_d_id = d_id)
		JOIN selling ON (g_id = sel_g_id)
		JOIN transactions ON (sel_t_id = t_id)
		WHERE
			DATE(t_date_time) = tr_date
				AND d_name = department
		GROUP BY 2) AS temp
	GROUP BY d_name);
END |
DELIMITER ;

SET @`На суму` = sold_goods_by_dd ('2016-03-02', 'відділ2');  
SELECT @`На суму`;


-- найпопулярніший покупець у вказаного касира
DELIMITER |
CREATE FUNCTION most_popular_client (cashier VARCHAR(100))
RETURNS VARCHAR(100)
BEGIN
RETURN (SELECT 
		CONCAT('Для касира ', cashier, ' найчастішим покупцем є ', dc_client)
	FROM
		(SELECT 
			w_name, dc_client_name AS dc_client, COUNT(t_dc_id)
		FROM
			discount_cards
		JOIN transactions ON (dc_id = t_dc_id)
		JOIN workers ON (t_w_id = w_id)
		WHERE
			w_name = cashier
		GROUP BY 1 , 2
		ORDER BY 3
		LIMIT 1) AS temp);
END |
DELIMITER ;

SET @`Клієнт` = most_popular_client ('Артеменко Дмитро Ілліч');  
SELECT @`Клієнт`;


-- прибуток за період
DELIMITER |
CREATE FUNCTION number_one (begin_date DATE, end_date DATE)
RETURNS DECIMAL (9, 2) 
BEGIN
RETURN (SELECT 
		SUM(sold - income)
	FROM
		(SELECT 
			t_id,
				g_name,
				IF(t_dc_id IS NULL, g_retail_price * SUM(sel_units_amount), ROUND(g_retail_price * SUM(sel_units_amount) - g_retail_price * SUM(sel_units_amount) / 100 * dc_percentage, 2)) AS sold,
				ROUND(avg_price * SUM(sel_units_amount), 2) AS income
		FROM
			(SELECT 
			s_g_id, AVG(s_purchase_price) AS avg_price
		FROM
			invoice
		JOIN supplies ON (i_id = s_i_id)
		LEFT JOIN (SELECT 
			s_g_id, MAX(i_date_time) AS first_supply_date
		FROM
			invoice
		JOIN supplies ON (i_id = s_i_id)
		WHERE
			i_date_time < begin_date
		GROUP BY 1) AS temp1 USING (s_g_id)
		WHERE
			i_date_time BETWEEN IF(first_supply_date IS NULL, begin_date, first_supply_date) AND end_date
		GROUP BY 1) AS temp2
		JOIN goods ON (s_g_id = g_id)
		JOIN selling ON (sel_g_id = g_id)
		JOIN transactions ON (sel_t_id = t_id)
		LEFT JOIN discount_cards ON (t_dc_id = dc_id)
		WHERE
			DATE(t_date_time) BETWEEN begin_date AND end_date
		GROUP BY 1 , 2) AS almost_result);
END |
DELIMITER ;

SET @`Прибуток` = number_one('2016-01-01', '2016-12-31');
SELECT @`Прибуток`;
    

-- скільки товарів знаходяться на даний момент на заданому типі стелажів
DELIMITER |
CREATE FUNCTION goods_amount (shelf VARCHAR(14))
RETURNS INT
BEGIN
RETURN (SELECT 
		IF(sup IS NULL, 0, sup) - sold
		FROM
		(SELECT 
			SUM(s_units_amount) AS sup
		FROM
			departments
		LEFT JOIN goods ON (d_id = g_d_id)
		LEFT JOIN supplies ON (g_id = s_g_id)
		WHERE
			d_shelving_type = shelf
		GROUP BY d_shelving_type) AS temp,
		(SELECT 
			SUM(IF(sel_sum IS NULL, 0, sel_sum)) AS sold
		FROM
			departments
		LEFT JOIN goods ON (d_id = g_d_id)
		LEFT JOIN (SELECT 
			sel_g_id, SUM(sel_units_amount) AS sel_sum
		FROM
			selling
		GROUP BY 1) AS temp1 ON (g_id = sel_g_id)
		WHERE
			d_shelving_type = shelf
		GROUP BY d_shelving_type) AS temp2);
END |
DELIMITER ;

SET @`Кількість товарів` = goods_amount('з охолодженням');
SELECT @`Кількість товарів`;


-- скільки днів тому востаннє продався вказаний товар
DELIMITER |
CREATE FUNCTION when_last_sold (good VARCHAR(100))
RETURNS VARCHAR(16)
BEGIN
RETURN (SELECT 
		IF(MAX(t_date_time) IS NULL,
			'Ще не продавався',
			TO_DAYS(NOW()) - TO_DAYS(MAX(t_date_time)))
	FROM
		goods
			LEFT JOIN
		selling ON (g_id = sel_g_id)
			LEFT JOIN
		transactions ON (sel_t_id = t_id)
	WHERE
		g_name = good
	GROUP BY g_id);
END |
DELIMITER ;

SET @`Востаннє продався` = when_last_sold ('товар3');
SELECT @`Востаннє продався`;