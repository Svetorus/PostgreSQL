/*
Задание 1. World-db.
В командной строке используя pg_restore.exe восстановите бэкап
базы world-db
Выполните запрос select * from country
*/
cd c:program files\postgresql\10\bin

pg_restore -h localhost -p 5433 -U postrges -d postrges "world-db.backup"

psql -h localhost -p 5433 -U postgres;

/*
Задание 2. Dvd-rental.
Напишите функцию, которая будет в виде аргументов принимать 
* две даты 
и в качестве результата возвращать 
** сумму продаж между этими датами, включая эти даты.
*/

drop function sum_sales;

create or replace function sum_sales(x date, y date,OUT fin numeric)
AS $$
begin 
	select sum(amount) from payment_new where payment_date::date <=x  and payment_date::date >=y 
	into fin;
end	
$$ LANGUAGE plpgsql;

select sum_sales('2007-02-16','2007-02-15')

--проверка
select sum(amount) from payment_new where payment_date::date <= '2007.02.16' and payment_date::date >= '2007.02.15'

/*
Задание 3. Dvd-rental.
Создайте таблицу not_active_customer со столбцами id, customer_id и not_active_date (дата создания записи)
Напишите триггерную функцию, которая будет срабатывать при изменении данных в таблице customer, 
если пользователь становится неактивным, то в таблицу not_active_customer должна добавиться запись об этом пользователе
*/

--Создание таблицы
drop table if exists not_active_customer cascade;
create table not_active_customer (
	id serial primary key,
	customer_id int4 references customer(customer_id) on update cascade on delete cascade,
	not_active_date timestamp NOT NULL DEFAULT now()
);

--Подготовка триггерной функции
create or replace function update_status_customer() returns trigger as $$
begin 
	if TG_OP = 'UPDATE' -- внутренняя переменная, создаваемая при создании триггера
		then insert into not_active_customer(customer_id, not_active_date)
			values(old.customer_id, now());
	end if;
	return new; -- надо сделать возврат или будет ошибка
end;
$$ language plpgsql

--Запись триггера
create trigger update_status
after update of active on customer
for each row execute function update_status_customer();

--проверка
update customer
set active=0
where customer_id=599;

--select * from not_active_customer nac ;
--
--select * from customer c ;

--select c.customer_id, c.first_name, c.last_name, c.active 
--from customer c where c.active = 1
--order by c.customer_id desc;
