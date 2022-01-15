--=============== МОДУЛЬ 6. POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Напишите SQL-запрос, который выводит всю информацию о фильмах 
--со специальным атрибутом "Behind the Scenes".

explain analyze
select
	film_id
	,title 
	,special_features 
from film f 
where f.special_features @> array['Behind the Scenes']
--Seq Scan on film f  (cost=0.00..67.50 rows=538 width=78) (actual time=0.014..0.437 rows=538 loops=1)
select pg_typeof(special_features) from film f;

--ЗАДАНИЕ №2
--Напишите еще 2 варианта поиска фильмов с атрибутом "Behind the Scenes",
--используя другие функции или операторы языка SQL для поиска значения в массиве.

explain analyze
select film_id, title, special_features
from film f 
where special_features && array['Behind the Scenes'];
--Seq Scan on film f  (cost=0.00..67.50 rows=538 width=78) (actual time=0.011..0.495 rows=538 loops=1)

explain analyze
select film_id, title, special_features
from film f 
where array_position(special_features, 'Behind the Scenes') > 0;
--Seq Scan on film f  (cost=0.00..70.00 rows=333 width=78) (actual time=0.017..0.457 rows=538 loops=1)

explain analyze
select film_id, title, special_features
from film 
where special_features::text ilike '%Behind the Scenes%';
--Seq Scan on film  (cost=0.00..72.50 rows=1 width=78) (actual time=0.022..1.572 rows=538 loops=1)

explain analyze
select film_id, title, special_features
from film f 
where 'Behind the Scenes' = any(special_features);
--Seq Scan on film f  (cost=0.00..77.50 rows=538 width=78) (actual time=0.011..0.416 rows=538 loops=1)

explain analyze
select film_id, title, special_features 
from film f 
where 'Behind the Scenes' = all(special_features);
--Seq Scan on film f  (cost=0.00..77.50 rows=69 width=78) (actual time=0.028..0.375 rows=70 loops=1)

--ЗАДАНИЕ №3
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов 
--со специальным атрибутом "Behind the Scenes.

--Обязательное условие для выполнения задания: используйте запрос из задания 1, 
--помещенный в CTE. CTE необходимо использовать для решения задания.

explain analyze
with bts_films as (
	select * from film f 
	where f.special_features @> array['Behind the Scenes']
	)
select
	c.customer_id,
	count(r.rental_id) rent_count
from customer c 
join rental r using(customer_id)
join inventory i using(inventory_id)
join bts_films bf using(film_id)
group by c.customer_id
order by c.customer_id;
--Sort  (cost=855.41..856.91 rows=599 width=12) (actual time=9.403..9.435 rows=599 loops=1)

--ЗАДАНИЕ №4
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов
-- со специальным атрибутом "Behind the Scenes".

--Обязательное условие для выполнения задания: используйте запрос из задания 1,
--помещенный в подзапрос, который необходимо использовать для решения задания.

explain analyze
select
	c.customer_id,
	count(r.rental_id) rent_count
from customer c 
join rental r using(customer_id)
join inventory i using(inventory_id)
join (select * from film f where f.special_features @> array['Behind the Scenes']) 
	bf using(film_id)
group by c.customer_id
order by c.customer_id;
--Sort  (cost=719.26..720.75 rows=599 width=12) (actual time=12.069..12.095 rows=599 loops=1)

--ЗАДАНИЕ №5
--Создайте материализованное представление с запросом из предыдущего задания
--и напишите запрос для обновления материализованного представления

create materialized view bts_rent_count_by_customer as
select
	c.customer_id,
	count(r.rental_id) rent_count
from customer c 
join rental r using(customer_id)
join inventory i using(inventory_id)
join (select * from film f 
	where f.special_features @> array['Behind the Scenes']) bf using(film_id)
group by c.customer_id
order by c.customer_id;

refresh materialized view bts_rent_count_by_customer;

--ЗАДАНИЕ №6
--С помощью explain analyze проведите анализ скорости выполнения запросов
-- из предыдущих заданий и ответьте на вопросы:

--1. Каким оператором или функцией языка SQL, используемых при выполнении домашнего задания, 
--   поиск значения в массиве происходит быстрее

--Оператор '@>' '&&' и имеет наименьший cost 

--2. какой вариант вычислений работает быстрее: 
--   с использованием CTE или с использованием подзапроса

-- CTE(actual time=9.403..9.435)< подзапроса(actual time=12.069..12.095)
-- CTE быстрее

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выполняйте это задание в форме ответа на сайте Нетологии
--Сделайте explain analyze этого запроса.

