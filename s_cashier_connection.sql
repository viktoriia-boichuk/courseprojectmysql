use supermarket;

insert into departments values (5, 'відділ5', 'закриті');

update departments set d_shelving_type = 'відкриті' where d_id = 2;

select * from departments;

select * from goods;

select * from manufacturers;

select * from discount_cards;

select * from selling;

select * from transactions;

select * from supplies;

delete from manufacturers where d_id = 1;

drop table goods;

drop function good;

call goods_sum_price ('2016-03-02');

call prices (1);

alter table discount_cards add column surname varchar(50);

CREATE TABLE test_table (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(10)
);

SET @`Кількість по №` = good (4);

insert into selling values (12, 5, 8, 6);

insert into transactions values (9, '2015-12-24 03:06:05', null, 6);

SET @`Найпопулярніший товар` = cashiers_good ('працівник1');  
SELECT @`Найпопулярніший товар`;

SET @`Клієнт` = most_popular_client ('працівник6');  
SELECT @`Клієнт`;