--1--
select foo2.season_year, foo2.player_name
FROM (select season.season_year, foo.player_name, foo.sixes, ROW_NUMBER() OVER (PARTITION BY foo.season_id ORDER BY foo.sixes DESC, foo.player_name) rank 
FROM (select match.season_id, player.player_name, COUNT(batsman_scored.runs_scored) as sixes
from match, ball_by_ball, batsman_scored, player
WHERE
match.match_id = ball_by_ball.match_id
AND ball_by_ball.match_id = batsman_scored.match_id
AND ball_by_ball.over_id = batsman_scored.over_id
AND ball_by_ball.ball_id = batsman_scored.ball_id
AND ball_by_ball.innings_no = batsman_scored.innings_no
AND ball_by_ball.innings_no < 3
AND (batsman_scored.runs_scored = 6 OR batsman_scored.runs_scored = 7)
AND ball_by_ball.striker = player.player_id
GROUP BY match.season_id, player.player_name) as foo, season
WHERE
foo.season_id = season.season_id) as foo2
WHERE foo2.rank < 4
ORDER BY foo2.season_year, foo2.rank;


--2--
select temp5.player_name, temp5.wcks as highest_wickets, temp5.season_year
FROM(
select temp4.player_name, temp4.season_year, temp4.wcks, ROW_NUMBER() OVER (PARTITION BY temp4.player_name ORDER BY temp4.wcks DESC, temp4.season_year) rank 
FROM (select season.season_year, player.player_name, temp3.wcks
FROM (SELECT temp1.season_id, temp1.bowler, temp1.wcks
FROM (select match.season_id, ball_by_ball.bowler, COUNT(ball_by_ball.bowler) as wcks
FROM match, ball_by_ball, wicket_taken
WHERE
match.match_id = ball_by_ball.match_id
AND ball_by_ball.match_id = wicket_taken.match_id
AND ball_by_ball.over_id = wicket_taken.over_id
AND ball_by_ball.ball_id = wicket_taken.ball_id
AND ball_by_ball.innings_no = wicket_taken.innings_no
AND ball_by_ball.innings_no < 3
AND wicket_taken.kind_out != 3 AND wicket_taken.kind_out != 5 AND wicket_taken.kind_out != 9
GROUP BY match.season_id, ball_by_ball.bowler) as temp1
UNION
select temp2.season_id, temp2.bowler, 0
FROM (select match.season_id, ball_by_ball.bowler
FROM match, ball_by_ball
WHERE
match.match_id = ball_by_ball.match_id
AND ball_by_ball.bowler NOT IN (select foo3.bowler FROM (select match.season_id, ball_by_ball.bowler, COUNT(ball_by_ball.bowler) as wcks
FROM match, ball_by_ball, wicket_taken
WHERE
match.match_id = ball_by_ball.match_id
AND ball_by_ball.match_id = wicket_taken.match_id
AND ball_by_ball.over_id = wicket_taken.over_id
AND ball_by_ball.ball_id = wicket_taken.ball_id
AND ball_by_ball.innings_no < 3
AND ball_by_ball.innings_no = wicket_taken.innings_no
AND wicket_taken.kind_out != 3 AND wicket_taken.kind_out != 5 AND wicket_taken.kind_out != 9
GROUP BY match.season_id, ball_by_ball.bowler) as foo3) ) as temp2) temp3, season, player
WHERE
temp3.season_id = season.season_id
AND temp3.bowler = player.player_id) as temp4) as temp5
WHERE temp5.rank < 2;





--3--

select match.season_id, ball_by_ball.striker as person, SUM (batsman_scored.runs_scored) as runs
from match, ball_by_ball, batsman_scored, player
WHERE
match.match_id = ball_by_ball.match_id
AND ball_by_ball.match_id = batsman_scored.match_id
AND ball_by_ball.over_id = batsman_scored.over_id
AND ball_by_ball.ball_id = batsman_scored.ball_id
AND ball_by_ball.innings_no < 3
GROUP BY match.season_id, ball_by_ball.striker;

