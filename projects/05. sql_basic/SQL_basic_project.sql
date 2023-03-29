/*
111 [Схема БД](https://github.com/pydspyds/YaPracticum_DA_projects/blob/33d8555194a71f64675362d221241b13532656aa/misc/ER_sql_basic.png)
*/
/*
В самостоятельном проекте вам нужно проанализировать данные о фондах и инвестициях и написать запросы к базе. 
*/


/* 
1. Посчитайте, сколько компаний закрылось. 
*/

SELECT
	count(status)
FROM
	company
WHERE
	status = 'closed';

/* 
2. Отобразите количество привлечённых средств для новостных компаний США. 
Используйте данные из таблицы company. Отсортируйте таблицу по убыванию значений в поле funding_total. 
*/

SELECT
	funding_total
FROM
	company
WHERE
	category_code = 'news'
	AND country_code = 'USA'
ORDER BY
	funding_total DESC;

/* 
3. Найдите общую сумму сделок по покупке одних компаний другими в долларах. 
Отберите сделки, которые осуществлялись только за наличные с 2011 по 2013 год включительно. 
*/

SELECT
	SUM(price_amount)
FROM
	acquisition
WHERE
	term_code = 'cash'
	AND EXTRACT(YEAR
FROM
	acquired_at) BETWEEN 2011 AND 2013;

/* 
4. Отобразите имя, фамилию и названия аккаунтов людей в твиттере, у которых названия аккаунтов начинаются на 'Silver'. 
*/

SELECT
	first_name,
	last_name,
	twitter_username
FROM
	people
WHERE
	twitter_username LIKE 'Silver%';

/* 
5. Выведите на экран всю информацию о людях, у которых названия аккаунтов в твиттере содержат подстроку 'money', а фамилия начинается на 'K'. 
*/

SELECT
	*
FROM
	people
WHERE
	twitter_username LIKE '%money%'
	AND last_name LIKE 'K%';

/*
6. Для каждой страны отобразите общую сумму привлечённых инвестиций, которые получили компании, зарегистрированные в этой стране. Страну, в которой зарегистрирована компания, можно определить по коду страны. Отсортируйте данные по убыванию суммы. 
*/

SELECT
	country_code,
	SUM(funding_total)
FROM
	company
GROUP BY
	country_code
ORDER BY
	SUM(funding_total) DESC;

/* 
7. Составьте таблицу, в которую войдёт дата проведения раунда, а также минимальное и максимальное значения суммы инвестиций, привлечённых в эту дату. Оставьте в итоговой таблице только те записи, в которых минимальное значение суммы инвестиций не равно нулю и не равно максимальному значению. 
*/

SELECT
	funded_at,
	MIN(raised_amount),
	MAX(raised_amount)
FROM
	funding_round
GROUP BY
	funded_at
HAVING
	MIN(raised_amount) != 0
	AND MIN(raised_amount) != MAX(raised_amount);

/* 
8. Создайте поле с категориями:
	* Для фондов, которые инвестируют в 100 и более компаний, назначьте категорию high_activity.
	* Для фондов, которые инвестируют в 20 и более компаний до 100, назначьте категорию middle_activity.
	* Если количество инвестируемых компаний фонда не достигает 20, назначьте категорию low_activity. 
Отобразите все поля таблицы fund и новое поле с категориями. 
*/
       
SELECT
	*,
	CASE
		WHEN invested_companies > 100 THEN 'high_activity'
		WHEN invested_companies <= 100
		AND invested_companies >= 20 THEN 'middle_activity'
		WHEN invested_companies < 20 THEN 'low_activity'
	END
FROM
	fund;

/* 
9. Для каждой из категорий, назначенных в предыдущем задании, посчитайте округлённое до ближайшего целого числа среднее количество инвестиционных раундов, в которых фонд принимал участие. Выведите на экран категории и среднее число инвестиционных раундов. Отсортируйте таблицу по возрастанию среднего. 
*/

SELECT
	ROUND(AVG(investment_rounds)) AS avg_rounds,
	CASE
		WHEN invested_companies >= 100 THEN 'high_activity'
		WHEN invested_companies >= 20 THEN 'middle_activity'
		ELSE 'low_activity'
	END AS activity
FROM
	fund
