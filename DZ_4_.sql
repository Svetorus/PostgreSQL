--=============== МОДУЛЬ 4. УГЛУБЛЕНИЕ В SQL =======================================
create schema homework4;
set search_path to homework4;
--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--База данных: если подключение к облачной базе, то создаете новые таблицы в формате:
--таблица_фамилия, 
--если подключение к контейнеру или локальному серверу, то создаете новую схему и в ней создаете таблицы.


-- Спроектируйте базу данных для следующих сущностей:
-- 1. язык (в смысле английский, французский и тп)
-- 2. народность (в смысле славяне, англосаксы и тп)
-- 3. страны (в смысле Россия, Германия и тп)


--Правила следующие:
-- на одном языке может говорить несколько народностей
-- одна народность может входить в несколько стран
-- каждая страна может состоять из нескольких народностей

 
--Требования к таблицам-справочникам:
-- идентификатор сущности должен присваиваться автоинкрементом
-- наименования сущностей не должны содержать null значения и не должны допускаться дубликаты в названиях сущностей
 
--СОЗДАНИЕ ТАБЛИЦЫ ЯЗЫКИ

create table languages (
	language_id serial primary key,
	"name" varchar(20) unique not null
);

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ ЯЗЫКИ

insert into languages("name")
values
	('Русский'),
	('Испанский'),
	('Английский'),
	('Немецкий'),
	('Гэльский'),
	('Эсперанто');

--СОЗДАНИЕ ТАБЛИЦЫ НАРОДНОСТИ

create table nations (
	nation_id serial primary key,
	title varchar(40) unique not null 
);

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ НАРОДНОСТИ

insert into nations(title) 
values 
	('Русские'),
	('Испанцы'),
	('Англичане'),
	('Немцы'),
	('Шотландцы'),
	('Люди из мира стальной крысы');

--СОЗДАНИЕ ТАБЛИЦЫ СТРАНЫ

create table countries (
	country_id serial primary key,
	"name" varchar(40) unique not null 
)

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ СТРАНЫ

insert into countries("name")
values
	('Российская Федерация'),
	('Испания'),
	('Великобритания'),
	('Германия'),
	('Планета Райский уголок');

--СОЗДАНИЕ ПЕРВОЙ ТАБЛИЦЫ СО СВЯЗЯМИ

create table CountriesNations(
	country_id integer references countries not null,
	nation_id integer references nations not null,
	constraint pkCountriesNations primary key (country_id, nation_id)
);

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ СО СВЯЗЯМИ

insert into countriesnations 
values
	(1,1),
	(2,2),
	(3,3),
	(4,4),
	(3,5),
	(5,6);

--СОЗДАНИЕ ВТОРОЙ ТАБЛИЦЫ СО СВЯЗЯМИ

create table LanguagesNations(
	language_id integer references languages not null,
	nation_id integer references nations not null,
	constraint pkLanguagesNations primary key (language_id, nation_id)
);

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ СО СВЯЗЯМИ

insert into languagesnations 
values
	(1,1),
	(2,2),
	(3,3),
	(4,4),
	(5,5),
	(6,6);

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============


--ЗАДАНИЕ №1 
--Создайте новую таблицу film_new со следующими полями:
--·   	film_name - название фильма - тип данных varchar(255) и ограничение not null
--·   	film_year - год выпуска фильма - тип данных integer, условие, что значение должно быть больше 0
--·   	film_rental_rate - стоимость аренды фильма - тип данных numeric(4,2), значение по умолчанию 0.99
--·   	film_duration - длительность фильма в минутах - тип данных integer, ограничение not null и условие, что значение должно быть больше 0
--Если работаете в облачной базе, то перед названием таблицы задайте наименование вашей схемы.

create table film_new (
	film_id serial primary key,
	film_name varchar(255) not null,
	film_year integer check (film_year > 0),
	film_rental_rate numeric(4,2) default 0.99,
	film_duration integer not null check (film_duration > 0)
);

--ЗАДАНИЕ №2 
--Заполните таблицу film_new данными с помощью SQL-запроса, где колонкам соответствуют массивы данных:
--·       film_name - array['The Shawshank Redemption', 'The Green Mile', 'Back to the Future', 'Forrest Gump', 'Schindlers List']
--·       film_year - array[1994, 1999, 1985, 1994, 1993]
--·       film_rental_rate - array[2.99, 0.99, 1.99, 2.99, 3.99]
--·   	  film_duration - array[142, 189, 116, 142, 195]

insert into film_new(film_name, film_year, film_rental_rate, film_duration)
select
	unnest(array['The Shawshank Redemption', 'The Green Mile', 'Back to the Future', 'Forrest Gump', 'Schindlers List']),
	unnest(array[1994, 1999, 1985, 1994, 1993]),
	unnest(array[2.99, 0.99, 1.99, 2.99, 3.99]),
	unnest(array[142, 189, 116, 142, 195]);

--ЗАДАНИЕ №3
--Обновите стоимость аренды фильмов в таблице film_new с учетом информации, 
--что стоимость аренды всех фильмов поднялась на 1.41

update film_new 
set film_rental_rate = film_rental_rate + 1.41;

--ЗАДАНИЕ №4
--Фильм с названием "Back to the Future" был снят с аренды, 
--удалите строку с этим фильмом из таблицы film_new

delete from film_new 
where film_name = 'Back to the Future';

--ЗАДАНИЕ №5
--Добавьте в таблицу film_new запись о любом другом новом фильме

insert into film_new(film_name, film_year, film_rental_rate, film_duration)
values
	('Snatch', 2000, 4.99, 104);

--ЗАДАНИЕ №6
--Напишите SQL-запрос, который выведет все колонки из таблицы film_new, 
--а также новую вычисляемую колонку "длительность фильма в часах", округлённую до десятых

select 
	*, round(film_duration / 60::numeric, 1) "Длительность фильма в часах" 
from film_new;

--ЗАДАНИЕ №7 
--Удалите таблицу film_new

drop table film_new;