@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion

rem ============================================================
rem SWF 下载器 CMD 版
rem 由 swf_downloader.py 转换
rem
rem 用法示例：
rem   swf_downloader.cmd
rem   swf_downloader.cmd --base "http://img3.17yy.com/swf/dongzuo/2016-07-31/yaowei/" --referer "http://www.17yy.com/f/61258.html"
rem   swf_downloader.cmd --baseUrl "http://example.com/path/" --Referer "http://example.com/page.html" --timeout 30
rem
rem 交互输入示例：
rem   1
rem   1.swf
rem   folder01/1
rem   1 备份1
rem   http://example.com/a/b/1.swf
rem   q
rem ============================================================

set "DEFAULT_BASE_URL=http://img3.17yy.com/swf/dongzuo/2016-07-31/yaowei/"
set "DEFAULT_REFERER=http://www.17yy.com/f/61258.html"

set "BASE_URL=%DEFAULT_BASE_URL%"
set "REFERER=%DEFAULT_REFERER%"
set "TIMEOUT=30"

call :parse_args %*
call :normalize_base_url

echo === 4399 swf 下载器（多次下载模式 / CMD版）===
echo [+] 当前 baseUrl：!BASE_URL!
echo [+] 当前 Referer：!REFERER!
echo 输入 swf 文件名 或 完整 URL：
echo   例：1          （自动变成 1.swf）
echo   例：1.swf
echo   例：folder01/1 （自动保存到 folder01\1.swf）
echo   例：1 备份1    （第二个是保存文件名，可选，也会自动补 .swf）
echo 直接回车或输入 q 退出。
echo.

:main_loop
set "LINE="
set /p "LINE=swf> "

if not defined LINE (
    echo [+] 退出。
    goto :eof
)

if /I "!LINE!"=="q" (
    echo [+] 退出。
    goto :eof
)

set "TARGET="
set "OUTPUT="

for /f "tokens=1,2" %%A in ("!LINE!") do (
    set "TARGET=%%~A"
    set "OUTPUT=%%~B"
)

if not defined TARGET (
    echo.
    goto main_loop
)

call :is_full_url "!TARGET!" TARGET_IS_FULL

rem 非完整 URL 的输入，如果没有点号，则自动补 .swf
if "!TARGET_IS_FULL!"=="0" (
    call :add_swf_ext TARGET
)

rem 用户显式指定输出名时，也自动补 .swf
if defined OUTPUT (
    call :add_swf_ext OUTPUT
)

rem 拼出真实下载 URL
if "!TARGET_IS_FULL!"=="1" (
    set "URL=!TARGET!"
) else (
    set "URL=!BASE_URL!!TARGET!"
)

rem 未显式指定输出名时：
rem - 完整 URL：保存为 URL 中的文件名
rem - 相对路径：保留目录结构，如 folder01/1.swf -> folder01\1.swf
if not defined OUTPUT (
    if "!TARGET_IS_FULL!"=="1" (
        call :filename_from_url "!URL!" OUTPUT
    ) else (
        set "OUTPUT=!TARGET:/=\!"
    )
)

if not defined OUTPUT (
    set "OUTPUT=downloaded_file"
)

call :download_file "!URL!" "!OUTPUT!"
echo.
goto main_loop


:parse_args
if "%~1"=="" goto :eof

if /I "%~1"=="--base" (
    set "BASE_URL=%~2"
    shift
    shift
    goto parse_args
)

if /I "%~1"=="--baseUrl" (
    set "BASE_URL=%~2"
    shift
    shift
    goto parse_args
)

if /I "%~1"=="--referer" (
    set "REFERER=%~2"
    shift
    shift
    goto parse_args
)

if /I "%~1"=="--Referer" (
    set "REFERER=%~2"
    shift
    shift
    goto parse_args
)

if /I "%~1"=="--timeout" (
    set "TIMEOUT=%~2"
    shift
    shift
    goto parse_args
)

echo [!] 忽略未知参数：%~1
shift
goto parse_args


:normalize_base_url
if not defined BASE_URL goto :eof
if not "!BASE_URL:~-1!"=="/" set "BASE_URL=!BASE_URL!/"
goto :eof


:is_full_url
rem 用法：call :is_full_url "字符串" 返回变量名
set "%~2=0"
set "CHECK_URL=%~1"
if /I "!CHECK_URL:~0,7!"=="http://" set "%~2=1"
if /I "!CHECK_URL:~0,8!"=="https://" set "%~2=1"
goto :eof


:add_swf_ext
rem 用法：call :add_swf_ext 变量名
set "TMP_VALUE=!%~1!"
if not defined TMP_VALUE goto :eof

rem 与原 Python 逻辑保持一致：只要字符串里没有点号，就补 .swf
if "!TMP_VALUE!"=="!TMP_VALUE:.=!" (
    set "%~1=!TMP_VALUE!.swf"
)
goto :eof


:filename_from_url
rem 用法：call :filename_from_url "URL" 返回变量名
set "TMP_URL=%~1"

rem 去掉 ?query 和 #fragment
for /f "tokens=1 delims=?" %%U in ("!TMP_URL!") do set "TMP_URL_NO_QUERY=%%U"
for /f "tokens=1 delims=#" %%U in ("!TMP_URL_NO_QUERY!") do set "TMP_URL_NO_FRAGMENT=%%U"

rem 将 / 替换成 \，再取最后的文件名
set "TMP_PATH=!TMP_URL_NO_FRAGMENT:/=\!"
for %%F in ("!TMP_PATH!") do set "TMP_FILE=%%~nxF"

if not defined TMP_FILE set "TMP_FILE=downloaded_file"
set "%~2=!TMP_FILE!"
goto :eof


:ensure_output_dir
rem 用法：call :ensure_output_dir "输出文件路径"
set "OUT_FILE=%~1"
for %%F in ("!OUT_FILE!") do set "OUT_DIR=%%~dpF"

if defined OUT_DIR (
    if not exist "!OUT_DIR!" (
        mkdir "!OUT_DIR!" >nul 2>nul
    )
)
goto :eof


:download_file
rem 用法：call :download_file "URL" "输出文件"
set "DL_URL=%~1"
set "DL_OUTPUT=%~2"

call :ensure_output_dir "!DL_OUTPUT!"

if exist "!DL_OUTPUT!" (
    echo [!] 文件已存在，跳过下载：!DL_OUTPUT!
    goto :eof
)

echo [+] 开始下载：!DL_URL!
echo [+] 使用 Referer：!REFERER!
echo [+] 输出文件：!DL_OUTPUT!

where curl.exe >nul 2>nul
if errorlevel 1 (
    echo [-] 下载失败：未找到 curl.exe。Windows 10/11 通常自带 curl，请确认系统 PATH 是否正常。
    goto :eof
)

curl.exe ^
  -L ^
  --fail ^
  --connect-timeout !TIMEOUT! ^
  --max-time !TIMEOUT! ^
  -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0 Safari/537.36" ^
  -e "!REFERER!" ^
  -o "!DL_OUTPUT!" ^
  "!DL_URL!"

if errorlevel 1 (
    echo [-] 下载失败。
) else (
    echo [+] 下载完成！
)

goto :eof