GROUP BY
	activity
ORDER BY
	avg_rounds;

/* 
10. Проанализируйте, в каких странах находятся фонды, которые чаще всего инвестируют в стартапы. 
Для каждой страны посчитайте минимальное, максимальное и среднее число компаний, в которые инвестировали фонды этой страны, основанные с 2010 по 2012 год включительно. Исключите страны с фондами, у которых минимальное число компаний, получивших инвестиции, равно нулю.
Выгрузите десять самых активных стран-инвесторов: отсортируйте таблицу по среднему количеству компаний от большего к меньшему. Затем добавьте сортировку по коду страны в лексикографическом порядке. 
*/

SELECT
	country_code,
	MIN(invested_companies),
	MAX(invested_companies),
	AVG(invested_companies)
FROM
	fund
WHERE
	EXTRACT(YEAR
FROM
	founded_at) BETWEEN 2010 AND 2012
GROUP BY
	country_code
HAVING
	MIN(invested_companies) != 0
ORDER BY
	AVG(invested_companies) DESC,
	country_code
LIMIT 10;

/* 
11. Отобразите имя и фамилию всех сотрудников стартапов. Добавьте поле с названием учебного заведения, которое окончил сотрудник, если эта информация известна. 
*/

SELECT
	p.first_name,
	p.last_name,
	e.instituition
FROM
	people AS p
LEFT JOIN education AS e ON
	p.id = e.person_id;

/* 
12. Для каждой компании найдите количество учебных заведений, которые окончили её сотрудники. 
Выведите название компании и число уникальных названий учебных заведений.
Составьте топ-5 компаний по количеству университетов.
*/

SELECT
	c.name,
	count(DISTINCT(e.instituition)) AS inst_count
FROM
	company AS c
JOIN people AS p ON
	c.id = p.company_id
JOIN education AS e ON
	p.id = e.person_id
GROUP BY
	c.name
ORDER BY
	inst_count DESC
LIMIT 5;

/* 
13. Составьте список с уникальными названиями закрытых компаний, для которых первый раунд финансирования оказался последним. 
*/

WITH
fr AS (
SELECT
	company_id
FROM
	funding_round
WHERE
	is_first_round = 1
	AND is_last_round = 1)
    
SELECT
	DISTINCT(name)
FROM
	company AS c
RIGHT JOIN fr ON
	c.id = fr.company_id
WHERE
	status = 'closed';

/* 
14. Составьте список уникальных номеров сотрудников, которые работают в компаниях, отобранных в предыдущем задании. 
*/

WITH cte AS (
SELECT
	c.id
FROM
	company AS c
RIGHT JOIN funding_round AS fr ON
	c.id = fr.company_id
WHERE
	c.status = 'closed'
	AND fr.is_first_round = 1
	AND fr.is_last_round = 1)
                    
SELECT
	DISTINCT(p.id)
FROM
	people AS p
WHERE
	p.company_id IN (
	SELECT
		id
	FROM
		cte);

/* 
15. Составьте таблицу, куда войдут уникальные пары с номерами сотрудников из предыдущей задачи и учебным заведением, которое окончил сотрудник. 
*/
                       
WITH cte AS (
SELECT
	c.id
FROM
	company AS c
RIGHT JOIN funding_round AS fr ON
	c.id = fr.company_id
WHERE
	c.status = 'closed'
	AND fr.is_first_round = 1
	AND fr.is_last_round = 1)
                     
SELECT
	DISTINCT(e.instituition),
	e.person_id
FROM
	education AS e
WHERE
	e.person_id IN (
	SELECT
		DISTINCT(p.id)
	FROM
		people AS p
	WHERE
		p.company_id IN (
		SELECT
			id
		FROM
			cte));

/* 
16. Посчитайте количество учебных заведений для каждого сотрудника из предыдущего задания. При подсчёте учитывайте, что некоторые сотрудники могли окончить одно и то же заведение дважды. 
*/

WITH cte AS 
	(
SELECT
	c.id
FROM
	company AS c
RIGHT JOIN funding_round AS fr
		ON
	c.id = fr.company_id
WHERE
	c.status = 'closed'
	AND fr.is_first_round = 1
	AND fr.is_last_round = 1)
SELECT
	count((e.instituition)),
		 e.person_id
