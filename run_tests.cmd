@echo off
echo ==========================================
echo     Payment Mock Service - Test Runner
echo ==========================================
echo.

:: Check Node.js
node -v >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Node.js not found!
    echo Download from: https://nodejs.org
    pause
    exit /b 1
)
echo [OK] Node.js found.

:: Install Newman
echo.
echo [INFO] Installing Newman...
call npm install -g newman >nul 2>&1
echo [OK] Newman ready.

:: Install htmlextra reporter (better than html)
echo [INFO] Installing HTML Reporter...
call npm install -g newman-reporter-htmlextra >nul 2>&1
echo [OK] Reporter ready.

:: Create results folder
if not exist "results" mkdir results

:: Run the collection
echo.
echo [INFO] Running all 5 scenarios...
echo.

newman run PaymentMock.postman_collection.json ^
  --reporters cli,htmlextra ^
  --reporter-htmlextra-export results\newman-report.html ^
  --reporter-htmlextra-title "Payment Mock Service - Test Report" ^
  --reporter-htmlextra-showOnlyFails false

:: Open report automatically
echo.
echo ==========================================
echo  Done! Report saved: results\newman-report.html
echo ==========================================
start results\newman-report.html
pause
