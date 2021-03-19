--PREAMBLE--
CREATE VIEW edge AS
    SELECT ap1.authorid AS authorid1, ap2.authorid AS authorid2
    FROM authorpaperlist AS ap1
    JOIN authorpaperlist AS ap2
        ON ap1.paperid = ap2.paperid
    WHERE ap1.authorid != ap2.authorid;

CREATE VIEW edge2 AS
SELECT ap1.authorid AS authorid1, ap2.authorid AS authorid2, paperdetails.conferencename as conf
FROM authorpaperlist AS ap1, authorpaperlist AS ap2, paperdetails
WHERE ap1.paperid = ap2.paperid
AND ap1.authorid != ap2.authorid
AND ap1.paperid = paperdetails.paperid;

CREATE VIEW conncompo as
WITH RECURSIVE path (s, arr, d) AS
(
SELECT edge.authorid1, ARRAY[edge.authorid1], edge.authorid2
FROM edge
UNION
SELECT path.s, array_append(path.arr, path.d), edge.authorid2
FROM path, edge
WHERE path.d = edge.authorid1
AND (NOT path.d = ANY(path.arr))
AND ((NOT edge.authorid2 = ANY(path.arr)) OR edge.authorid2 = path.s)
) 
SELECT path.s, path.d
FROM path
GROUP BY path.s, path.d
ORDER BY path.s, path.d;

create view citations as 
select authorpaperlist.authorid, CASE
WHEN SUM(foo.cnt) IS NULL THEN 0
ELSE SUM(foo.cnt)
END sum
from (select foo.s, COUNT(DISTINCT foo.d) as cnt
from (WITH RECURSIVE path1 (s, arr, d) AS
(
SELECT citationlist.paperid2, ARRAY[citationlist.paperid2], citationlist.paperid1
FROM citationlist
UNION
SELECT path1.s, array_append(path1.arr, path1.d), citationlist.paperid1
FROM path1, citationlist
WHERE path1.d = citationlist.paperid2
AND (NOT path1.d = ANY(path1.arr))
AND ((NOT citationlist.paperid1 = ANY(path1.arr)) OR citationlist.paperid1 = path1.s)
) 
SELECT *
FROM path1) as foo
group by foo.s) as foo right join authorpaperlist
ON authorpaperlist.paperid = foo.s
group by authorpaperlist.authorid;

CREATE VIEW view14 AS
select authorpaperlist.authorid, foo.s as p1, foo.d as p2
from (select temp.s, temp.d
FROM (
WITH RECURSIVE citepath (s, arr, d) AS
(
SELECT citationlist.paperid1, ARRAY[citationlist.paperid1], citationlist.paperid2
FROM citationlist
UNION
SELECT citepath.s, array_append(citepath.arr, citepath.d), citationlist.paperid2
FROM citepath, citationlist
WHERE citepath.d = citationlist.paperid1
AND (NOT citepath.d = ANY(citepath.arr))
AND ((NOT citationlist.paperid2 = ANY(citepath.arr)) OR citationlist.paperid2 = citepath.s)
) 
SELECT *
FROM citepath) as temp
GROUP BY temp.s, temp.d
) as foo, authorpaperlist
WHERE authorpaperlist.paperid = foo.s;

CREATE VIEW view12 as 
select temp.s, temp.d, MIN(array_length(temp.arr, 1)) as length
FROM (WITH RECURSIVE path (s, arr, d) AS
(
SELECT edge.authorid1, ARRAY[edge.authorid1], edge.authorid2
FROM edge
UNION
SELECT path.s, array_append(path.arr, path.d), edge.authorid2
FROM path, edge
WHERE path.d = edge.authorid1
AND (NOT path.d = ANY(path.arr))
AND ((NOT edge.authorid2 = ANY(path.arr)) OR edge.authorid2 = path.s)
) 
SELECT *
FROM path) as temp
WHERE temp.s = 1235
AND temp.s != temp.d
GROUP BY temp.s, temp.d;

CREATE VIEW view13 as 
select COUNT(temp.arr) as count
FROM (WITH RECURSIVE path (s, arr, d) AS
(
SELECT edge.authorid1, ARRAY[edge.authorid1], edge.authorid2
FROM edge
UNION
SELECT path.s, array_append(path.arr, path.d), edge.authorid2
FROM path, edge, authordetails as a1, authordetails as a2
WHERE path.d = edge.authorid1
AND edge.authorid1 = a1.authorid
AND edge.authorid2 = a2.authorid
AND a1.age > 35 
AND (a2.authorid = 2826 OR (a2.age > 35 AND a1.gender != a2.gender))
AND (NOT path.d = ANY(path.arr))
AND ((NOT edge.authorid2 = ANY(path.arr)) OR edge.authorid2 = path.s)
) 
SELECT *
FROM path) as temp
WHERE temp.s = 1558 AND temp.d = 2826
GROUP BY temp.arr;

