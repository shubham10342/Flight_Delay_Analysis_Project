CREATE TABLE flights (
    `MONTH` VARCHAR(10),
    DAY INT,
    DAY_OF_WEEK VARCHAR(10),
    AIRLINE VARCHAR(10),
    FLIGHT_NUMBER INT,
    ORIGIN_AIRPORT VARCHAR(10),
    DESTINATION_AIRPORT VARCHAR(10),
    DEPARTURE_DELAY FLOAT NOT NULL,
    DISTANCE INT,
    ARRIVAL_DELAY FLOAT NOT NULL,
    DIVERTED INT,
    CANCELLED INT,
    CANCELLATION_REASON VARCHAR(10)
);

describe flights;

SHOW VARIABLES LIKE 'secure_file_priv';

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/flightssummary.csv'
INTO TABLE flights
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

# Created index on various columns to optimize query performance

CREATE INDEX idx_month ON flights (`MONTH`);
CREATE INDEX idx_cancelled ON flights (CANCELLED);
CREATE INDEX idx_depdelay ON flights (DEPARTURE_DELAY);
CREATE INDEX idx_arrdelay ON flights (ARRIVAL_DELAY);
CREATE INDEX idx_dist ON flights (DISTANCE);
CREATE INDEX idx_dow ON flights (DAY_OF_WEEK);
CREATE INDEX idx_div ON flights (DIVERTED);
CREATE INDEX idx_air ON flights (AIRLINE);
CREATE INDEX idx_airline_cancelled ON flights (AIRLINE, CANCELLED);

# Modified Datatypes 
ALTER TABLE flights
MODIFY COLUMN CANCELLED TINYINT(1),
MODIFY COLUMN DIVERTED TINYINT(1);

ALTER TABLE flights
MODIFY COLUMN DAY_OF_WEEK CHAR(3),
MODIFY COLUMN `MONTH` CHAR(3);

ALTER TABLE flights
MODIFY COLUMN CANCELLATION_REASON CHAR(2),
MODIFY COLUMN AIRLINE CHAR(2),
MODIFY COLUMN ORIGIN_AIRPORT VARCHAR(5),
MODIFY COLUMN DESTINATION_AIRPORT VARCHAR(5);

# KPI 1: Weekday Vs Weekend total flights statistics

SELECT
CASE
WHEN DAY_OF_WEEK IN ('Mon','Tue','Wed','Thu','Fri')  THEN 'Weekday'
WHEN DAY_OF_WEEK IN ('Sat','Sun') THEN 'Weekend'
ELSE 'Unknown'
END AS Day_Type,
Count(AIRLINE) AS Total_Flights
FROM flights
GROUP BY Day_Type;

# KPI 2: Total number of cancelled flights for JetBlue Airways on first date of every month

SELECT `MONTH`, COUNT(AIRLINE) AS Total_Flights
FROM flights
WHERE CANCELLED = 1 AND AIRLINE = "B6" AND `DAY` = 1
GROUP BY `MONTH`
ORDER BY Total_Flights DESC;

# KPI 3: Week wise, State wise and City wise statistics of delay of flights with airline details

# Stored Procedure to get citywise data

DELIMITER $$

CREATE PROCEDURE GetTotalFlightsByCity(
    IN Input_City VARCHAR(100)
)
BEGIN
    SELECT COUNT(*) AS Total_Flights
    FROM flights f
    JOIN airports a1 ON f.ORIGIN_AIRPORT = a1.IATA_CODE
    JOIN airports a2 ON f.DESTINATION_AIRPORT = a2.IATA_CODE
    WHERE 
        a1.CITY = Input_City
        OR
        a2.CITY = Input_City;
END$$
DELIMITER ;

# Stored Procedure to get statewise data

DELIMITER $$

CREATE PROCEDURE GetTotalFlightsByState(
    IN Input_State VARCHAR(100)
)
BEGIN
    SELECT COUNT(*) AS Total_Flights
    FROM flights f
    JOIN airports a1 ON f.ORIGIN_AIRPORT = a1.IATA_CODE
    JOIN airports a2 ON f.DESTINATION_AIRPORT = a2.IATA_CODE
    WHERE 
        a1.STATE = Input_State
        OR
        a2.STATE = Input_State;
END$$

DELIMITER ;

# Stored Procedure to get weekly data

DELIMITER $$
CREATE PROCEDURE GetWeeklyFlightStats()
BEGIN
    SELECT 
        WEEK(STR_TO_DATE(CONCAT('2015-', 
                                CASE MONTH
                                    WHEN 'Jan' THEN '01'
                                    WHEN 'Feb' THEN '02'
                                    WHEN 'Mar' THEN '03'
                                    WHEN 'Apr' THEN '04'
                                    WHEN 'May' THEN '05'
                                    WHEN 'Jun' THEN '06'
                                    WHEN 'Jul' THEN '07'
                                    WHEN 'Aug' THEN '08'
                                    WHEN 'Sep' THEN '09'
                                    WHEN 'Oct' THEN '10'
                                    WHEN 'Nov' THEN '11'
                                    WHEN 'Dec' THEN '12'
                                END, '-', DAY), '%Y-%m-%d')) AS Week_Number,
        COUNT(*) AS Total_Flights
    FROM flights
    GROUP BY Week_Number
    ORDER BY Week_Number;
END$$

DELIMITER ;



# KPI 4: Number of airlines with No departure/arrival delay with distance covered between 2500 and 3000

SELECT AIRLINE, Count(AIRLINE) as NodelayFlights
FROM flights
WHERE ARRIVAL_DELAY<=0 AND CANCELLED = 0 AND DIVERTED=0
AND DISTANCE BETWEEN 2500 AND 3000
GROUP BY AIRLINE
ORDER BY NodelayFlights DESC;













