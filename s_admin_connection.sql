use supermarket;

insert into departments values (5, 'відділ5', 'закриті');

update departments set d_shelving_type = 'відкриті' where d_id = 5;

select * from departments;

delete from departments where d_id = 5;

drop table goods;

drop function good;

call goods_sum_price ('2016-03-02');

select * from transactions;

alter table discount_cards add column surname varchar(50);

CREATE TABLE test_table (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(10)
);

SET @`Кількість по №` = good (4);
SELECT @`Кількість по №`;