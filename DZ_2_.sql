--Задание 1. Выведите уникальные названия регионов из таблицы адресов.
--Ожидаемый результат запроса
SELECT distinct district 
FROM address a;

/*
 Задание 2. Доработайте запрос из предыдущего задания, чтобы запрос выводил только те 
регионы, названия которых начинаются на “K” и заканчиваются на “a”, и названия не содержат пробелов.
*/

SELECT distinct district
FROM address a
WHERE district LIKE 'K%' 
	and district LIKE '%a'
	and district ~~ '% %'; 

/*
Задание 3. Получите из таблицы платежей за прокат фильмов информацию по платежам, 
которые выполнялись в промежуток с 17 марта 2007 года по 19 марта 2007 года включительно, 
и стоимость которых превышает 1.00. Платежи нужно отсортировать по дате платежа.
*/

--первый вариант
select payment_id, payment_date, amount
from payment p
where amount > 1 
	and payment_date::date >= '2007-03-17'  
	and payment_date::date <='2007-03-19'
order by payment_date,amount;

--второй вариант
select payment_id, payment_date, amount
from payment p
where amount > 1 and
	payment_date::date between '2007/03/17' and '2007-03-20' 
order by payment_date,amount;

/*тип колонки
select column_name,data_type 
from information_schema.columns 
where table_name = 'payment';
*/
--Задание 4. Выведите информацию о 10-ти последних платежах за прокат фильмов

select payment_id, payment_date, amount
from payment p
order by payment_date desc
limit 10;

/*
Задание 5. Выведите следующую информацию по покупателям:

Фамилия и имя (в одной колонке через пробел)
Электронная почта
Длину значения поля email
Дату последнего обновления записи о покупателе (без времени)
Каждой колонке задайте наименование на русском языке.
*/
--первый вариант
select last_name||' '||first_name as "Фамилия и имя",
	email "Электронная почта", length(email) "Длину email",
	last_update::date "Дата"
from customer c;

--второй вариант
select concat(last_name,' ',first_name) as "Фамилия и имя",
	email "Электронная почта", length(email) "Длину email",
	last_update::date "Дата"
from customer c;
/*
 Задание 6. Выведите одним запросом активных покупателей, имена которых Kelly или Willie. 
 Все буквы в фамилии и имени из нижнего регистра должны быть переведены в высокий регистр.
 */

select upper(last_name), upper(first_name)
from customer c
where active = 1
	and first_name ilike 'Kelly%' 
	or first_name ~~* 'Willie%';


/*
 Дополнительная часть:
 Задание 1. Выведите одним запросом информацию о фильмах, у которых рейтинг “R” и стоимость аренды указана 
 от 0.00 до 3.00 включительно, а также фильмы c рейтингом “PG-13” и стоимостью аренды больше или равной 4.00.
 */


select film_id, title, description, rating, rental_rate 
from film f
where (rating ='PG-13' 
	and rental_rate >= 4)
	or (rating ='R' 
	and rental_rate > 0
	and rental_rate <= 2.99)

/*
 Задание 2. Получите информацию о трёх фильмах с самым длинным описанием фильма. 
 */

select film_id, title, description
from (select film_id, title, description , length(description) 
		from film f 
		order by length desc 
		limit 3) t;
	
/*
Задание 3. Выведите Email каждого покупателя, разделив значение Email на 2 отдельных колонки: 
в первой колонке должно быть значение, указанное до @, во второй колонке должно быть значение, указанное после @.
*/
	
select 
	customer_id, 
	email "Email", 
	split_part(email ,'@',1) "Email before @",
	split_part(email ,'@',2) "Email after @"
from customer c;

/*
Задание 4. Доработайте запрос из предыдущего задания, скорректируйте значения в новых колонках: 
первая буква должна быть заглавной, остальные строчными.
 */
--UPPER(SUBSTRING(name FROM 1 FOR 1)) || SUBSTRING(name FROM 2 FOR LENGTH(name))

select 
	customer_id, 
	lower(email) "Email",
	SUBSTRING(split_part(email ,'@',1) FROM 1 FOR 1) || SUBSTRING(lower(split_part(email ,'@',1)) FROM 2 FOR LENGTH(split_part(email ,'@',1))) "Email before @",
	upper(SUBSTRING(split_part(email ,'@',2) FROM 1 FOR 1)) || SUBSTRING(lower(split_part(email ,'@',2)) FROM 2 FOR LENGTH(split_part(email ,'@',2))) "Email after @"    
from customer c;



	