create view view17 as
select foo.s as authorid, citations.sum
FROM (select foo.s, foo.d
FROM (select temp.s, temp.d, MIN(array_length(temp.arr, 1)) as length
FROM (WITH RECURSIVE path (s, arr, d) AS
(
SELECT edge.authorid1, ARRAY[edge.authorid1], edge.authorid2
FROM edge
UNION
SELECT path.s, array_append(path.arr, path.d), edge.authorid2
FROM path, edge
WHERE path.d = edge.authorid1
AND (NOT path.d = ANY(path.arr))
AND ((NOT edge.authorid2 = ANY(path.arr)) OR edge.authorid2 = path.s)
)
SELECT *
FROM path) as temp
WHERE temp.s != temp.d
GROUP BY temp.s, temp.d) as foo
WHERE foo.length = 3) as foo, citations
WHERE
foo.d = citations.authorid
ORDER BY citations.sum DESC, foo.s;

create view view19 as 
select a1.authorid as authorid1, a2.authorid as authorid2
from authorpaperlist as a1, citationlist, authorpaperlist as a2
WHERE
a1.paperid = citationlist.paperid1
AND citationlist.paperid2 = a2.paperid
INTERSECT
select a2.authorid as authorid1, a1.authorid as authorid2
from authorpaperlist as a1, citationlist, authorpaperlist as a2
WHERE
a1.paperid = citationlist.paperid1
AND citationlist.paperid2 = a2.paperid;

create view view20 as
select view14.authorid as authorid1, authorpaperlist.authorid as authorid2
FROM view14, authorpaperlist
WHERE
view14.p2 = authorpaperlist.paperid
ORDER BY authorid1, authorid2;

--1--
select DISTINCT a2.city as name
FROM (WITH RECURSIVE path (s, arr, d, carrier) AS
(
SELECT flights.originairportid, ARRAY[flights.originairportid], flights.destairportid, flights.carrier
FROM flights
UNION
SELECT path.s, array_append(path.arr, path.d), flights.destairportid, flights.carrier
FROM path, flights
WHERE path.d = flights.originairportid
AND path.carrier = flights.carrier
AND (NOT path.d = ANY(path.arr))
AND ((NOT flights.destairportid = ANY(path.arr)) OR flights.destairportid = path.s)
) 
SELECT *
FROM path) as foo, airports as a1, airports as a2
WHERE foo.s = a1.airportid
AND foo.d = a2.airportid
AND a1.city = 'Albuquerque'
AND a1.airportid = 10140
ORDER BY a2.city;

--2--
select DISTINCT a2.city as name
FROM (WITH RECURSIVE path (s, arr, d, dayofweek) AS
(
SELECT flights.originairportid, ARRAY[flights.originairportid], flights.destairportid, flights.dayofweek
FROM flights
UNION
SELECT path.s, array_append(path.arr, path.d), flights.destairportid, flights.dayofweek
FROM path, flights
WHERE path.d = flights.originairportid
AND path.dayofweek = flights.dayofweek
AND (NOT path.d = ANY(path.arr))
AND ((NOT flights.destairportid = ANY(path.arr)) OR flights.destairportid = path.s)
) 
SELECT *
FROM path) as foo, airports as a1, airports as a2
WHERE foo.s = a1.airportid
AND foo.d = a2.airportid
AND a1.city = 'Albuquerque'
AND a1.airportid = 10140
ORDER BY a2.city;

--3--
select a2.city as name
FROM (select foo.s, foo.d, COUNT(foo.arr)
FROM (WITH RECURSIVE path (s, arr, d) AS
(
SELECT flights.originairportid, ARRAY[flights.originairportid], flights.destairportid
FROM flights
UNION
SELECT path.s, array_append(path.arr, path.d), flights.destairportid
FROM path, flights
WHERE path.d = flights.originairportid
AND (NOT path.d = ANY(path.arr))
AND ((NOT flights.destairportid = ANY(path.arr)) OR flights.destairportid = path.s)
) 
SELECT *
FROM path) as foo
GROUP BY foo.s, foo.d) as foo, airports as a1, airports as a2
WHERE foo.d = a2.airportid AND foo.s = a1.airportid
AND foo.s = 10140 AND a1.city = 'Albuquerque'
AND foo.count = 1
ORDER BY a2.city;

