-- CEP Public Transport Optimization - SQL Schema
-- Compatible with MySQL / PostgreSQL / SQLite / SQL Server
-- Run in VS Code with SQLTools or MySQL Workbench

DROP TABLE IF EXISTS bus_trips;
CREATE TABLE bus_trips (
    trip_id INT PRIMARY KEY AUTO_INCREMENT,
    Agency VARCHAR(50),
    Source VARCHAR(50),
    Destination VARCHAR(50),
    Bus_Type VARCHAR(50),
    Travel_Date DATE,
    Fare_Price_INR DECIMAL(10,2),
    Total_Seats INT,
    Duration_hours DECIMAL(5,1),
    Route VARCHAR(100) GENERATED ALWAYS AS (CONCAT(Source, ' -> ', Destination)) STORED,
    Revenue_Estimate DECIMAL(12,2) GENERATED ALWAYS AS (Fare_Price_INR * Total_Seats * 0.75) STORED -- assuming 75% occupancy
);

-- For SQLite (no GENERATED), use:
-- CREATE TABLE bus_trips (
--   trip_id INTEGER PRIMARY KEY AUTOINCREMENT,
--   Agency TEXT, Source TEXT, Destination TEXT, Bus_Type TEXT,
--   Travel_Date DATE, Fare_Price_INR REAL, Total_Seats INTEGER, Duration_hours REAL
-- );

-- Load CSV (MySQL)
-- LOAD DATA INFILE 'C:/Users/ashiy/OneDrive/Documents/Default Project/CEP_Public_Transport/data/bus_data.csv'
-- INTO TABLE bus_trips FIELDS TERMINATED BY ',' IGNORE 1 LINES
-- (Agency, Source, Destination, Bus_Type, Travel_Date, Fare_Price_INR, Total_Seats, Duration_hours);

-- Index for optimization
CREATE INDEX idx_route ON bus_trips(Source, Destination);
CREATE INDEX idx_agency ON bus_trips(Agency);
CREATE INDEX idx_date ON bus_trips(Travel_Date);
CREATE INDEX idx_bustype ON bus_trips(Bus_Type);

-- ===================== OPTIMIZATION QUERIES =====================

-- Q1: Top 10 most profitable routes (avg revenue)
-- SELECT Source, Destination, COUNT(*) as trips, AVG(Fare_Price_INR) as avg_fare,
--        AVG(Total_Seats) as avg_seats, AVG(Duration_hours) as avg_duration,
--        SUM(Fare_Price_INR * Total_Seats * 0.75) as total_revenue
-- FROM bus_trips GROUP BY Source, Destination ORDER BY total_revenue DESC LIMIT 10;

-- Q2: Agency performance
-- SELECT Agency, COUNT(*) as total_trips, AVG(Fare_Price_INR) as avg_fare,
--        SUM(Fare_Price_INR*Total_Seats) as max_revenue, AVG(Duration_hours) as avg_duration
-- FROM bus_trips GROUP BY Agency ORDER BY avg_fare DESC;

-- Q3: Bus Type optimization - cost per hour
-- SELECT Bus_Type, AVG(Fare_Price_INR) as avg_fare, AVG(Duration_hours) as avg_duration,
--        AVG(Fare_Price_INR/Duration_hours) as fare_per_hour, AVG(Total_Seats) as avg_seats
-- FROM bus_trips GROUP BY Bus_Type ORDER BY fare_per_hour DESC;

-- Q4: Underutilized routes (low fare + high duration = inefficiency)
-- SELECT Source, Destination, AVG(Fare_Price_INR) as avg_fare, AVG(Duration_hours) as avg_duration,
--        AVG(Fare_Price_INR/Duration_hours) as efficiency
-- FROM bus_trips GROUP BY Source, Destination HAVING efficiency < 100 ORDER BY efficiency ASC;

-- Q5: Peak travel demand by month-year
-- SELECT STRFTIME('%Y-%m', Travel_Date) as month, COUNT(*) as trips, AVG(Fare_Price_INR) as avg_fare
-- FROM bus_trips GROUP BY month ORDER BY trips DESC; -- SQLite
-- SELECT DATE_FORMAT(Travel_Date, '%Y-%m') as month, COUNT(*) FROM bus_trips GROUP BY month; -- MySQL

-- Q6: Fare optimization - routes where fare > 1 stddev above mean (overpriced)
-- SELECT * FROM bus_trips WHERE Fare_Price_INR > (SELECT AVG(Fare_Price_INR)+STDDEV(Fare_Price_INR) FROM bus_trips);

-- Q7: Fleet allocation suggestion - routes with highest demand (trip count)
-- SELECT Route, COUNT(*) as demand, AVG(Total_Seats) as avg_capacity FROM bus_trips GROUP BY Route ORDER BY demand DESC LIMIT 15;

-- Q8: Duration optimization - slowest routes
-- SELECT Source, Destination, AVG(Duration_hours) as avg_duration, COUNT(*) as trips
-- FROM bus_trips GROUP BY Source, Destination ORDER BY avg_duration DESC LIMIT 10;
