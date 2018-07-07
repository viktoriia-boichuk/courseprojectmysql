USE supermarket;

-- дата народження повинна бути більшою за дату прийняття на роботу,дата прийняття на роботу повинна бути більшою за дату звільнення
-- вік працівника не може бути меншим за 16 років
DELIMITER |
CREATE TRIGGER workers_dates AFTER INSERT ON workers
FOR EACH ROW 
BEGIN
IF new.w_birth_date>new.w_employment_date OR new.w_employment_date>new.w_firing_date 
OR YEAR(new.w_employment_date)-YEAR(new.w_birth_date)<=16
THEN
DELETE FROM workers WHERE NEW.w_birth_date>NEW.w_employment_date 
OR NEW.w_employment_date>NEW.w_firing_date
OR YEAR(NEW.w_employment_date)-YEAR(NEW.w_birth_date)<=16;
END IF;
END |
DELIMITER ;


-- тільки менеджери закупівлі можуть приймати товар по накладних, при чому лише після прийняття на роботу і до звільнення
DELIMITER |
CREATE TRIGGER invoice_workers AFTER INSERT ON invoice
FOR EACH ROW 
BEGIN
IF ((select w_job from workers where w_id=new.i_w_id)<>'менеджер закупівлі' or 
(select w_firing_date from workers where w_id=new.i_w_id)<date(new.i_date_time) or
(select w_employment_date from workers where w_id=new.i_w_id)>date(new.i_date_time))
THEN
DELETE FROM invoice WHERE i_w_id=new.i_w_id;
END IF;
END |
DELIMITER ;


-- тільки касири можуть здійснювати продаж, при чому лише після прийняття на роботу і до звільнення
DELIMITER |
CREATE TRIGGER transactions_workers AFTER INSERT ON transactions
FOR EACH ROW 
BEGIN
IF ((select w_job from workers where w_id=new.t_w_id)<>'касир' or 
(select w_firing_date from workers where w_id=new.t_w_id)<date(new.t_date_time) or
(select w_employment_date from workers where w_id=new.t_w_id)>date(new.t_date_time))
THEN
DELETE FROM transactions WHERE t_w_id=new.t_w_id;
END IF;
END |
DELIMITER ;


-- продаж тільки якщо є в наявності
DELIMITER |
CREATE TRIGGER only_if_available AFTER INSERT ON selling
FOR EACH ROW 
BEGIN
IF ((good(NEW.sel_g_id)+NEW.sel_units_amount)<NEW.sel_units_amount)
THEN
DELETE FROM selling WHERE sel_g_id=new.sel_g_id;
END IF;
END |
DELIMITER ;


-- дата зберігання не може бути меншою за дату накладної
DELIMITER |
CREATE TRIGGER invoice_and_expiration_date AFTER INSERT ON supplies
FOR EACH ROW 
BEGIN
IF ((SELECT i_date_time FROM invoice WHERE i_id=NEW.s_i_id)>NEW.s_expiration_date)
THEN
DELETE FROM supplies WHERE s_id=NEW.s_id;
END IF;
END |
DELIMITER ;


-- чим більша дата накладної, тим більший її номер
DELIMITER |
CREATE TRIGGER invoice_date_and_id AFTER INSERT ON invoice
FOR EACH ROW 
BEGIN
IF (NEW.i_date_time<(select i_date_time from invoice where new.i_id-i_id=1))
THEN
DELETE FROM invoice WHERE i_id=NEW.i_id;
END IF;
END |
DELIMITER ;


-- однією накладною один товар один раз
DELIMITER |
CREATE TRIGGER one_good_once AFTER INSERT ON supplies
FOR EACH ROW 
BEGIN
IF ((select count(s_g_id) from supplies where s_i_id=new.s_i_id and s_g_id=new.s_g_id)>1)
THEN
DELETE FROM supplies WHERE s_id=NEW.s_id;
END IF;
END |
DELIMITER ;


-- чим більша дата транзакції, тим більший її номер, працівник не може здійснювати 2 транзакції одночасно
DELIMITER |
CREATE TRIGGER transaction_date_and_id AFTER INSERT ON transactions
FOR EACH ROW 
BEGIN
IF (NEW.t_date_time<(select t_date_time from transactions where new.t_id-t_id=1) or 
(select count(t_date_time) from transactions where new.t_date_time=t_date_time and new.t_w_id=t_w_id)>1)
THEN
DELETE FROM transactions WHERE t_id=NEW.t_id;
END IF;
END |
DELIMITER ;