--4--
select array_length(foo.arr, 1) as length
FROM (WITH RECURSIVE path (s, arr, d) AS
(
SELECT flights.originairportid, ARRAY[flights.originairportid], flights.destairportid
FROM flights
UNION
SELECT path.s, array_append(path.arr, path.d), flights.destairportid
FROM path, flights
WHERE path.d = flights.originairportid
AND (NOT path.d = ANY(path.arr))
AND ((NOT flights.destairportid = ANY(path.arr)) OR flights.destairportid = path.s)
) 
SELECT *
FROM path) as foo, airports
WHERE
foo.s = foo.d AND
foo.s = airports.airportid
AND airports.airportid = 10140
AND airports.city = 'Albuquerque'
ORDER BY length DESC
limit 1;

--5--
select array_length(foo.arr, 1) as length
FROM (WITH RECURSIVE path (s, arr, d) AS
(
SELECT flights.originairportid, ARRAY[flights.originairportid], flights.destairportid
FROM flights
UNION
SELECT path.s, array_append(path.arr, path.d), flights.destairportid
FROM path, flights
WHERE path.d = flights.originairportid
AND (NOT path.d = ANY(path.arr))
AND ((NOT flights.destairportid = ANY(path.arr)) OR flights.destairportid = path.s)
) 
SELECT *
FROM path) as foo, airports
WHERE
foo.s = foo.d AND
foo.s = airports.airportid
ORDER BY length DESC
limit 1;

--6--
select COUNT(DISTINCT foo.arr) as count
FROM (WITH RECURSIVE path (s, arr, d) AS
(
SELECT flights.originairportid, ARRAY[flights.originairportid], flights.destairportid
FROM flights, airports as a1, airports as a2
WHERE flights.originairportid = a1.airportid AND flights.destairportid = a2.airportid
AND a1.state != a2.state
UNION
SELECT path.s, array_append(path.arr, path.d), flights.destairportid
FROM path, flights, airports as a1, airports as a2
WHERE path.d = flights.originairportid
AND flights.originairportid = a1.airportid AND flights.destairportid = a2.airportid
AND a1.state != a2.state
AND (NOT path.d = ANY(path.arr))
AND ((NOT flights.destairportid = ANY(path.arr)) OR flights.destairportid = path.s)
) 
SELECT *
FROM path) as foo, airports as a1, airports as a2
WHERE
a1.city = 'Albuquerque' AND a2.city = 'Chicago'
AND foo.s = a1.airportid AND foo.d = a2.airportid;

--7--
select COUNT(foo.arr)
FROM (select DISTINCT foo.arr
FROM (WITH RECURSIVE path (s, arr, d) AS
(
SELECT flights.originairportid, ARRAY[flights.originairportid], flights.destairportid
FROM flights
UNION
SELECT path.s, array_append(path.arr, path.d), flights.destairportid
FROM path, flights
WHERE path.d = flights.originairportid
AND (NOT path.d = ANY(path.arr))
AND ((NOT flights.destairportid = ANY(path.arr)) OR flights.destairportid = path.s)
) 
SELECT *
FROM path) as foo, airports as a1, airports as a2, airports as a3
WHERE
a1.city = 'Albuquerque' AND a2.city = 'Chicago' AND a3.city = 'Washington'
AND foo.s = a1.airportid AND foo.d = a2.airportid
AND a3.airportid = ANY(foo.arr)
GROUP BY foo.arr) as foo;

--8--
select airports1.city as name1, airports2.city as name2
FROM (select airports1.airportid as c1, airports2.airportid as c2
FROM airports as airports1 cross join airports as airports2
WHERE
airports1.airportid != airports2.airportid
EXCEPT
select temp.s as c1, temp.d as c2
FROM (WITH RECURSIVE path (s, arr, d) AS
(
SELECT flights.originairportid, ARRAY[flights.originairportid], flights.destairportid
FROM flights
UNION
SELECT path.s, array_append(path.arr, path.d), flights.destairportid
FROM path, flights
WHERE path.d = flights.originairportid
AND (NOT path.d = ANY(path.arr))
AND ((NOT flights.destairportid = ANY(path.arr)) OR flights.destairportid = path.s)
) 
SELECT *
FROM path) as temp
WHERE temp.s != temp.d
GROUP BY temp.s, temp.d) as temp, airports as airports1, airports as airports2
WHERE
airports1.airportid = temp.c1
AND airports2.airportid = temp.c2
ORDER BY name1, name2;

