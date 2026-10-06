@echo off
setlocal enabledelayedexpansion

echo ========================================================
echo   COCORD // Android ARM64 Release APK Auto-Builder
echo ========================================================
echo.

:: 1. Configure Java JDK
if "%JAVA_HOME%"=="" (
    if exist "C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot\bin\javac.exe" (
        set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot"
        set "PATH=C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot\bin;!PATH!"
        echo [JAVA] Configured JAVA_HOME: !JAVA_HOME!
    )
)

:: 2. Configure Android SDK
if "%ANDROID_HOME%"=="" (
    if exist "C:\Android\sdk" (
        set "ANDROID_HOME=C:\Android\sdk"
        set "ANDROID_SDK_ROOT=C:\Android\sdk"
        set "PATH=C:\Android\sdk\platform-tools;C:\Android\sdk\cmdline-tools\latest\bin;!PATH!"
        echo [ANDROID] Configured ANDROID_HOME: C:\Android\sdk
    )
)

:: 3. Configure Flutter
set "FLUTTER_CMD=flutter"
if exist "C:\src\flutter\bin\flutter.bat" (
    set "PATH=C:\src\flutter\bin;!PATH!"
    set "FLUTTER_CMD=C:\src\flutter\bin\flutter.bat"
    echo [FLUTTER] Found Flutter at: C:\src\flutter\bin
)

cd /d "%~dp0"

echo.
echo [1/3] Resolving Flutter dependencies...
call %FLUTTER_CMD% pub get
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] pub get failed.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo [2/3] Compiling ARM64 Release APK (android-arm64)...
call %FLUTTER_CMD% build apk --target-platform android-arm64 --split-per-abi --release
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Build failed. Checking Flutter doctor status...
    call %FLUTTER_CMD% doctor
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ========================================================
echo [3/3] BUILD SUCCESSFUL!
echo ========================================================
echo Your ARM64 APK is ready at:
echo %~dp0build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
echo.

if exist "%~dp0build\app\outputs\flutter-apk\app-arm64-v8a-release.apk" (
    explorer /select,"%~dp0build\app\outputs\flutter-apk\app-arm64-v8a-release.apk"
)

pause
