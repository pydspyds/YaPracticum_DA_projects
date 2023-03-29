# Продвинутый SQL
## Цель

Произвести выгрузки из базы данных Stackoverflow с помощью SQL

## Инструменты и библиотеки  
`SQL`, `PostgreSQL`

## База данных
![-](https://github.com/pydspyds/YaPracticum_DA_projects/blob/f29b0a8aa61952f5375114cde7ef5cda853fe4be/misc/ER_sql_adv.png)

## 1-я часть

```sql
/*
1. Найдите количество вопросов, которые набрали больше 300 очков или как минимум 100 раз были добавлены в «Закладки».
*/

SELECT
	count(p.id)
FROM
	stackoverflow.posts p
JOIN stackoverflow.post_types pt ON
	pt.id = p.post_type_id
WHERE
	pt.type = 'Question'
	AND (favorites_count >= 100
		OR score > 300);

/*
2. Сколько в среднем в день задавали вопросов с 1 по 18 ноября 2008 включительно? Результат округлите до целого числа.
*/
       
SELECT
	round(avg(question_cnt))
FROM
	(
	SELECT
		count(p.id) question_cnt
	FROM
		stackoverflow.posts p
	JOIN stackoverflow.post_types pt ON
		pt.id = p.post_type_id
	WHERE
		creation_date::date BETWEEN '2008-11-1' AND '2008-11-18'
		AND pt.type = 'Question'
	GROUP BY
		p.creation_date::date) question_cnt;

/*
3. Сколько пользователей получили значки сразу в день регистрации? Выведите количество уникальных пользователей.
*/
   
SELECT
	count(DISTINCT u.id)
FROM
	stackoverflow.users u
JOIN stackoverflow.badges b ON
	b.user_id = u.id
WHERE
	u.creation_date::date = b.creation_date::date;

/*
4. Сколько уникальных постов пользователя с именем Joel Coehoorn получили хотя бы один голос?
*/

SELECT
	count(DISTINCT p.id) posts
FROM
	stackoverflow.users u
JOIN stackoverflow.posts p ON
	p.user_id = u.id
JOIN stackoverflow.votes v ON
	v.post_id = p.id
WHERE
	u.display_name = 'Joel Coehoorn'
HAVING
	count(v.id) >= 1;

/*
5. Выгрузите все поля таблицы vote_types. Добавьте к таблице поле rank, в которое войдут номера записей в обратном порядке. Таблица должна быть отсортирована по полю id.
*/

SELECT
	*,
	ROW_NUMBER() OVER (
	ORDER BY id DESC) RANK
FROM
	stackoverflow.vote_types
ORDER BY
	id;

/*
6. Отберите 10 пользователей, которые поставили больше всего голосов типа Close. Отобразите таблицу из двух полей: идентификатором пользователя и количеством голосов. Отсортируйте данные сначала по убыванию количества голосов, потом по убыванию значения идентификатора пользователя.
*/

SELECT
	DISTINCT u.id,
	count(v.id) OVER (PARTITION BY u.id)
FROM
	stackoverflow.users u
JOIN stackoverflow.votes v ON
	u.id = v.user_id
JOIN stackoverflow.vote_types vt ON
	v.vote_type_id = vt.id
WHERE
	vt.name = 'Close'
ORDER BY
	2 DESC,
	1 DESC
LIMIT 10;

/*
7. Отберите 10 пользователей по количеству значков, полученных в период с 15 ноября по 15 декабря 2008 года включительно. Отобразите несколько полей:
	идентификатор пользователя;
	число значков;
	место в рейтинге — чем больше значков, тем выше рейтинг.
Пользователям, которые набрали одинаковое количество значков, присвойте одно и то же место в рейтинге. Отсортируйте записи по количеству значков по убыванию, а затем по возрастанию значения идентификатора пользователя.
*/

WITH popo AS     
     (
SELECT
	DISTINCT u.id users,
	count(b.id) OVER (PARTITION BY u.id) badge_cnt
FROM
	stackoverflow.users u
JOIN stackoverflow.badges b ON
	u.id = b.user_id
WHERE
	b.creation_date::date BETWEEN '2008-11-15' AND '2008-12-15'
     )
SELECT
	users,
	badge_cnt,
	DENSE_RANK() OVER (
	ORDER BY badge_cnt DESC)
FROM
	popo
ORDER BY
	2 DESC,
	1
LIMIT 10;

/*
8. Сколько в среднем очков получает пост каждого пользователя?
Сформируйте таблицу из следующих полей:
	заголовок поста;
	идентификатор пользователя;
	число очков поста;
	среднее число очков пользователя за пост, округлённое до целого числа.
Не учитывайте посты без заголовка, а также те, что набрали ноль очков.
*/

SELECT
	p.title,
	p.user_id,
	p.score,
	round(avg(p.score) OVER (PARTITION BY p.user_id))
FROM
	stackoverflow.posts p
WHERE
	p.title IS NOT NULL
	AND p.score != 0;

/*
9. Отобразите заголовки постов, которые были написаны пользователями, получившими более 1000 значков. Посты без заголовков не должны попасть в список.
*/
 
WITH badge_users AS
    (
SELECT
	users
FROM
	(
	SELECT
		DISTINCT u.id users,
		count(b.id) OVER (PARTITION BY u.id) badge_count
	FROM
		stackoverflow.users u
	JOIN stackoverflow.badges b ON
		u.id = b.user_id) badge_count
WHERE
	badge_count > 1000)
SELECT
	p.title
FROM
	stackoverflow.posts p
JOIN badge_users bu ON
	bu.users = p.user_id
WHERE
	p.title IS NOT NULL;

/*
10. Напишите запрос, который выгрузит данные о пользователях из США (англ. United States). 
Разделите пользователей на три группы в зависимости от количества просмотров их профилей:
	пользователям с числом просмотров больше либо равным 350 присвойте группу 1;
	пользователям с числом просмотров меньше 350, но больше либо равно 100 — группу 2;
	пользователям с числом просмотров меньше 100 — группу 3.
Отобразите в итоговой таблице идентификатор пользователя, количество просмотров профиля и группу. Пользователи с нулевым количеством просмотров не должны войти в итоговую таблицу.
*/

SELECT
	id,
	views_sum,
	CASE
		WHEN views_sum >= 350 THEN 1
		WHEN views_sum < 350
		AND views_sum >= 100 THEN 2
		WHEN views_sum < 100 THEN 3
	END
FROM
	(
	SELECT
		DISTINCT id,
		sum(VIEWS) OVER (PARTITION BY id) views_sum
	FROM
		stackoverflow.users
	WHERE
		LOCATION LIKE '%United States%'
           ) user_filter
WHERE
	views_sum > 0;

11. Дополните предыдущий запрос. Отобразите лидеров каждой группы — пользователей,
которые набрали максимальное число просмотров в своей группе. Выведите поля с идентификатором пользователя,
группой и количеством просмотров. Отсортируйте таблицу по убыванию просмотров,
а затем по возрастанию значения идентификатора.

WITH popo AS
    (
SELECT
	id,
	views_sum,
	CASE
		WHEN views_sum >= 350 THEN 1
		WHEN views_sum < 350
			AND views_sum >= 100 THEN 2
			WHEN views_sum < 100 THEN 3
		END user_group
	FROM
		(
		SELECT
			DISTINCT id,
			sum(VIEWS) OVER (PARTITION BY id) views_sum
		FROM
			stackoverflow.users
		WHERE
			LOCATION LIKE '%United States%') user_filter
	WHERE
		views_sum > 0)
    
SELECT
	id,
	user_group,
	views_sum
FROM
	(
	SELECT
		id,
		user_group,
		views_sum,
		max(views_sum) OVER (PARTITION BY user_group) max_cnt
	FROM
		popo) max_cnt
WHERE
	views_sum = max_cnt
ORDER BY
	views_sum DESC,
	id;

/*
12. Посчитайте ежедневный прирост новых пользователей в ноябре 2008 года. 
Сформируйте таблицу с полями:
	номер дня;
	число пользователей, зарегистрированных в этот день;
	сумму пользователей с накоплением.
*/

SELECT
	day_num,
	user_cnt,
	sum(user_cnt) OVER (
	ORDER BY day_num)
FROM
	(
	SELECT
		DISTINCT creation_date::date reg_date,
		EXTRACT(DAY
	FROM
		creation_date) AS day_num,
		count(id) OVER (PARTITION BY creation_date::date) user_cnt
	FROM
		stackoverflow.users
	WHERE
		date_trunc('month', creation_date::date) = '2008-11-01') profiles;

/*
13. Для каждого пользователя, который написал хотя бы один пост, найдите интервал между регистрацией и временем создания первого поста. Отобразите:
	идентификатор пользователя;
	разницу во времени между регистрацией и первым постом.
*/
   
SELECT
	DISTINCT u.id AS users,
	min(p.creation_date) OVER (PARTITION BY p.user_id) - u.creation_date AS diff_time
FROM
	stackoverflow.users u
JOIN stackoverflow.posts p ON
	p.user_id = u.id;
```

## 2-я часть

```sql
/*
1. Выведите общую сумму просмотров постов за каждый месяц 2008 года. Если данных за какой-либо месяц в базе нет, такой месяц можно пропустить. Результат отсортируйте по убыванию общего количества просмотров.
*/

SELECT
	date_trunc('month', creation_date)::date AS MONTH,
	sum(views_count)
FROM
	stackoverflow.posts
WHERE
	EXTRACT(YEAR
FROM
	creation_date::date) = 2008
GROUP BY
	MONTH
ORDER BY
	sum(views_count) DESC;

/*
2. Выведите имена самых активных пользователей, которые в первый месяц после регистрации (включая день регистрации) дали больше 100 ответов. Вопросы, которые задавали пользователи, не учитывайте. Для каждого имени пользователя выведите количество уникальных значений user_id. Отсортируйте результат по полю с именами в лексикографическом порядке.
*/

SELECT
	u.display_name username
        ,
	count(DISTINCT p.user_id)
FROM
	stackoverflow.users u
JOIN stackoverflow.posts p ON
	p.user_id = u.id
JOIN stackoverflow.post_types pt ON
	pt.id = p.post_type_id
WHERE
	pt.type = 'Answer'
	AND p.creation_date::date 
  	BETWEEN u.creation_date::date AND u.creation_date::date + INTERVAL '1 month'
GROUP BY
	1
HAVING
	count(p.id) > 100
ORDER BY
	1;

/*
3. Выведите количество постов за 2008 год по месяцам. Отберите посты от пользователей, которые зарегистрировались в сентябре 2008 года и сделали хотя бы один пост в декабре того же года. Отсортируйте таблицу по значению месяца по убыванию.
*/

WITH users AS
    (
SELECT
	DISTINCT u.id sept_users
	--           ,p.id december_posts
FROM
	stackoverflow.users u
JOIN stackoverflow.posts p ON
	p.user_id = u.id
WHERE
	date_trunc('month' , u.creation_date) = '2008-09-01'
		AND date_trunc('month' , p.creation_date) = '2008-12-01')
SELECT
	date_trunc('month', p.creation_date)::date
        ,
	count(p.id)
FROM
	stackoverflow.posts p
JOIN users u ON
	p.user_id = u.sept_users
GROUP BY
	1
ORDER BY
	1 DESC;

/*
4. Используя данные о постах, выведите несколько полей:
	идентификатор пользователя, который написал пост;
	дата создания поста;
	количество просмотров у текущего поста;
	сумму просмотров постов автора с накоплением.
Данные в таблице должны быть отсортированы по возрастанию идентификаторов пользователей, а данные об одном и том же пользователе — по возрастанию даты создания поста.
*/

SELECT
	user_id,
	creation_date,
	views_count,
	sum(views_count) OVER (PARTITION BY user_id
ORDER BY
	creation_date)
FROM
	stackoverflow.posts p
ORDER BY
	1,
	2;

/*
5. Сколько в среднем дней в период с 1 по 7 декабря 2008 года включительно пользователи взаимодействовали с платформой? Для каждого пользователя отберите дни, в которые он или она опубликовали хотя бы один пост. Нужно получить одно целое число — не забудьте округлить результат.
*/

SELECT
	round(avg(users_cnt))
FROM
	(
	SELECT
		DISTINCT users,
		count(active_days) OVER (PARTITION BY users) AS users_cnt
	FROM
		(
		SELECT
			user_id AS users
              ,
			EXTRACT(DAY
		FROM
			creation_date) active_days
		FROM
			stackoverflow.posts p
		WHERE
			creation_date::date BETWEEN '2008-12-01' AND '2008-12-07'
		GROUP BY
			1,
			2) active_days) users_cnt;

/*
6. На сколько процентов менялось количество постов ежемесячно с 1 сентября по 31 декабря 2008 года? Отобразите таблицу со следующими полями:
	номер месяца;
	количество постов за месяц;
	процент, который показывает, насколько изменилось количество постов в текущем месяце по сравнению с предыдущим.
Если постов стало меньше, значение процента должно быть отрицательным, если больше — положительным. Округлите значение процента до двух знаков после запятой. Напомним, что при делении одного целого числа на другое в PostgreSQL в результате получится целое число, округлённое до ближайшего целого вниз. Чтобы этого избежать, переведите делимое в тип numeric.
*/

SELECT
	creation_mnth,
	cur_mnth_cnt,
	round(((cur_mnth_cnt::NUMERIC / prev_mnth_cnt::NUMERIC)-1) * 100.0 , 2)
FROM
	(
	SELECT
		creation_mnth,
		cur_mnth_cnt,
		LAG(cur_mnth_cnt) OVER (
		ORDER BY creation_mnth) AS prev_mnth_cnt
	FROM
		(
		SELECT
			EXTRACT(MONTH
		FROM
			p.creation_date) creation_mnth
               ,
			count(p.id) cur_mnth_cnt
		FROM
			stackoverflow.posts p
		WHERE
			p.creation_date BETWEEN '2008-09-01' AND '2008-12-31'
		GROUP BY
			1
        ) popo
    )jopo;

/*
7. Выгрузите данные активности пользователя, который опубликовал больше всего постов за всё время. Выведите данные за октябрь 2008 года в таком виде:
	номер недели;
	дата и время последнего поста, опубликованного на этой неделе.
*/
   
WITH no_life AS
    (
SELECT
	p.user_id AS USER
          ,
	count(p.id) OVER (PARTITION BY p.user_id)
FROM
	stackoverflow.posts p
ORDER BY
	2 DESC
LIMIT 1)
SELECT
	DISTINCT EXTRACT(week
FROM
	p.creation_date) week_num
      ,
	max(p.creation_date) OVER (
	ORDER BY EXTRACT(week
FROM
	p.creation_date))
FROM
	stackoverflow.posts p
JOIN no_life ON
	no_life.user = p.user_id
WHERE
	date_trunc('month', p.creation_date) = '2008-10-01';
```