--9--
select foo.day
FROM (select foo.dayofmonth as day, 0 as delay
FROM (select generate_series as dayofmonth
FROM generate_series(1, 31)
EXCEPT
select temp.dayofmonth
FROM (select flights.dayofmonth, (flights.arrivaldelay+flights.departuredelay) as delay
from flights, airports
WHERE flights.originairportid = airports.airportid
AND airports.city = 'Albuquerque') as temp
GROUP BY temp.dayofmonth) as foo
UNION
select temp.dayofmonth as day, SUM(temp.delay) as delay
FROM (select flights.dayofmonth, (flights.arrivaldelay+flights.departuredelay) as delay
from flights, airports
WHERE flights.originairportid = airports.airportid
AND airports.city = 'Albuquerque') as temp
GROUP BY temp.dayofmonth) as foo
ORDER BY foo.delay, foo.day;

--10--
select airports.city as name
FROM (select flights.originairportid, COUNT(DISTINCT flights.destairportid) as cnt
FROM flights, airports as a1, airports as a2
WHERE flights.originairportid = a1.airportid
AND flights.destairportid = a2.airportid
AND a1.state = 'New York' AND a2.state = 'New York'
AND a1.airportid != a2.airportid
GROUP BY flights.originairportid) as foo, airports
WHERE foo.cnt +1 = ALL(select COUNT(DISTINCT(airportid)) from airports where airports.state = 'New York')
AND foo.originairportid = airports.airportid
ORDER BY airports.city;

--11--
select DISTINCT a1.city as name1, a2.city as name2
from (WITH RECURSIVE path (s, arr, d, delay) AS
(SELECT flights.originairportid, ARRAY[flights.originairportid], flights.destairportid, (flights.arrivaldelay+flights.departuredelay) as delay
FROM flights
UNION
SELECT path.s, array_append(path.arr, path.d), flights.destairportid, (flights.arrivaldelay+flights.departuredelay) as delay
FROM path, flights
WHERE path.d = flights.originairportid
AND (flights.arrivaldelay+flights.departuredelay) >= path.delay
AND (NOT path.d = ANY(path.arr))
AND ((NOT flights.destairportid = ANY(path.arr)) OR flights.destairportid = path.s)
) 
SELECT *
FROM path) as foo, airports as a1, airports as a2
WHERE foo.s = a1.airportid
AND foo.d = a2.airportid
ORDER BY a1.city, a2.city;

--12--
select temp.d as authorid, temp.length as length
FROM (select temp.s, temp.d, -1 as length
from (select e1.authorid as s, e2.authorid as d
from authordetails as e1 cross join authordetails as e2
WHERE e1.authorid != e2.authorid
AND e1.authorid = 1235
EXCEPT
select view12.s, view12.d
from view12) as temp
UNION
select * from view12
) as temp
ORDER BY temp.length, temp.d;

--13--
SELECT CASE
WHEN temp.cnt > 0 THEN temp.cnt
WHEN temp.cnt = 0 THEN -1
END count
FROM (
select count(*) as cnt
FROM view13
) as temp;


--14--
select CASE
WHEN 704 not in (select conncompo.s from conncompo where conncompo.d = 102) THEN -1 
ELSE temp.count 
END count
FROM (
select COUNT(foo.arr) as count
FROM (WITH RECURSIVE path (s, arr, d, flag) AS
(
SELECT edge.authorid1, ARRAY[edge.authorid1], edge.authorid2 , 0
FROM edge
UNION
SELECT path.s, array_append(path.arr, path.d), edge.authorid2, CASE
WHEN path.flag = 1 THEN 1
WHEN (edge.authorid1 IN (select view14.authorid from view14 where view14.p2 = 126)) THEN 1
ELSE 0
END flag
FROM path, edge
WHERE path.d = edge.authorid1
AND (NOT path.d = ANY(path.arr))
AND ((NOT edge.authorid2 = ANY(path.arr)) OR edge.authorid2 = path.s)
) 
SELECT *
FROM path) as foo
WHERE foo.flag = 1
AND foo.s = 704 AND foo.d = 102) as temp;


