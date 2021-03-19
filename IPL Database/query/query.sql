--1--
SELECT temp2.match_id, temp2.player_name, team.team_name, temp2.num_wickets
FROM (SELECT temp.match_id, player.player_name, temp.team_id, temp.num_wickets
FROM (SELECT FOO.match_id, FOO.bowler, player_match.team_id, FOO.num_wickets
FROM (SELECT wicket_taken.match_id, bowler, COUNT(bowler) AS num_wickets
FROM wicket_taken join ball_by_ball
ON wicket_taken.match_id = ball_by_ball.match_id AND wicket_taken.over_id = ball_by_ball.over_id AND wicket_taken.ball_id = ball_by_ball.ball_id AND wicket_taken.innings_no = ball_by_ball.innings_no AND wicket_taken.kind_out != 3 AND wicket_taken.kind_out != 5 AND wicket_taken.kind_out != 9
GROUP BY wicket_taken.match_id, bowler
) AS FOO join player_match
ON player_match.match_id = FOO.match_id AND player_match.player_id = FOO.bowler
) AS temp join player
ON player.player_id = temp.bowler) AS temp2 join team
ON temp2.team_id = team.team_id AND temp2.num_wickets > 4
ORDER BY temp2.num_wickets DESC, temp2.player_name, temp2.match_id;

--2--
SELECT player.player_name, foo.num_matches
FROM (
SELECT player_match.player_id, COUNT (player_match.player_id) AS num_matches
FROM match join player_match
ON
match.match_id = player_match.match_id
AND 
match.man_of_the_match = player_match.player_id
AND 
match.match_winner != player_match.team_id
GROUP BY player_match.player_id
) as FOO join player
ON foo.player_id = player.player_id
ORDER BY foo.num_matches DESC, player.player_name
limit 3;

--3--
select player.player_name
from match, wicket_taken, player
WHERE
match.season_id = 5
AND
match.match_id = wicket_taken.match_id
AND
wicket_taken.kind_out = 1
AND
wicket_taken.fielders = player.player_id
GROUP BY player.player_name
ORDER BY COUNT(player.player_name) DESC, player.player_name
limit 1;

--4--
SELECT season.season_year, player.player_name, COUNT (player_match.player_id) as num_matches
FROM season, match, player_match, player
WHERE
season.season_id = match.season_id
AND
match.match_id = player_match.match_id
AND
season.purple_cap = player_match.player_id AND player_match.player_id = player.player_id
GROUP BY season.season_year, player.player_name
ORDER BY season.season_year;

--5--
SELECT DISTINCT player.player_name as player_name
FROM
(select match.match_id, ball_by_ball.striker, SUM( batsman_scored.runs_scored) as total
FROM match, ball_by_ball, batsman_scored
WHERE match.match_id = ball_by_ball.match_id
AND match.match_id = batsman_scored.match_id
AND match.match_winner = ball_by_ball.team_bowling
AND batsman_scored.over_id = ball_by_ball.over_id
AND batsman_scored.ball_id = ball_by_ball.ball_id
AND batsman_scored.innings_no < 3
AND batsman_scored.innings_no = ball_by_ball.innings_no
GROUP BY match.match_id, ball_by_ball.striker) AS foo, player
WHERE
foo.striker = player.player_id
AND
foo.total > 50
ORDER BY player.player_name;

--6--
select season.season_year, foo2.team_name, foo2.rank
FROM
(
SELECT foo.season_id, team.team_name, COUNT(foo.player_name) as cnt,
ROW_NUMBER() OVER (PARTITION BY foo.season_id ORDER BY COUNT(foo.player_name) DESC, team.team_name) rank 
FROM
(
SELECT DISTINCT ON (match.season_id, player_match.team_id, player_match.player_id)
match.season_id, player_match.team_id, player.player_name
FROM
match, player_match, player
WHERE
match.match_id = player_match.match_id
AND
player_match.player_id = player.player_id
AND
player.batting_hand = 1
AND
player.country_id != 1
) AS foo, team
WHERE
foo.team_id = team.team_id
GROUP BY foo.season_id, team.team_name
ORDER BY foo.season_id, cnt DESC, team.team_name
) as foo2, season
WHERE
foo2.season_id = season.season_id
AND
foo2.rank < 6
ORDER BY season.season_id, rank;

