--=============== МОДУЛЬ 3. ОСНОВЫ SQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите для каждого покупателя его адрес проживания, город и страну проживания.

SET search_path TO public;

select 
	last_name ||' '|| first_name "Customer name",
	a.address,
	city,
	country
from customer c join address a
	USING(address_id)
	join city c2 
	USING(city_id)
	join country c3 
	USING(country_id);

--ЗАДАНИЕ №2
--С помощью SQL-запроса посчитайте для каждого магазина количество его покупателей.

select store_id, count(distinct customer_id)
from store s join customer c 
	using(store_id)
group by store_id;

--Доработайте запрос и выведите только те магазины, 
--у которых количество покупателей больше 300-от.
--Для решения используйте фильтрацию по сгруппированным строкам 
--с использованием функции агрегации.

select store_id, count(distinct customer_id)
from store s join customer c 
	using(store_id)
group by store_id
having count(distinct customer_id) >300;

-- Доработайте запрос, добавив в него информацию о городе магазина, 
--а также фамилию и имя продавца, который работает в этом магазине.

select 
	s.store_id "ID магазина" 
	,count(customer_id) "Количество покупателей"
	,c2.city "Город" 
	,s2.last_name ||' '|| s2.first_name "Имя сотрудника" 
from store s join customer c 
	using(store_id)
	join address a
	on a.address_id=s.address_id 
	join city c2 
	USING(city_id)
	left join staff s2 
	on s.store_id=s2.store_id
group by s.store_id,c2.city, s2.last_name,s2.first_name
having count(distinct customer_id) >300;

--ЗАДАНИЕ №3
--Выведите ТОП-5 покупателей, 
--которые взяли в аренду за всё время наибольшее количество фильмов

select 
	last_name ||' '|| first_name "Фамилия и имя покупателя",
	count(film_id) "Количество фильмов"
from customer c join rental r 
	using(customer_id)
	join inventory i 
	using(inventory_id)
group by c.last_name,c.first_name
order by "Количество фильмов" desc;

--ЗАДАНИЕ №4
--Посчитайте для каждого покупателя 4 аналитических показателя:
--  1. количество фильмов, которые он взял в аренду
--  2. общую стоимость платежей за аренду всех фильмов (значение округлите до целого числа)
--  3. минимальное значение платежа за аренду фильма
--  4. максимальное значение платежа за аренду фильма

select 
	last_name ||' '|| first_name "Фамилия и имя покупателя"
	,count(r.inventory_id ) "Количество фильмов"
	,round(sum(amount)) "Общая стоимость платежей"
	,min(amount) "Минимальная стоимость платежа"
	,max(amount) "Максимальная стоимость платежа"
from customer c left join rental r 
	on c.customer_id= r.customer_id
	left join payment p 
	on p.rental_id = r.rental_id	
group by c.last_name,c.first_name;

--ЗАДАНИЕ №5
--Используя данные из таблицы городов составьте одним запросом всевозможные пары городов таким образом,
 --чтобы в результате не было пар с одинаковыми названиями городов. 
 --Для решения необходимо использовать декартово произведение.
 
select a.city "Город 1", b.city "Город 2" 
from city a cross join city b 
where a.city <> b.city;

--ЗАДАНИЕ №6
--Используя данные из таблицы rental о дате выдачи фильма в аренду (поле rental_date)
--и дате возврата фильма (поле return_date), 
--вычислите для каждого покупателя среднее количество дней, за которые покупатель возвращает фильмы.
 
select 
	c.customer_id "ID покупателя"
	,round(avg(return_date::date -rental_date::date),2) "Среднее количество дней на возврат"
from customer c join rental r 
	using(customer_id)
	group by c.customer_id 
order by customer_id;

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Посчитайте для каждого фильма сколько раз его брали в аренду и значение общей стоимости аренды фильма за всё время.

select 
	title "Название фильма"
	,rating "Рейтинг"
	,c."name" "Жанр"
	,release_year "Год выпуска" 
	,l."name" "Язык"
	,count(r.inventory_id) "Количество аренд"
	,sum(p.amount)
from film f left join inventory i 
	on f.film_id = i.film_id 
	left join rental r 
	on i.inventory_id = r.inventory_id 
	left join payment p 
	on p.rental_id =r.rental_id
	left join film_category fc 
	on fc.film_id =f.film_id 
	left join category c 
	on c.category_id = fc.category_id 
	left join "language" l 
	on l.language_id = f.language_id 
group by "Название фильма","Рейтинг","Жанр","Год выпуска","Язык";

--ЗАДАНИЕ №2
--Доработайте запрос из предыдущего задания и выведите с помощью запроса фильмы, которые ни разу не брали в аренду.

select 
	title "Название фильма"
	,rating "Рейтинг"
	,c."name" "Жанр"
	,release_year "Год выпуска" 
	,l."name" "Язык"
	,count(r.inventory_id) "Количество аренд"
	,sum(p.amount)
from film f left join inventory i 
	on f.film_id = i.film_id 
	left join rental r 
	on i.inventory_id = r.inventory_id 
	left join payment p 
	on p.rental_id =r.rental_id
	left join film_category fc 
	on fc.film_id =f.film_id 
	left join category c 
	on c.category_id = fc.category_id 
	left join "language" l 
	on l.language_id = f.language_id
where i.film_id is null
group by "Название фильма","Рейтинг","Жанр","Год выпуска","Язык";

--ЗАДАНИЕ №3
--Посчитайте количество продаж, выполненных каждым продавцом. Добавьте вычисляемую колонку "Премия".
--Если количество продаж превышает 7300, то значение в колонке будет "Да", иначе должно быть значение "Нет".

select 	
	staff_id 
	,count(payment_id)
	,case 
		when count(payment_id) > 7300 then 'Да' 
		when count(payment_id)  < 7300 then 'Нет'
	end 
from payment p join staff s
	using(staff_id)
group by staff_id;






