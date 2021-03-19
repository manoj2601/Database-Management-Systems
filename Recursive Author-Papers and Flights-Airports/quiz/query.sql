create table airports
(                        
airportid int PRIMARY KEY,
city varchar(50),
state varchar(50),
name varchar(50));

insert into airports values (1, 'New Delhi', 'Delhi', 'Indira Gandhi Airport'), (2, 'Mumbai', 'Delhi', 'Chhatrapati Shivaji Airport'),  (3, 'Jaipur', 'Rajasthan', 'Jaipur International Airport'), (4, 'Karachi', 'Pakistan', 'Karachi Airport');

create table flights (
flightid int PRIMARY KEY,
originairportid int,
destairportid int,
carrier varchar(50),
dayofmonth int,
dayofweek int,
departuredelay int,
arrivaldelay int);


insert into flights values
(1, 3, 1, 'Airindia', 1, 1, 5, 5),
(2, 1, 2, 'Airindia', 2, 2, 5, 15),
(3, 2, 1, 'Airindia', 9, 2, 5, 10),
(4, 1, 4, 'Indigo', 10, 3, 10, 10),
(5, 2, 4, 'Indigo', 11, 4, 1, 1),
(6, 4, 1, 'Indigo', 1, 1, 5, 5);

--FOR Dataset 1--
WITH RECURSIVE path (s, arr, d) AS
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
FROM path


--For Dataset 2--
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
SELECT *
FROM path



CREATE VIEW edge AS
    SELECT ap1.authorid AS authorid1, ap2.authorid AS authorid2
    FROM authorpaperlist AS ap1
    JOIN authorpaperlist AS ap2
        ON ap1.paperid = ap2.paperid
    WHERE ap1.authorid != ap2.authorid;


--1--
select MIN(del) as time
FROM (select foo.s, unnest(foo.delay) as del, foo.d
FROM (WITH RECURSIVE path (s, arr, delay, d) AS
(
SELECT flights.originairportid, ARRAY[flights.originairportid], ARRAY[flights.arrivaldelay+flights.departuredelay], flights.destairportid
FROM flights
UNION
SELECT path.s, array_append(path.arr, path.d), array_append(path.delay, flights.arrivaldelay+flights.departuredelay), flights.destairportid
FROM path, flights
WHERE path.d = flights.originairportid
AND (NOT path.d = ANY(path.arr))
AND ((NOT flights.destairportid = ANY(path.arr)) OR flights.destairportid = path.s)
) 
SELECT *
FROM path) as foo, airports as a1, airports as a2
WHERE
foo.s = a1.airportid AND foo.d = a2.airportid
AND a1.city = 'Albuquerque' AND a2.city = 'Chicago') as foo
GROUP BY foo.s, foo.d;


--2--

CREATE VIEW edge AS
SELECT ap1.authorid AS authorid1, ap2.authorid AS authorid2, paperdetails.conferencename as conf
FROM authorpaperlist AS ap1, authorpaperlist AS ap2, paperdetails
WHERE ap1.paperid = ap2.paperid
AND ap1.authorid != ap2.authorid
AND ap1.paperid = paperdetails.paperid;

select COUNT(foo.arr) as count
FROM (WITH RECURSIVE path (s, arr, conf, d) AS
(
SELECT edge.authorid1, ARRAY[edge.authorid1], edge.conf, edge.authorid2
FROM (
	SELECT ap1.authorid AS authorid1, ap2.authorid AS authorid2, paperdetails.conferencename as conf
FROM authorpaperlist AS ap1, authorpaperlist AS ap2, paperdetails
WHERE ap1.paperid = ap2.paperid
AND ap1.authorid != ap2.authorid
AND ap1.paperid = paperdetails.paperid
) as edge
UNION
SELECT path.s, array_append(path.arr, path.d), path.conf, edge.authorid2
FROM path, (
SELECT ap1.authorid AS authorid1, ap2.authorid AS authorid2, paperdetails.conferencename as conf
FROM authorpaperlist AS ap1, authorpaperlist AS ap2, paperdetails
WHERE ap1.paperid = ap2.paperid
AND ap1.authorid != ap2.authorid
AND ap1.paperid = paperdetails.paperid
) as edge
WHERE path.d = edge.authorid1
AND path.conf = edge.conf
AND (NOT path.d = ANY(path.arr))
AND ((NOT edge.authorid2 = ANY(path.arr)) OR edge.authorid2 = path.s)
) 
SELECT *
FROM path) as foo
WHERE foo.s = 1 AND foo.d = 5
GROUP BY foo.s, foo.d, foo.conf;



--3--
select COUNT(foo.arr) as num_paths
FROM (WITH RECURSIVE path (s, arr, d, day) AS
(
SELECT flights.originairportid, ARRAY[flights.originairportid], flights.destairportid, flights.dayofweek
FROM flights
UNION
SELECT path.s, array_append(path.arr, path.d), flights.destairportid,
CASE
WHEN (path.day = 7) THEN 1
ELSE (flights.dayofweek)
END 

FROM path, flights
WHERE path.d = flights.originairportid
AND (path.day +1 = flights.dayofweek OR (path.day = 7 AND flights.dayofweek = 1))
AND (NOT path.d = ANY(path.arr))
AND ((NOT flights.destairportid = ANY(path.arr)) OR flights.destairportid = path.s)
) 
SELECT *
FROM path) as foo, airports
WHERE foo.s = airports.airportid
AND airports.city = 'Albuquerque'
AND array_length(foo.arr, 1) = 7;