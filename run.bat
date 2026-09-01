@echo off
REM CEP Public Transport - VS Code Run Script (Windows)
REM Double-click or run in VS Code terminal

echo === CEP Public Transport & Optimization ===
echo Dataset: data/bus_data.csv (500k rows)
echo Streamlit: http://localhost:8501
echo.

REM Activate venv if exists
if exist "..\venv\Scripts\activate.bat" call "..\venv\Scripts\activate.bat"
if exist ".\.venv\Scripts\activate.bat" call ".\.venv\Scripts\activate.bat"

pip install -r requirements.txt
echo.
echo Starting Streamlit...
streamlit run app.py
pause
