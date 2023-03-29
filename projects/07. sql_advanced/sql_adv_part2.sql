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
