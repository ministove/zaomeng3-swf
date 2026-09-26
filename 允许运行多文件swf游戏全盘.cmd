@echo off
setlocal EnableExtensions DisableDelayedExpansion
title 允许运行多文件swf游戏

echo.
echo 允许运行多文件swf游戏
echo.

set "CFG=%APPDATA%\Macromedia\Flash Player\#Security\FlashPlayerTrust\myTrustFiles.cfg"

for %%I in ("%CFG%") do set "CFG_DIR=%%~dpI"

if not exist "%CFG_DIR%" (
    mkdir "%CFG_DIR%" >nul 2>nul
)

if not exist "%CFG_DIR%" (
    echo [失败] 无法创建 Flash 信任目录。
    echo 目标目录：%CFG_DIR%
    echo.
    pause
    exit /b 1
)

if exist "%CFG%" (
    attrib -R -H -S "%CFG%" >nul 2>nul
)

set "TMP=%CFG%.tmp"

> "%TMP%" echo A:\
>>"%TMP%" echo B:\
>>"%TMP%" echo C:\
>>"%TMP%" echo D:\
>>"%TMP%" echo E:\
>>"%TMP%" echo F:\
>>"%TMP%" echo G:\
>>"%TMP%" echo H:\
>>"%TMP%" echo I:\
>>"%TMP%" echo J:\
>>"%TMP%" echo K:\
>>"%TMP%" echo L:\
>>"%TMP%" echo M:\
>>"%TMP%" echo N:\
>>"%TMP%" echo O:\
>>"%TMP%" echo P:\
>>"%TMP%" echo Q:\
>>"%TMP%" echo R:\
>>"%TMP%" echo S:\
>>"%TMP%" echo T:\
>>"%TMP%" echo U:\
>>"%TMP%" echo V:\
>>"%TMP%" echo W:\
>>"%TMP%" echo X:\
>>"%TMP%" echo Y:\
>>"%TMP%" echo Z:\

if errorlevel 1 (
    echo [失败] 无法写入临时配置文件。
    echo 目标文件：%CFG%
    echo.
    pause
    exit /b 1
)

move /Y "%TMP%" "%CFG%" >nul 2>nul

if errorlevel 1 (
    echo [失败] 无法保存 Flash 信任配置。
    echo 请关闭 SWF/Flash 播放器后重试。
    echo 目标文件：%CFG%
    echo.
    if exist "%TMP%" del /F /Q "%TMP%" >nul 2>nul
    pause
    exit /b 1
)

set "COUNT=0"
for /f "usebackq delims=" %%L in ("%CFG%") do set /a COUNT+=1

if "%COUNT%"=="26" (
    echo [成功] 已允许本机所有盘符运行多文件 SWF 游戏。
    echo.
    echo 请重新打开 SWF/Flash 播放器后再测试。
    echo.
    pause
    exit /b 0
) else (
    echo [失败] 配置文件写入不完整。
    echo 目标文件：%CFG%
    echo.
    pause
    exit /b 1
)