--7--
select team.team_name
from match, team
WHERE match.season_id = 2
AND match.match_winner = team.team_id
GROUP BY team.team_name
ORDER BY COUNT(match.match_winner) DESC, team.team_name;

--8--
select DISTINCT ON (foo.team_name) foo.team_name, foo.player_name, foo.runs
FROM (
select player.player_name, SUM(batsman_scored.runs_scored) as runs, team.team_name
FROM match, ball_by_ball, batsman_scored, team, player, player_match
WHERE
match.season_id = 3
AND
match.match_id = ball_by_ball.match_id
AND
match.match_id = batsman_scored.match_id
AND
batsman_scored.over_id = ball_by_ball.over_id
AND
batsman_scored.ball_id = ball_by_ball.ball_id
AND
batsman_scored.innings_no < 3
AND
batsman_scored.innings_no = ball_by_ball.innings_no
AND
ball_by_ball.striker = player_match.player_id
AND
match.match_id = player_match.match_id
AND
player_match.team_id = team.team_id
AND
player_match.player_id = player.player_id
GROUP BY player.player_name, team.team_name
ORDER BY runs DESC, player.player_name
) as foo
ORDER BY foo.team_name, foo.runs DESC;

--9--
select foo.team_name, team.team_name as opponent_team_name, foo.number_of_sixes
FROM (
select team.team_name, ball_by_ball.team_bowling, COUNT(batsman_scored.runs_scored) as number_of_sixes
FROM match, ball_by_ball, batsman_scored, team
WHERE
match.season_id = 1
AND
match.match_id = ball_by_ball.match_id
AND
ball_by_ball.match_id = batsman_scored.match_id
AND
ball_by_ball.over_id = batsman_scored.over_id
AND
ball_by_ball.ball_id = batsman_scored.ball_id
AND
ball_by_ball.innings_no = batsman_scored.innings_no
AND
batsman_scored.runs_scored = 6
AND ball_by_ball.team_batting = team.team_id
GROUP BY team.team_name, match.match_id, ball_by_ball.team_bowling
ORDER BY number_of_sixes DESC, team.team_name
) AS foo, team
WHERE foo.team_bowling = team.team_id
limit 3;

