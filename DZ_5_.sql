--=============== МОДУЛЬ 5. РАБОТА С POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Сделайте запрос к таблице payment и с помощью оконных функций добавьте вычисляемые колонки согласно условиям:
--Пронумеруйте все платежи от 1 до N по дате

select payment_date , row_number() over (order by p.payment_date)
from payment p;
 
--Пронумеруйте платежи для каждого покупателя, сортировка платежей должна быть по дате

select payment_id
	,customer_id
	,payment_date 
	,row_number() over (order by p.payment_date) payment
	,row_number() over (partition by p.customer_id order by p.payment_date) customer_payment
from payment p;

--Посчитайте нарастающим итогом сумму всех платежей для каждого покупателя, сортировка должна 
--быть сперва по дате платежа, а затем по сумме платежа от наименьшей к большей

select customer_id
	,payment_date 
	,sum(p.amount) over (partition by p.customer_id order by p.payment_date) payment_sum
from payment p;

--Пронумеруйте платежи для каждого покупателя по стоимости платежа от наибольших к меньшим 
--так, чтобы платежи с одинаковым значением имели одинаковое значение номера.
--Можно составить на каждый пункт отдельный SQL-запрос, а можно объединить все колонки в одном запросе.

select customer_id
	,payment_id
	,amount 
	,DENSE_RANK() over (partition by customer_id order by amount desc) payment_sum
from 
	payment p
order by customer_id;

--Можно составить на каждый пункт отдельный SQL-запрос, а можно объединить все колонки в одном запросе.

select customer_id 
	,payment_id
	, payment_date
	, row_number() over (order by p.payment_date)
	,row_number() over (partition by p.customer_id order by p.payment_date) customer_payment
	,sum(p.amount) over (partition by p.customer_id order by p.payment_date) payment_sum
	,DENSE_RANK() over (partition by customer_id order by amount desc) payment_sum
from payment p;

--ЗАДАНИЕ №2
--С помощью оконной функции выведите для каждого покупателя стоимость платежа и стоимость 
--платежа из предыдущей строки со значением по умолчанию 0.0 с сортировкой по дате.

select 
	customer_id
	,payment_id 
	,payment_date 
	,amount
	,lag(amount,1,0.) over (partition by customer_id order by payment_date)lag_amount
from 
	payment p;

--ЗАДАНИЕ №3
--С помощью оконной функции определите, на сколько каждый следующий платеж покупателя больше или меньше текущего.

--что не нужно можно закоментировать в select
SELECT customer_id
	,payment_id 
	,payment_date 
	,amount
	,lead(amount, 1, 0.) over (partition by customer_id order by payment_date) next_pay 
	,amount - lead(amount, 1, 0.) over (partition by customer_id order by payment_date) different
FROM payment p;

--ЗАДАНИЕ №4
--С помощью оконной функции для каждого покупателя выведите данные о его последней оплате аренды.
--1 = 5,99  2 = 4,99 3 = 2,99 4 = 1,99

with c1 as (
		select 
			payment_id
			,customer_id
			,payment_date
			,amount 
			,last_value(amount)over(partition by customer_id) last_rent
			,rank ()over (partition by customer_id order by payment_date desc) nr 
		from payment p)
select 
	payment_id
	,payment_date
	,last_rent
	,customer_id
from c1
where nr = 1;

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--С помощью оконной функции выведите для каждого сотрудника сумму продаж за август 2005 года 
--с нарастающим итогом по каждому сотруднику и по каждой дате продажи (без учёта времени) 
--с сортировкой по дате.

select distinct staff_id
	,to_char(date_trunc('day', payment_date), 'YYYY-MM-DD') payment_date
	,sum(amount) over (partition by staff_id,date_trunc('day', payment_date))
	,sum(amount) over (partition by staff_id order by date_trunc('day', payment_date)) Difference
from payment p 
where date_trunc('month', payment_date) = '2005-08-01'  
group by staff_id,payment_date,amount
order by staff_id;

--ЗАДАНИЕ №2
--20 августа 2005 года в магазинах проходила акция: покупатель каждого сотого платежа получал
--дополнительную скидку на следующую аренду. С помощью оконной функции выведите всех покупателей,
--которые в день проведения акции получили скидку

select customer_id 
	,payment_id
	,payment_date 
	,row_number() over (order by p.payment_id)%100=0 payment_num_ber
from payment p 
where payment_date::date = '2005-08-20';

--ЗАДАНИЕ №3
--Для каждой страны определите и выведите одним SQL-запросом покупателей, которые попадают под условия:
-- 1. покупатель, арендовавший наибольшее количество фильмов
-- 2. покупатель, арендовавший фильмов на самую большую сумму
-- 3. покупатель, который последним арендовал фильм

with finally as (
	with max_by_customer as(
		select distinct
			r.customer_id,
			c2.country_id,
			count(r.rental_id) over (partition by (r.customer_id)) max_rents,
			sum(p.amount) over (partition by (p.customer_id)) pay_amount,
			last_value(r.rental_id)  over (partition by (r.customer_id)) last_rent
		from customer c 
		inner join address a using(address_id)
		inner join city c2 using(city_id)
		inner join rental r on c.customer_id = r.customer_id 
		right join payment p on p.customer_id = c.customer_id 
	),
	max_by_country as (
		select
			mrc.country_id,
			max(mrc.max_rents) max_rent_count,
			max(mrc.pay_amount) max_pay_amount,
			max(mrc.last_rent) max_last_rent
		from max_by_customer mrc
		group by mrc.country_id
	)
	select distinct
		c3.country cnt,
		array_agg(mc1.customer_id) ma, 
		array_agg(mc2.customer_id) mp, 
		array_agg(mc3.customer_id) la
	from country c3 
	join max_by_country mc0 on c3.country_id = mc0.country_id
	join max_by_customer mc1 on mc0.country_id = mc1.country_id and mc0.max_rent_count = mc1.max_rents
	join max_by_customer mc2 on mc0.country_id = mc1.country_id and mc0.max_pay_amount = mc2.pay_amount
	join max_by_customer mc3 on mc0.country_id = mc1.country_id and mc0.max_last_rent = mc3.last_rent
	group by c3.country
)
select 
	cnt "Страна",
	array(select distinct * from unnest(ma)) "Макс аренд",
	array(select distinct * from unnest(mp)) "Макс платеж",
	array(select distinct * from unnest(la)) "Последняя аренда"
from finally;


