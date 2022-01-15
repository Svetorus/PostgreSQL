
set search_path to bookings;

-- 1 В каких городах больше одного аэропорта?	

-- группируем по городам и выводим больше одного аэропорта

select city "Город"
from airports a
group by city 
having count(airport_code) > 1
order by 1;

-- 2 В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?	
--  Подзапрос

-- Выводим максимальную дальность полета.
-- Находим самолеты с максимальной дальностью.
-- По коду самолетов выводим Города + названия аэропортов


select distinct city || ' ('||airport_name||')' "Аэропорт"  
from airports a  
	join flights f 
	on a.airport_code = f.departure_airport 
where f.aircraft_code = (
						select a.aircraft_code 
						from aircrafts a 
						order by "range" desc limit 1
						)
order by 1;

-- 3 Вывести 10 рейсов с максимальным временем задержки вылета	
-- Оператор LIMIT

-- Выбираем рейсы которые вылетели(по расписанию и не по расписанию)
-- Задержка считается простым вычитанием(от расписания scheduled_departure вычитаем время реального вылета).


select 
	f.flight_id,
	f.scheduled_departure,
	f.actual_departure,
	f.actual_departure - f.scheduled_departure Время_задержки
from flights f
where f.actual_departure is not null
order by 4 desc
limit 10;

-- 4 Были ли брони, по которым не были получены посадочные талоны?	
-- Верный тип JOIN

-- Left join, т.к. нужны все is null.
-- Можно билеты с бронью join и посмотреть пропуски
-- А чтобы найти уникальные нужно джойнить бронь, билеты и посадочные талоны и отбираем по null в брони.

-- bookings b -- Номер бронирования book_ref
-- tickets t -- Номер бронирования book_ref, Номер билета ticket_no
-- boarding_passes bp --Номер билета ticket_no, Номер посадочного талона boarding_no

select count(distinct b.book_ref) "Количество" --91 388
from bookings b left join tickets t on b.book_ref =t.book_ref 
--	left join ticket_flights tf on t.ticket_no =tf.ticket_no 
	left join boarding_passes bp on bp.ticket_no =t.ticket_no
where bp.boarding_no is null

-- 5. Найдите количество свободных мест для каждого рейса, их % отношение к общему количеству мест в самолете.
-- Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого 
-- аэропорта на каждый день. Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело 
-- из данного аэропорта на этом или более ранних рейсах в течении дня.
-- Оконная функция
-- Подзапросы или/и cte

-- первое СТЕ вывожу сколько мест занято 
-- вторым сколько мест в самолете
-- от макс мест отнимаю занятых и получаю свободных и процент свободных
-- понять сколько человек перевезли за сутки по маршруту

with seats_board as ( 
		select f.flight_id
				,flight_no
				,aircraft_code
				,departure_airport
				,scheduled_departure
				,actual_departure
				,count(bp.boarding_no) count_seats
		from boarding_passes bp join flights f 
			using(flight_id)
		where f.actual_departure is not null 
		group by f.flight_id
		order by scheduled_departure
		),
seat_model as(
				select aircraft_code,count(seat_no) max_model 
				from seats 
				group by aircraft_code
			)
select 
	scheduled_departure::date
	,actual_departure
	,departure_airport
	,max_model
	,count_seats
	,max_model - count_seats free_seats
	,round((max_model - count_seats)/max_model::numeric,2)*100 procent
	,sum(count_seats) over (partition by (departure_airport,actual_departure::date) order by actual_departure)
from seats_board b join seat_model sm 
	using(aircraft_code)

-- 6. Найдите процентное соотношение перелетов по типам самолетов от общего количества.
-- Подзапрос или окно
-- Оператор ROUND
	
-- вывожу в подзапросе без повторов кол-во полетов модели
	-- общие число полетов и % полетов на общие кол-во
-- вывел суммировал проценты по полетам

select model
	,flight
	,sum_flight
	,"%"
	, sum("%")over() procent_sum
from(
select distinct model
	,count(flight_no) over(partition by model) flight
	,count(flight_id) over() sum_flight
	,round(count(flight_no) over(partition by model)/count(flight_no) over()::numeric,2)*100 "%"
from aircrafts a right join flights f
	on f.aircraft_code = a.aircraft_code
) t order by model;
		
-- 7. Были ли города, в которые можно  добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета?		
-- CTE	

-- выводим номер рейса и окнами минимальное значение эконом класса
-- максимальное значение бизнес класса
-- подзапросом выводим город по условию мак.эконом > мин.бизнес

select distinct flight_id,max_econom,min_busines,a.city
from (
		select 
			flight_id
			,max(amount)FILTER (WHERE fare_conditions = 'Economy') over(partition by flight_id) max_econom
			,min(amount)FILTER (WHERE fare_conditions = 'Business')over(partition by flight_id) min_busines
		from ticket_flights tf
	) t
join flights f using(flight_id)
join airports a on a.airport_code=f.arrival_airport 
where max_econom > min_busines;

-- 8. Между какими городами нет прямых рейсов?
-- Декартово произведение в предложении FROM Самостоятельно созданные представления (если облачное подключение, то без представления)
-- Оператор EXCEPT

-- вывел без прямого рейса(аэропорты-вылет и прилет)
-- и исключил пересечение из всех перелетов

with turbo as 
	(select distinct 
		a.city departure_city,
		a2.city arrival_city 
	from airports a join airports a2 
	on a.city <> a2.city 
	except
	select distinct 
		a.city departure_city,
		a2.city arrival_city
	from flights f 
	join airports a on f.departure_airport = a.airport_code 
	join airports a2 on f.arrival_airport = a2.airport_code
	order by 1)
select count(departure_city) from turbo;

-- 9.Вычислите расстояние между аэропортами, связанными прямыми рейсами, сравните с допустимой максимальной дальностью 
-- перелетов  в самолетах, обслуживающих эти рейсы *
-- Оператор RADIANS или использование sind/cosd
-- CASE 

-- выводим аэропорт вылета и аэропорт прилета, формула из описания расчитать расстояние
-- СТЕ вытаскиваем нужные нам значения и с помощью CASE назначаем долетиле или нет

with cte as (
	select 
		f.departure_airport
		,f.arrival_airport
		,f.aircraft_code
		,round(((acos((sind(dep.coordinates[1])*sind(arr.coordinates[1]) + cosd(dep.coordinates[1]) * cosd(arr.coordinates[1]) * cosd((dep.coordinates[0] - arr.coordinates[0]))))) * 6371)::numeric, 2)
		as distance_airports 
		,f.flight_no
		,dep.airport_name as departure_airport_name
		,arr.airport_name as arrival_airport_name
	from 
	flights f,
	airports dep,
	airports arr
	where f.departure_airport = dep.airport_code and f.arrival_airport = arr.airport_code
)
select distinct 
	cte.departure_airport_name
	,cte.arrival_airport_name
	,cte.distance_airports,
	a.range as aircraft_flight_distance
	,case
		when range > distance_airports then 'Долетели'
		else 'Сели в поле!'
	 end result
from aircrafts a 
join cte on cte.aircraft_code = a.aircraft_code


