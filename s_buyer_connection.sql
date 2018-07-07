use supermarket;

CREATE TEMPORARY TABLE test_table (
    tt_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    tt_name VARCHAR(10)
);

insert into departments values (5, 'відділ5', 'з охолодженням');

alter table goods add column surname varchar(10);

SELECT * FROM goods;

SELECT 
    g_name, m_name
FROM
    goods
        JOIN
    manufacturers ON (g_m_id = m_id);

DROP TABLE manufacturers;

SET @var = good(3);
SELECT @var;