/*
Unique  (cost=8599.88..8600.22 rows=46 width=44) (actual time=33.747..34.944 rows=600 loops=1)
  ->  Sort  (cost=8599.88..8599.99 rows=46 width=44) (actual time=33.746..34.132 rows=8632 loops=1)
        Sort Key: (count(r.inventory_id) OVER (?)) DESC, ((((cu.first_name)::text || ' '::text) || (cu.last_name)::text))
        Sort Method: quicksort  Memory: 1058kB
        ->  WindowAgg  (cost=8597.57..8598.61 rows=46 width=44) (actual time=24.075..29.153 rows=8632 loops=1)
              ->  Sort  (cost=8597.57..8597.69 rows=46 width=21) (actual time=24.054..25.199 rows=8632 loops=1)
                    Sort Key: cu.customer_id
                    Sort Method: quicksort  Memory: 1057kB
                    ->  Nested Loop Left Join  (cost=8212.35..8596.30 rows=46 width=21) (actual time=6.100..21.724 rows=8632 loops=1)
                          ->  Hash Right Join  (cost=8212.07..8582.70 rows=46 width=6) (actual time=6.085..10.312 rows=8632 loops=1)
                                Hash Cond: (r.inventory_id = inv.inventory_id)
                                ->  Seq Scan on rental r  (cost=0.00..310.44 rows=16044 width=6) (actual time=0.006..1.390 rows=16044 loops=1)
                                ->  Hash  (cost=8211.50..8211.50 rows=46 width=4) (actual time=6.073..6.073 rows=2494 loops=1)
                                      Buckets: 4096 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 120kB
                                      ->  Subquery Scan on inv  (cost=77.50..8211.50 rows=46 width=4) (actual time=0.513..5.798 rows=2494 loops=1)
                                            Filter: (inv.sf_string ~~ '%Behind the Scenes%'::text)
                                            Rows Removed by Filter: 7274
                                            ->  ProjectSet  (cost=77.50..2485.25 rows=458100 width=712) (actual time=0.511..4.658 rows=9768 loops=1)
                                                  ->  Hash Full Join  (cost=77.50..160.39 rows=4581 width=63) (actual time=0.508..1.754 rows=4623 loops=1)
                                                        Hash Cond: (i.film_id = f.film_id)
                                                        ->  Seq Scan on inventory i  (cost=0.00..70.81 rows=4581 width=6) (actual time=0.008..0.350 rows=4581 loops=1)
                                                        ->  Hash  (cost=65.00..65.00 rows=1000 width=63) (actual time=0.494..0.494 rows=1000 loops=1)
                                                              Buckets: 1024  Batches: 1  Memory Usage: 104kB
                                                              ->  Seq Scan on film f  (cost=0.00..65.00 rows=1000 width=63) (actual time=0.008..0.326 rows=1000 loops=1)
                          ->  Index Scan using customer_pkey on customer cu  (cost=0.28..0.30 rows=1 width=17) (actual time=0.001..0.001 rows=1 loops=8632)
                                Index Cond: (r.customer_id = customer_id)
Planning time: 0.453 ms
Execution time: 35.220 ms
*/

--Основываясь на описании запроса, найдите узкие места и опишите их.

/*
             ->  Sort  (cost=8597.57..8597.69 rows=46 width=21) (actual time=24.045..24.866 rows=8632 loops=1)
                    Sort Key: cu.customer_id
                    Sort Method: quicksort  Memory: 1057kB
                    ->  Nested Loop Left Join  (cost=8212.35..8596.30 rows=46 width=21) (actual time=5.898..21.395 rows=8632 loops=1)
                          ->  Hash Right Join  (cost=8212.07..8582.70 rows=46 width=6) (actual time=5.878..10.004 rows=8632 loops=1)
                                Hash Cond: (r.inventory_id = inv.inventory_id)
                                ->  Seq Scan on rental r  (cost=0.00..310.44 rows=16044 width=6) (actual time=0.008..1.375 rows=16044 loops=1)
                                ->  Hash  (cost=8211.50..8211.50 rows=46 width=4) (actual time=5.865..5.865 rows=2494 loops=1)
                                      Buckets: 4096 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 120kB
 */
-- Затруднения начинаются на join-ах когда помещаются для сортировки в hash таблицу

--Сравните с вашим запросом из основной части (если ваш запрос изначально укладывается в 15мс — отлично!).

--Сделайте построчное описание explain analyze на русском языке оптимизированного запроса. 
--Описание строк в explain.

explain analyze
with bts_films as (
	select * from film f 
	where f.special_features @> array['Behind the Scenes']
	)
select
	c.customer_id,
	count(r.rental_id) rent_count
from customer c 
join rental r using(customer_id)
join inventory i using(inventory_id)
join bts_films bf using(film_id)
group by c.customer_id
order by c.customer_id;
--Сканирование Seq -> Хэш -> CTE Scan on(Операция сканирует на операцию...чего там) -> Хэш-соединение -> Хешагрегировать -> Фильтр и Сортировка


--Задание 2. Используя оконную функцию, выведите для каждого сотрудника сведения о первой его продаже.

with first_rent_by_staff as (
select 
	s.staff_id
	,f.film_id 
	,f.title 
	,p.amount 
	,p.payment_date 
	,c.first_name customer_first_name
	,c.last_name customer_last_name
	,first_value (r.rental_date) over (partition by s.staff_id order by p.payment_date) first_rent
	,row_number ()over (partition by s.staff_id) row_numb
from rental r 
join staff s on s.staff_id = r.staff_id
join inventory i on i.inventory_id= r.inventory_id
join film f on f.film_id = i.film_id
join payment p on p.rental_id = r.rental_id
join customer c on c.customer_id = r.customer_id)
select 
	staff_id
	,film_id 
	,title 
	,amount
	,payment_date 
	,customer_first_name
	,customer_last_name
from first_rent_by_staff fr
where fr.row_numb = 1;

--Задание 3. Для каждого магазина определите и выведите одним SQL-запросом следующие аналитические показатели:
--день, в который арендовали больше всего фильмов (в формате год-месяц-день);
--количество фильмов, взятых в аренду в этот день;
--день, в который продали фильмов на наименьшую сумму (в формате год-месяц-день);
--сумму продажи в этот день.