--15--
select CASE
WHEN 1745 not in (select conncompo.s from conncompo where conncompo.d = 456) THEN -1
ELSE COUNT(DISTINCT foo.arr)
END count
FROM (select foo.s, foo.arr, foo.d
FROM (WITH RECURSIVE path (s, arr, d) AS
(
SELECT edge.authorid1, ARRAY[edge.authorid1], edge.authorid2
FROM edge
UNION
SELECT path.s, array_append(path.arr, path.d), edge.authorid2
FROM path, edge, citations as c1, citations as c2
WHERE path.d = edge.authorid1
AND c1.authorid = edge.authorid1 AND c2.authorid = edge.authorid2
AND (c1.sum < c2.sum OR edge.authorid2 = 456)
AND (NOT path.d = ANY(path.arr))
AND ((NOT edge.authorid2 = ANY(path.arr)) OR edge.authorid2 = path.s)
) 
SELECT *
FROM path) as foo
UNION
select temp.s, temp.arr, temp.d
FROM (WITH RECURSIVE path (s, arr, d) AS
(
SELECT edge.authorid1, ARRAY[edge.authorid1], edge.authorid2
FROM edge
UNION
SELECT path.s, array_append(path.arr, path.d), edge.authorid2
FROM path, edge, citations as c1, citations as c2
WHERE path.d = edge.authorid1
AND c1.authorid = edge.authorid1 AND c2.authorid = edge.authorid2
AND (c1.sum > c2.sum OR edge.authorid2 = 456)
AND (NOT path.d = ANY(path.arr))
AND ((NOT edge.authorid2 = ANY(path.arr)) OR edge.authorid2 = path.s)
) 
SELECT *
FROM path) as temp) as foo
WHERE
foo.s = 1745 AND foo.d = 456;



--16--
select foo.authorid
FROM (select foo.authorid, 0 as count
from (select authordetails.authorid
from authordetails
EXCEPT
select foo.authorid
FROM (select foo.authorid, COUNT(DISTINCT authorpaperlist.authorid)
from
(select view14.authorid, view14.p2
from view14
group by view14.authorid, view14.p2) as foo, authorpaperlist
WHERE foo.p2 = authorpaperlist.paperid
AND foo.authorid != authorpaperlist.authorid
AND foo.authorid NOT IN (select edge.authorid1 from edge where edge.authorid2 = authorpaperlist.authorid)
GROUP BY foo.authorid) as foo) as foo
UNION
select foo.authorid, COUNT(authorpaperlist.authorid)
from
(select view14.authorid, view14.p2
from view14
group by view14.authorid, view14.p2) as foo, authorpaperlist
WHERE foo.p2 = authorpaperlist.paperid
AND foo.authorid != authorpaperlist.authorid
AND foo.authorid NOT IN (select edge.authorid1 from edge where edge.authorid2 = authorpaperlist.authorid)
GROUP BY foo.authorid) as foo
ORDER BY count DESC, authorid
limit 10;

--17--
select foo.authorid
FROM (select temp.authorid, 0 as sum
FROM (select authordetails.authorid from authordetails
EXCEPT 
select view17.authorid from view17) as temp
UNION
select view17.authorid, view17.sum
from view17) as foo
ORDER BY foo.sum DESC, foo.authorid
limit 10;

--18--
select CASE 
WHEN 3552 not in (select conncompo.s from conncompo where conncompo.d = 321) THEN -1
ELSE COUNT(DISTINCT foo.arr)
END count
FROM (select foo.arr
FROM (WITH RECURSIVE path (s, arr, d, flag) AS
(
SELECT edge.authorid1, ARRAY[edge.authorid1], edge.authorid2, 0 as flag
FROM edge
UNION
SELECT path.s, array_append(path.arr, path.d), edge.authorid2, CASE
WHEN path.flag = 1 THEN 1
WHEN edge.authorid1 = 1436 OR edge.authorid1 = 562 OR edge.authorid1 = 921 THEN 1
ELSE 0
END flag
FROM path, edge
WHERE path.d = edge.authorid1
AND (NOT path.d = ANY(path.arr))
AND ((NOT edge.authorid2 = ANY(path.arr)) OR edge.authorid2 = path.s)
) 
SELECT *
FROM path) as foo
WHERE foo.flag = 1
AND foo.s = 3552 AND foo.d = 321) as foo;