--10--
select last.bowling_skill as  bowling_category, last.player_name, ROUND(last.batavg::numeric,2) as batting_average
FROM (select final1.player_id, final1.batavg, player.player_name, final2.bowling_skill, ROW_NUMBER() OVER (PARTITION BY final2.bowling_skill ORDER BY final1.batavg DESC, player.player_name) rank 
FROM (
select foo.player_id, AVG(foo.runs) as batavg
FROM
(select ball_by_ball.striker AS player_id, SUM(batsman_scored.runs_scored) as runs
FROM ball_by_ball, batsman_scored
WHERE
batsman_scored.match_id = ball_by_ball.match_id
AND
batsman_scored.over_id = ball_by_ball.over_id
AND
batsman_scored.ball_id = ball_by_ball.ball_id
AND
batsman_scored.innings_no = ball_by_ball.innings_no
AND
batsman_scored.innings_no < 3
GROUP BY ball_by_ball.striker, ball_by_ball.match_id
) as foo
GROUP BY foo.player_id
) as final1,
(
select temp1.bowling_skill, temp1.bowler
FROM (select bowling_style.bowling_skill, ball_by_ball.bowler, COUNT(ball_by_ball.bowler) AS tw
FROM ball_by_ball, wicket_taken, player, bowling_style
WHERE
ball_by_ball.match_id = wicket_taken.match_id
AND
ball_by_ball.over_id = wicket_taken.over_id
AND
ball_by_ball.ball_id = wicket_taken.ball_id
AND
wicket_taken.kind_out != 3
AND
wicket_taken.kind_out != 5
AND
wicket_taken.kind_out != 9
AND
ball_by_ball.innings_no = wicket_taken.innings_no
AND
ball_by_ball.innings_no < 3
AND
ball_by_ball.bowler = player.player_id
AND
player.bowling_skill = bowling_style.bowling_id
GROUP BY ball_by_ball.bowler, bowling_style.bowling_skill
ORDER BY bowling_style.bowling_skill) as temp1, (
select AVG(foo.tw) as avgwk
FROM 
(
select COUNT(ball_by_ball.bowler) AS tw
FROM ball_by_ball, wicket_taken, player, bowling_style
WHERE
ball_by_ball.match_id = wicket_taken.match_id
AND
ball_by_ball.over_id = wicket_taken.over_id
AND
ball_by_ball.ball_id = wicket_taken.ball_id
AND
wicket_taken.kind_out != 3
AND
wicket_taken.kind_out != 5
AND
wicket_taken.kind_out != 9
AND
ball_by_ball.innings_no = wicket_taken.innings_no
AND
ball_by_ball.innings_no < 3
AND
ball_by_ball.bowler = player.player_id
AND
player.bowling_skill = bowling_style.bowling_id
GROUP BY ball_by_ball.bowler
) as foo
)as temp2
WHERE
temp1.tw > temp2.avgwk
) as final2, player
WHERE final1.player_id = final2.bowler
AND final1.player_id = player.player_id
ORDER BY final1.batavg DESC) as last
WHERE last.rank = 1
ORDER BY last.bowling_skill, last.player_name;

--11--
select f1.season_year, f1.player_name, f2.wcks as num_wickets, f1.runs
FROM 
(
select temp1.season_year, temp1.player_name, temp1.runs
FROM (
select season.season_year, player.player_name, SUM(batsman_scored.runs_scored) as runs
from match, ball_by_ball, batsman_scored, player, season
WHERE
match.match_id = ball_by_ball.match_id
AND ball_by_ball.match_id = batsman_scored.match_id
AND ball_by_ball.over_id = batsman_scored.over_id
AND ball_by_ball.ball_id = batsman_scored.ball_id
AND ball_by_ball.innings_no = batsman_scored.innings_no
AND ball_by_ball.innings_no < 3
AND ball_by_ball.striker = player.player_id
AND player.batting_hand = 1
AND match.season_id = season.season_id
GROUP BY season.season_year, player.player_name
) as temp1
WHERE
temp1.runs > 149
ORDER BY temp1.season_year, temp1.player_name
) as f1,
(
select temp2.season_year, temp2.player_name, temp2.wcks
FROM (select season.season_year, player.player_name, COUNT (ball_by_ball.bowler) wcks
FROM match, ball_by_ball, wicket_taken, player, season
WHERE
match.match_id = ball_by_ball.match_id
AND ball_by_ball.match_id = wicket_taken.match_id
AND ball_by_ball.over_id = wicket_taken.over_id
AND ball_by_ball.ball_id = wicket_taken.ball_id
AND ball_by_ball.innings_no = wicket_taken.innings_no
AND ball_by_ball.innings_no < 3
AND wicket_taken.kind_out != 3 AND wicket_taken.kind_out != 5 AND wicket_taken.kind_out != 9
AND ball_by_ball.bowler = player.player_id
AND match.season_id = season.season_id
AND player.batting_hand = 1
GROUP BY season.season_year, player.player_name) as temp2
WHERE
temp2.wcks > 4
) as f2, 
(
select season.season_year, player.player_name, COUNT(player.player_name) as freq
FROM match, player_match, player, season
WHERE
match.season_id = season.season_id
AND match.match_id = player_match.match_id
AND player_match.player_id = player.player_id
AND player.batting_hand = 1
GROUP BY season.season_year, player.player_name
) as f3
WHERE
f1.season_year = f2.season_year
AND f1.season_year = f3.season_year
AND f1.player_name = f2.player_name
AND f1.player_name = f3.player_name
AND f3.freq > 9
ORDER BY num_wickets DESC, f1.runs DESC, f1.player_name;

