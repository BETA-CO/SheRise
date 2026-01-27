@echo off
echo ==========================================
echo      SheRise Build Fixer Tool
echo ==========================================
echo.
echo 1. Stopping stuck Gradle processes (unlocking build queue)...
cd android
call gradlew.bat --stop
echo.
echo 2. Removing Gradle lock files (Nuclear option)...
if exist ".gradle" rmdir /s /q ".gradle"
cd ..

echo.
echo 3. Cleaning project build cache (removing temporary files)...
call flutter clean

echo.
echo 4. Refreshing dependencies...
call flutter pub get

echo.
echo ==========================================
echo      Fix Complete! 
echo ==========================================
echo You can now try running the app again.
echo.
pause