--19--
select CASE
WHEN 
3552 not in (select conncompo.s from conncompo where conncompo.d = 321) THEN -1
ELSE COUNT(DISTINCT foo.arr)
END count
FROM (WITH RECURSIVE path (s, arr, cities, d) AS
(
SELECT edge.authorid1, ARRAY[edge.authorid1], ARRAY[authordetails.city], edge.authorid2
FROM edge, authordetails
WHERE edge.authorid1 = authordetails.authorid
UNION
SELECT path.s, array_append(path.arr, path.d), array_append(path.cities, authordetails.city), edge.authorid2
FROM path, edge, authordetails
WHERE path.d = edge.authorid1
AND edge.authorid1 = authordetails.authorid
AND (NOT authordetails.city = ANY(path.cities))
AND (NOT edge.authorid1 IN (select authorid1 from view19 where authorid2 = ANY(path.arr) AND authorid2 != 3552))
AND (NOT path.d = ANY(path.arr))
AND ((NOT edge.authorid2 = ANY(path.arr)) OR edge.authorid2 = path.s)
) 
SELECT *
FROM path) as foo
WHERE
foo.s = 3552 AND foo.d = 321; 

--20--
select CASE
WHEN 
3552 not in (select conncompo.s from conncompo where conncompo.d = 321) THEN -1
ELSE COUNT(DISTINCT foo.arr)
END count
FROM (WITH RECURSIVE path (s, arr, d) AS
(
SELECT edge.authorid1, ARRAY[edge.authorid1], edge.authorid2
FROM edge
UNION
SELECT path.s, array_append(path.arr, path.d), edge.authorid2
FROM path, edge
WHERE path.d = edge.authorid1
AND (NOT edge.authorid1 IN (select authorid1 from view20 where authorid2 = ANY(path.arr) AND authorid2 != 3552))
AND (NOT edge.authorid1 IN (select authorid2 from view20 where authorid1 = ANY(path.arr) AND authorid1 != 3552))
AND (NOT path.d = ANY(path.arr))
AND ((NOT edge.authorid2 = ANY(path.arr)) OR edge.authorid2 = path.s)
) 
SELECT *
FROM path) as foo
WHERE 
foo.s = 3552 AND foo.d = 321;

--21--
select foo.conf as conferencename, COUNT(foo.cc) as count
FROM (select DISTINCT foo.conf, foo.cc
FROM (select foo.conf, foo.s, ARRAY_AGG(foo.d) as cc
FROM (select DISTINCT foo.s, foo.d, foo.conf
FROM (WITH RECURSIVE path (s, arr, d, conf) AS
(
SELECT edge2.authorid1, ARRAY[edge2.authorid1], edge2.authorid2, edge2.conf
FROM edge2
UNION
SELECT path.s, array_append(path.arr, path.d), edge2.authorid2, path.conf
FROM path, edge2
WHERE path.d = edge2.authorid1
AND edge2.conf = path.conf
AND (NOT path.d = ANY(path.arr))
AND ((NOT edge2.authorid2 = ANY(path.arr)) OR edge2.authorid2 = path.s)
) 
SELECT *
FROM path) as foo
ORDER BY foo.conf, foo.s, foo.d) as foo
GROUP BY foo.conf, foo.s) as foo) as foo
GROUP BY foo.conf;

--22--
select foo.conf as conferencename, array_length(foo.cc, 1) as count
FROM (select DISTINCT foo.conf, foo.cc
FROM (select foo.conf, foo.s, ARRAY_AGG(foo.d) as cc
FROM (select DISTINCT foo.s, foo.d, foo.conf
FROM (WITH RECURSIVE path (s, arr, d, conf) AS
(
SELECT edge2.authorid1, ARRAY[edge2.authorid1], edge2.authorid2, edge2.conf
FROM edge2
UNION
SELECT path.s, array_append(path.arr, path.d), edge2.authorid2, path.conf
FROM path, edge2
WHERE path.d = edge2.authorid1
AND edge2.conf = path.conf
AND (NOT path.d = ANY(path.arr))
AND ((NOT edge2.authorid2 = ANY(path.arr)) OR edge2.authorid2 = path.s)
) 
SELECT *
FROM path) as foo
ORDER BY foo.conf, foo.s, foo.d) as foo
GROUP BY foo.conf, foo.s) as foo) as foo
ORDER BY count, foo.conf;

--CLEANUP--
DROP VIEW view20;
DROP VIEW view19;
DROP VIEW view17;
DROP VIEW view14;
DROP VIEW view13;
DROP VIEW view12;
DROP VIEW edge2;
DROP VIEW citations;
DROP VIEW conncompo;
DROP VIEW edge;