--12--
select match.match_id, player.player_name, team.team_name, COUNT(match.match_id) as num_wickets, season.season_year
from match, ball_by_ball, wicket_taken, player, team, season
WHERE
match.match_id = ball_by_ball.match_id
AND
ball_by_ball.match_id = wicket_taken.match_id
AND
ball_by_ball.over_id = wicket_taken.over_id
AND
ball_by_ball.ball_id = wicket_taken.ball_id
AND
ball_by_ball.innings_no = wicket_taken.innings_no
AND
wicket_taken.kind_out != 3 AND wicket_taken.kind_out != 5 AND wicket_taken.kind_out != 9
AND
ball_by_ball.bowler = player.player_id
AND
ball_by_ball.team_bowling = team.team_id
AND
match.season_id = season.season_id
GROUP BY match.match_id, player.player_name, team.team_name, season.season_year
ORDER BY num_wickets DESC, player_name, match.match_id
limit 1;

--13--
select foo2.player_name
FROM (select foo.player_name, COUNT(foo.player_name) as freq
FROM (select player.player_name
FROM match, player_match, player
WHERE
match.match_id = player_match.match_id
AND
player_match.player_id = player.player_id
GROUP BY player.player_name, match.season_id
ORDER BY player.player_name) as foo
GROUP BY foo.player_name) as foo2
WHERE
foo2.freq = 9
ORDER BY foo2.player_name;

--14--
select season.season_year, foo2.match_id, foo2.team_name
FROM (select foo.season_id, foo.match_id, team.team_name, COUNT(team.team_name) as freq, ROW_NUMBER() OVER (PARTITION BY foo.season_id ORDER BY COUNT(team.team_name) DESC, team.team_name, foo.match_id) rank 
FROM (select match.season_id, ball_by_ball.team_batting as team_name, match.match_id, ball_by_ball.striker, SUM(batsman_scored.runs_scored) as runs
FROM match, ball_by_ball, batsman_scored
WHERE
match.match_id = ball_by_ball.match_id
AND ball_by_ball.match_id = batsman_scored.match_id
AND ball_by_ball.over_id = batsman_scored.over_id
AND ball_by_ball.ball_id = batsman_scored.ball_id
AND ball_by_ball.innings_no = batsman_scored.innings_no
AND ball_by_ball.innings_no < 3
AND match.match_winner = ball_by_ball.team_batting
GROUP BY match.season_id, team_name, match.match_id, ball_by_ball.striker) as foo, team
WHERE foo.runs > 49
AND foo.team_name = team.team_id
GROUP BY foo.season_id, foo.match_id, team.team_name
ORDER BY foo.season_id, freq DESC, team.team_name) AS foo2, season
WHERE
foo2.rank < 4
AND
foo2.season_id = season.season_id
ORDER BY 
season.season_year, foo2.rank;