FROM
	education AS e
WHERE
	e.person_id IN 
	(
	SELECT
		DISTINCT(p.id)
	FROM
		people AS p
	WHERE
		p.company_id IN 
		(
		SELECT
			id
		FROM
			cte))
GROUP BY
	e.person_id;

/* 
17. Дополните предыдущий запрос и выведите среднее число учебных заведений (всех, не только уникальных), которые окончили сотрудники разных компаний. Нужно вывести только одну запись, группировка здесь не понадобится. 
*/

WITH cte AS 
	(
SELECT
	c.id
FROM
	company AS c
RIGHT JOIN funding_round AS fr
		ON
	c.id = fr.company_id
WHERE
	c.status = 'closed'
	AND fr.is_first_round = 1
	AND fr.is_last_round = 1)

    
SELECT
	avg(inst_count)
FROM
	(
	SELECT
		count(e.instituition) AS inst_count
	FROM
		education AS e
	WHERE
		e.person_id IN 
	(
		SELECT
			DISTINCT(p.id)
		FROM
			people AS p
		WHERE
			p.company_id IN 
		(
			SELECT
				id
			FROM
				cte))
	GROUP BY
		e.person_id) AS inst_count_query;

/* 
18. Напишите похожий запрос: выведите среднее число учебных заведений (всех, не только уникальных), которые окончили сотрудники Facebook. 
*/

WITH
c AS (
SELECT
	id
FROM
	company
WHERE
	name = 'Facebook'),       
p AS (
SELECT
	id
FROM
	people
WHERE
	company_id IN (
	SELECT
		id
	FROM
		c))                          

SELECT
	avg(inst_count)
FROM
	(
	SELECT
		count(instituition) AS inst_count
	FROM
		education
	WHERE
		person_id IN (
		SELECT
			id
		FROM
			p)
	GROUP BY
		person_id) AS edu;

/* 
19. Составьте таблицу из полей:
	* name_of_fund — название фонда;
	* name_of_company — название компании;
	* amount — сумма инвестиций, которую привлекла компания в раунде.
В таблицу войдут данные о компаниях, в истории которых было больше шести важных этапов, а раунды финансирования проходили с 2012 по 2013 год включительно. 
*/

SELECT
	f.name AS name_of_fund,
	c.name AS name_of_company,
	raised_amount
FROM
	fund f
JOIN investment i ON
	f.id = i.fund_id
JOIN company c ON
	i.company_id = c.id
JOIN funding_round fr ON
	fr.id = i.funding_round_id
WHERE
	c.milestones>6
	AND EXTRACT(YEAR
FROM
	fr.funded_at) BETWEEN 2012 AND 2013;

/* 
20. Выгрузите таблицу, в которой будут такие поля:
	* название компании-покупателя;
	* сумма сделки;
	* название компании, которую купили;
	* сумма инвестиций, вложенных в купленную компанию;
	* доля, которая отображает, во сколько раз сумма покупки превысила сумму вложенных в компанию инвестиций, округлённая до ближайшего целого числа.
Не учитывайте те сделки, в которых сумма покупки равна нулю. Если сумма инвестиций в компанию равна нулю, исключите такую компанию из таблицы. 
Отсортируйте таблицу по сумме сделки от большей к меньшей, а затем по названию купленной компании в лексикографическом порядке. Ограничьте таблицу первыми десятью записями. 
*/

SELECT
	c_owner.name AS acquiring,
	price_amount AS price,
	c_bought.name AS acquired,
	c_bought.funding_total AS fund,
	ROUND (price_amount / c_bought.funding_total) AS rate
FROM
	acquisition AS acq
LEFT JOIN company AS c_owner ON
	acq.acquiring_company_id = c_owner.id
LEFT JOIN company AS c_bought ON
	acq.acquired_company_id = c_bought.id
WHERE
	price_amount != 0
	AND c_bought.funding_total != 0
ORDER BY
	price DESC,
	acquired
LIMIT 10;

/* 
21. Выгрузите таблицу, в которую войдут названия компаний из категории social, получившие финансирование с 2010 по 2013 год включительно. Проверьте, что сумма инвестиций не равна нулю. Выведите также номер месяца, в котором проходил раунд финансирования.
*/

