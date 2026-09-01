-- CEP Public Transport: Advanced Optimization Queries
-- Copy-paste into VS Code SQL or Power BI Direct Query

-- 1. KPI SUMMARY
SELECT 
  COUNT(*) AS total_trips,
  COUNT(DISTINCT Agency) AS agencies,
  COUNT(DISTINCT Source) AS sources,
  COUNT(DISTINCT Destination) AS destinations,
  ROUND(AVG(Fare_Price_INR),2) AS avg_fare,
  ROUND(AVG(Duration_hours),2) AS avg_duration,
  ROUND(AVG(Total_Seats),1) AS avg_seats,
  ROUND(SUM(Fare_Price_INR * Total_Seats * 0.75),2) AS est_total_revenue
FROM bus_trips;

-- 2. ROUTE PROFITABILITY RANKING (Optimization Core)
SELECT 
  Source || ' -> ' || Destination AS route,
  COUNT(*) AS trips,
  ROUND(AVG(Fare_Price_INR),2) AS avg_fare,
  ROUND(AVG(Duration_hours),2) AS avg_hours,
  ROUND(AVG(Fare_Price_INR / Duration_hours),2) AS fare_per_hour,
  ROUND(SUM(Fare_Price_INR * Total_Seats * 0.75),0) AS est_revenue,
  ROUND(AVG(Total_Seats),1) AS avg_seats
FROM bus_trips
GROUP BY Source, Destination
ORDER BY est_revenue DESC
LIMIT 15;

-- 3. BUS TYPE EFFICIENCY
SELECT Bus_Type,
  COUNT(*) AS trips,
  ROUND(AVG(Fare_Price_INR),2) AS avg_fare,
  ROUND(AVG(Fare_Price_INR / Duration_hours),2) AS revenue_per_hour,
  ROUND(AVG(Total_Seats),1) AS avg_seats
FROM bus_trips
GROUP BY Bus_Type
ORDER BY revenue_per_hour DESC;

-- 4. FARE ANOMALY DETECTION (for ML)
SELECT * FROM bus_trips
WHERE Fare_Price_INR > (SELECT AVG(Fare_Price_INR)+2*STDDEV(Fare_Price_INR) FROM bus_trips)
   OR Fare_Price_INR < (SELECT AVG(Fare_Price_INR)-2*STDDEV(Fare_Price_INR) FROM bus_trips)
LIMIT 100;

-- 5. SEASONALITY
SELECT 
  CAST(strftime('%m', Travel_Date) AS INT) AS month_num,
  COUNT(*) AS trips,
  ROUND(AVG(Fare_Price_INR),2) AS avg_fare
FROM bus_trips GROUP BY month_num ORDER BY month_num;

-- 6. AGENCY MARKET SHARE
SELECT Agency, COUNT(*) AS trips,
  ROUND(COUNT(*)*100.0/(SELECT COUNT(*) FROM bus_trips),2) AS market_share_pct,
  ROUND(AVG(Fare_Price_INR),2) AS avg_fare
FROM bus_trips GROUP BY Agency ORDER BY trips DESC;

-- 7. FLEET OPTIMIZATION: Recommend seats per route (demand vs capacity)
SELECT Source, Destination, COUNT(*) AS demand_trips,
  CASE 
    WHEN COUNT(*) > 8000 THEN 'HIGH DEMAND - Deploy 50-seater Volvo/AC Sleeper'
    WHEN COUNT(*) > 5000 THEN 'MEDIUM - Deploy 40-seater'
    ELSE 'LOW - Deploy 28-32 seater'
  END AS fleet_recommendation
FROM bus_trips GROUP BY Source, Destination ORDER BY demand_trips DESC;

-- 8. LINEAR PROGRAMMING INPUT: Cost matrix for optimization model
SELECT Source, Destination, Bus_Type,
  ROUND(AVG(Duration_hours),2) AS avg_duration,
  ROUND(AVG(Fare_Price_INR),2) AS avg_fare,
  COUNT(*) AS frequency
FROM bus_trips GROUP BY Source, Destination, Bus_Type;
