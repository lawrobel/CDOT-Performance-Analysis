%web_drop_table(Transportation_Metrics);

FILENAME REFFILE '/folders/myfolders/Performance_Metrics_-_Transportation.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=Transportation_Metrics;
	GETNAMES=YES;
RUN;

% The below procedure totals the number of requests per activity;
PROC SQL;
	SELECT Activity, COUNT(*) AS number_of_requests
	FROM Transportation_Metrics
	GROUP BY Activity
	ORDER BY number_of_requests;
RUN;

% The below procedure finds by how much activities where the average number of days to complete the activity is longer; 
% than the target number of days;
PROC SQL;
	CREATE TABLE activity_summary AS
	SELECT Activity, COUNT(*) AS number_of_requests, 
	sum(Average_Days_to_Complete_Activit - Target_Response_Days)/COUNT(*) AS Target_Missed_By_Days
	FROM Transportation_Metrics
	GROUP BY Activity
	HAVING Target_Missed_By_Days > 0
	ORDER BY Target_Missed_By_Days;
RUN;

PROC PRINT DATA = activity_summary;
RUN;

% Correlation between the number of days the target time was missed by and the number of requests;
PROC CORR DATA = activity_summary;
	VAR Target_Missed_By_Days number_of_requests;
RUN;

title "Number of days the target time was missed by Vs. Number of requests";
PROC SGPLOT DATA = activity_summary;
	SCATTER x = Target_Missed_By_Days y=number_of_requests;
RUN;
title;

% Check and see if average completion time varies by month;
PROC SQL;
	SELECT MONTH, sum(Average_Days_to_Complete_Activit)/COUNT(*) AS Average_Completion_Time_Days
	FROM Transportation_Metrics
	GROUP BY MONTH
	ORDER BY Average_Completion_Time_Days;

RUN;