SELECT
	c.name,
	EXTRACT (MONTH
FROM
	fr.funded_at)
FROM
	company AS c
RIGHT JOIN funding_round AS fr ON
	c.id = fr.company_id
WHERE
	c.category_code = 'social'
	AND EXTRACT (YEAR
FROM
	fr.funded_at) BETWEEN 2010 AND 2013
	AND c.funding_total != 0
	AND fr.raised_amount != 0;

/* 
22. Отберите данные по месяцам с 2010 по 2013 год, когда проходили инвестиционные раунды. 
Сгруппируйте данные по номеру месяца и получите таблицу, в которой будут поля:
	 * номер месяца, в котором проходили раунды;
	 * количество уникальных названий фондов из США, которые инвестировали в этом месяце;
	 * количество компаний, купленных за этот месяц;
	 * общая сумма сделок по покупкам в этом месяце. 
*/
       
WITH acq_c AS
    (
SELECT
	EXTRACT(MONTH
FROM
	acquired_at) AS m
         ,
	count(acquired_company_id) AS acq_comp_cnt
         ,
	sum(price_amount) AS acq_amount
FROM
	acquisition AS acq
WHERE
	EXTRACT(YEAR
FROM
	acquired_at) BETWEEN 2010 AND 2013
GROUP BY
	EXTRACT(MONTH
FROM
	acquired_at)
    )
,
inv_f AS
    (
SELECT
	EXTRACT(MONTH
FROM
	funded_at) AS m
     ,
	count(DISTINCT f.name) AS fund_cnt
FROM
	funding_round fr,
	investment I,
	fund f
WHERE
	fr.id = I.funding_round_id
	AND i.fund_id = f.id
	AND EXTRACT(YEAR
FROM
	funded_at) BETWEEN 2010 AND 2013
	AND f.country_code = 'USA'
GROUP BY
	EXTRACT(MONTH
FROM
	funded_at)
    )

SELECT
	EXTRACT(MONTH
FROM
	fr.funded_at)
 ,
	avg(fund_cnt) AS fund_cnt
 ,
	avg(acq_comp_cnt)
 ,
	avg(acq_amount)
FROM
	funding_round fr
LEFT JOIN inv_f i 
 ON
	I.m = EXTRACT(MONTH
FROM
	fr.funded_at)
LEFT JOIN acq_c a 
 ON
	a.m = EXTRACT(MONTH
FROM
	fr.funded_at)
WHERE
	EXTRACT(YEAR
FROM
	fr.funded_at) BETWEEN 2010 AND 2013
GROUP BY
	EXTRACT(MONTH
FROM
	fr.funded_at);

/* 
23. Составьте сводную таблицу и выведите среднюю сумму инвестиций для стран, в которых есть стартапы, зарегистрированные в 2011, 2012 и 2013 годах. Данные за каждый год должны быть в отдельном поле. Отсортируйте таблицу по среднему значению инвестиций за 2011 год от большего к меньшему. 
*/

WITH
inv_2011 AS
(
SELECT
	avg(funding_total) AS avg_2011,
	country_code
FROM
	company
WHERE
	EXTRACT(YEAR
FROM
	founded_at) = 2011
GROUP BY
	country_code
HAVING
	avg(funding_total) IS NOT NULL
),
inv_2012 AS 
(
SELECT
	avg(funding_total) AS avg_2012,
	country_code
FROM
	company
WHERE
	EXTRACT(YEAR
FROM
	founded_at) = 2012
GROUP BY
	country_code
HAVING
	avg(funding_total) IS NOT NULL
),
inv_2013 AS
(
SELECT
	avg(funding_total) AS avg_2013,
	country_code
FROM
	company
WHERE
	EXTRACT(YEAR
FROM
	founded_at) = 2013
GROUP BY
	country_code
HAVING
	avg(funding_total) IS NOT NULL
)

SELECT
	inv_2011.country_code,
	inv_2011.avg_2011,
	inv_2012.avg_2012,
	inv_2013.avg_2013
FROM
	inv_2011
JOIN inv_2012 ON
	inv_2011.country_code = inv_2012.country_code
JOIN inv_2013 ON
	inv_2011.country_code = inv_2013.country_code
ORDER BY
	inv_2011.avg_2011 DESC;