--15--
select season.season_year, temp1.top_batsman, temp1.max_runs, temp2.top_bowler, temp2.max_wickets
FROM (
select foo2.season_id, foo2.player_name as top_batsman, foo2.runs as max_runs
FROM (select foo.season_id, player.player_name, foo.runs, ROW_NUMBER() OVER (PARTITION BY foo.season_id ORDER BY foo.runs DESC, player.player_name) as rank
FROM (select match.season_id, ball_by_ball.striker, SUM(batsman_scored.runs_scored) as runs
from match, ball_by_ball, batsman_scored
WHERE
match.match_id = ball_by_ball.match_id
AND ball_by_ball.match_id = batsman_scored.match_id
AND ball_by_ball.over_id = batsman_scored.over_id
AND ball_by_ball.ball_id = batsman_scored.ball_id
AND ball_by_ball.innings_no = batsman_scored.innings_no
AND ball_by_ball.innings_no < 3
GROUP BY match.season_id, ball_by_ball.striker
ORDER BY match.season_id, runs DESC) as foo, player
WHERE
foo.striker = player.player_id) as foo2
WHERE
foo2.rank = 2) as temp1,
(select foo3.season_id, foo3.top_bowler, foo3.max_wickets
FROM (select match.season_id, player.player_name as top_bowler, COUNT(ball_by_ball.bowler) as max_wickets, ROW_NUMBER() OVER (PARTITION BY match.season_id ORDER BY COUNT(ball_by_ball.bowler) DESC, player.player_name) as rank
FROM match, ball_by_ball, wicket_taken, player
WHERE
match.match_id = ball_by_ball.match_id
AND ball_by_ball.match_id = wicket_taken.match_id
AND ball_by_ball.over_id = wicket_taken.over_id
AND ball_by_ball.ball_id = wicket_taken.ball_id
AND ball_by_ball.innings_no = wicket_taken.innings_no
AND ball_by_ball.bowler = player.player_id
AND wicket_taken.kind_out != 3 AND wicket_taken.kind_out != 5 AND wicket_taken.kind_out != 9
GROUP BY match.season_id, player.player_name) as foo3
WHERE
foo3.rank = 2) as temp2, season
WHERE
temp1.season_id = temp2.season_id
AND temp1.season_id = season.season_id;

--16--
select team.team_name
FROM match, team
where 
match.season_id = 1
AND match.match_winner != 2
AND (match.team_1 = 2 OR match.team_2 = 2)
AND match.match_winner = team.team_id
GROUP BY team.team_name
ORDER BY COUNT(team.team_name) DESC, team.team_name;

--17--
select team.team_name, foo.player_name, foo.count
FROM (select player.player_name, player_match.team_id, COUNT(match.man_of_the_match) as count, ROW_NUMBER() OVER (PARTITION BY player_match.team_id ORDER BY COUNT(match.man_of_the_match) DESC, player.player_name) as rank
FROM match, player_match, player
WHERE
match.match_id = player_match.match_id
AND match.man_of_the_match = player_match.player_id
AND player_match.player_id = player.player_id
GROUP BY player.player_name, player_match.team_id) as foo, team
WHERE
foo.team_id = team.team_id
AND
foo.rank = 1
ORDER BY team.team_name, foo.player_name;

--18--
select player.player_name
FROM (select foo.player_id, foo.dteams
FROM (select player_match.player_id, COUNT(DISTINCT (player_match.team_id)) as dteams
FROM player_match
GROUP BY player_match.player_id) as foo
WHERE
foo.dteams > 2) as temp1,
(select foo2.bowler, COUNT(foo2.bowler) as cnt
FROM (select ball_by_ball.bowler, ball_by_ball.match_id, ball_by_ball.over_id, ball_by_ball.innings_no, SUM(batsman_scored.runs_scored) as runs
FROM match, ball_by_ball, batsman_scored
WHERE
match.match_id = ball_by_ball.match_id
AND ball_by_ball.match_id = batsman_scored.match_id
AND ball_by_ball.over_id = batsman_scored.over_id
AND ball_by_ball.ball_id = batsman_scored.ball_id
AND ball_by_ball.innings_no = batsman_scored.innings_no
GROUP BY ball_by_ball.bowler, ball_by_ball.match_id, ball_by_ball.over_id, ball_by_ball.innings_no) as foo2
WHERE foo2.runs > 20
GROUP BY foo2.bowler) as temp2, player 
WHERE
temp1.player_id = temp2.bowler
AND temp1.player_id = player.player_id
ORDER BY temp2.cnt DESC, player.player_name
limit 5;

--19--
select team.team_name, ROUND(AVG(foo.runs)::numeric,2) as avg_runs
FROM (select ball_by_ball.team_batting, SUM(batsman_scored.runs_scored) as runs
FROM match, ball_by_ball, batsman_scored
WHERE
match.match_id = ball_by_ball.match_id
AND match.season_id = 3
AND ball_by_ball.match_id = batsman_scored.match_id
AND ball_by_ball.over_id = batsman_scored.over_id
AND ball_by_ball.ball_id = batsman_scored.ball_id
AND ball_by_ball.innings_no = batsman_scored.innings_no
AND ball_by_ball.innings_no < 3
GROUP BY match.match_id, ball_by_ball.team_batting) as foo, team
WHERE foo.team_batting = team.team_id
GROUP BY team.team_name
ORDER BY team.team_name;

