USE supermarket;

-- покупець
create user 'buyer'@'%' identified by '1111';
grant select on supermarket.goods to 'buyer'@'%';
grant select on supermarket.manufacturers to 'buyer'@'%';
grant execute on function supermarket.good to 'buyer'@'%';


-- адміністратор
create user 'admin'@'%' identified by '1488';
grant insert, update, delete, select, execute on supermarket.* to 'admin'@'%';


-- касир
create user 'cashier'@'%' identified by '012345';
grant select on supermarket.goods to 'cashier'@'%';
grant select on supermarket.manufacturers to 'cashier'@'%';
grant select on supermarket.discount_cards to 'cashier'@'%';
grant select, insert on supermarket.selling to 'cashier'@'%';
grant select, insert on supermarket.transactions to 'cashier'@'%';
grant execute on function supermarket.cashiers_good to 'cashier'@'%';
grant execute on function supermarket.most_popular_client to 'cashier'@'%';
grant execute on procedure supermarket.prices to 'cashier'@'%';