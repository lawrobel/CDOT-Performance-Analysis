%web_drop_table(Transportation_Metrics);

FILENAME REFFILE '/folders/myfolders/Performance_Metrics_-_Transportation.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=Transportation_Metrics;
	GETNAMES=YES;
RUN;

%* The below procedure totals the number of requests per activity;
PROC SQL;
	SELECT Activity, COUNT(*) AS number_of_requests
	FROM Transportation_Metrics
	GROUP BY Activity
	ORDER BY number_of_requests;
RUN;

%* The below procedure finds by how much activities where the average number of days to complete the activity is longer; 
%* than the target number of days;
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

%* Correlation between the number of days the target time was missed by and the number of requests;
PROC CORR DATA = activity_summary;
	VAR Target_Missed_By_Days number_of_requests;
RUN;

title "Number of days the target time was missed by Vs. Number of requests";
PROC SGPLOT DATA = activity_summary;
	SCATTER x = Target_Missed_By_Days y=number_of_requests;
RUN;
title;

%* Check and see if average completion time varies by month;
PROC SQL;
	CREATE TABLE month_summary AS
	SELECT MONTH, sum(Total_Completed_Requests)/COUNT(*) AS Average_Completed_Requests, 
	sum(Average_Days_to_Complete_Activit)/COUNT(*) AS Average_Completion_Time_Days,
	sum(Average_Days_to_Complete_Activit - Target_Response_Days)/COUNT(*) AS Target_Missed_By_Days
	FROM Transportation_Metrics
	GROUP BY MONTH
	ORDER BY Average_Completion_Time_Days;
RUN;

PROC PRINT DATA = month_summary;
RUN;

title "Start of Period Vs. Average Number of Days to Complete Activity";
PROC SGPLOT DATA = Transportation_Metrics;
	SERIES x = Period_Start y = Average_Days_to_Complete_Activit / group = Activity;
RUN;
title;

PROC SQL;
	CREATE TABLE Transportation_Poor_Activities AS
	SELECT Period_Start, Average_Days_to_Complete_Activit, Activity
	FROM Transportation_Metrics
	WHERE (Average_Days_to_Complete_Activit - Target_Response_Days) > 500;
RUN;

title "Start of Period Vs. Average Number of Days to Complete Activity (Where Target is Missed by Over 500 Days)";
PROC SGPLOT DATA = Transportation_Poor_Activities;
	SERIES x = Period_Start y = Average_Days_to_Complete_Activit / group = Activity;
RUN;
title;
%* I want to test whether or not the average completion time is different in May than in other months. It is appears
to look much larger than others;
%* Create a column which indicates whether or not a certain data point is in May (For use in the test below);
PROC SQL;
	ALTER TABLE Transportation_Metrics
    ADD May_id INTEGER, Log_Completion_Days NUMERIC;
	UPDATE Transportation_Metrics
	SET May_id = 1
	WHERE MONTH = 5;
	UPDATE Transportation_Metrics
	SET May_id = 0
	WHERE MONTH <> 5;
	UPDATE Transportation_Metrics
	SET Log_Completion_Days = log(Average_Days_to_Complete_Activit); 
RUN;

%* histogram of log transformed Average_Days_to_Complete_Activit days to see data becomes normal for t-test;
PROC UNIVARIATE DATA = Transportation_Metrics;
	HISTOGRAM Average_Days_to_Complete_Activit;
	HISTOGRAM Log_Completion_Days;
RUN;

%* Distribution with or without log transformation does not look normal, so I will try mann-whitney test since it
%* is nonparametric;
%* The below procedure is slow with the large amount of data, consider using a smaller sample

%*PROC NPAR1WAY wilcoxon correct=no data=Transportation_Metrics;
%*      class May_id;     
%*      var Average_Days_to_Complete_Activit;
%*      exact wilcoxon;
%*RUN;

%* See what happens if we assume transformed distributions are normal;
PROC TTEST cochran ci=equal umpu DATA = Transportation_Metrics;
	class May_id;     
    var Log_Completion_Days;
RUN;