--20--
select player.player_name as player_names
FROM match, ball_by_ball, wicket_taken, player
WHERE
match.match_id = ball_by_ball.match_id
AND ball_by_ball.match_id = wicket_taken.match_id
AND wicket_taken.over_id = ball_by_ball.over_id
ANd wicket_taken.ball_id = ball_by_ball.ball_id
AND wicket_taken.innings_no = ball_by_ball.innings_no
AND wicket_taken.over_id = 1 AND wicket_taken.innings_no < 3
AND wicket_taken.player_out = player.player_id
GROUP BY player.player_name
ORDER BY COUNT(ball_by_ball.striker) DESC, player.player_name
limit 10;

--21--
select temp2.match_id, team.team_name as team_1_name, temp2.team_2_name, temp2.match_winner_name, temp2.number_of_boundaries
FROM (select temp1.match_id, temp1.team_1, team.team_name as team_2_name, temp1.match_winner_name, temp1.number_of_boundaries
FROM (select match.match_id, match.team_1, match.team_2, team.team_name as match_winner_name, COUNT(match.match_id) as number_of_boundaries
from match, ball_by_ball, batsman_scored, team
WHERE
match.match_id = ball_by_ball.match_id
AND ball_by_ball.match_id = batsman_scored.match_id
AND ball_by_ball.over_id = batsman_scored.over_id
AND ball_by_ball.ball_id = batsman_scored.ball_id
AND ball_by_ball.innings_no = batsman_scored.innings_no
AND ball_by_ball.innings_no = 2
AND match.outcome_id != 2
AND ball_by_ball.team_batting = match.match_winner
AND (batsman_scored.runs_scored = 4 OR batsman_scored.runs_scored = 6 OR batsman_scored.runs_scored = 5 OR batsman_scored.runs_scored = 7)
AND team.team_id = match.match_winner
GROUP BY match.match_id, match.team_1, match.team_2, team.team_name
ORDER BY number_of_boundaries, team.team_name
limit 3) as temp1, team
WHERE
temp1.team_2 = team.team_id) AS temp2, team
WHERE
temp2.team_1 = team.team_id;

--22--
select country.country_name
FROM(
select ball_by_ball.bowler, SUM(batsman_scored.runs_scored) as runs
from match, ball_by_ball, batsman_scored
WHERE
match.match_id = ball_by_ball.match_id
AND ball_by_ball.match_id = batsman_scored.match_id
AND ball_by_ball.over_id = batsman_scored.over_id
AND ball_by_ball.ball_id = batsman_scored.ball_id
AND ball_by_ball.innings_no = batsman_scored.innings_no
AND ball_by_ball.innings_no < 3
GROUP BY ball_by_ball.bowler) as temp1, (
select ball_by_ball.bowler, COUNT(ball_by_ball.bowler) as wcks
FROM match, ball_by_ball, wicket_taken
WHERE
match.match_id = ball_by_ball.match_id
AND ball_by_ball.match_id = wicket_taken.match_id
AND ball_by_ball.over_id = wicket_taken.over_id
AND ball_by_ball.ball_id = wicket_taken.ball_id
AND ball_by_ball.innings_no = wicket_taken.innings_no
AND ball_by_ball.innings_no < 3
AND wicket_taken.kind_out != 3 AND wicket_taken.kind_out != 5 AND wicket_taken.kind_out != 9
GROUP BY ball_by_ball.bowler) as temp2, player, country
WHERE
temp1.bowler = temp2.bowler
AND temp1.bowler = player.player_id
AND player.country_id = country.country_id
ORDER BY ROUND(temp1.runs/temp2.wcks::numeric,2), player.player_name
limit 3;

