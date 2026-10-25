@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title USB Printer Installer

:: กำหนด network path สำหรับไดรเวอร์
set "network_path=\\10.7.1.11\Script\run_"

:main_menu
cls
echo.
echo ===== โปรแกรมติดตั้งเครื่องพิมพ์ USB =====
echo.
echo 1. ติดตั้งผ่าน USB port (ตรวจจับอัตโนมัติ)
echo 2. ออกจากโปรแกรม
echo.
set /p menu_choice=กรุณาเลือกหมายเลข (1-2): 

if "!menu_choice!"=="1" goto detect_usb_printers
if "!menu_choice!"=="2" goto end

:: ถ้าป้อนตัวเลือกไม่ถูกต้อง
echo.
echo ❌ กรุณาเลือกหมายเลข 1-2 เท่านั้น
timeout /t 2 >nul
goto main_menu

:detect_usb_printers
cls
echo.
echo 🔍 กำลังค้นหาเครื่องพิมพ์ USB ที่เชื่อมต่ออยู่...
echo.

:: สร้างไฟล์ชั่วคราวเพื่อเก็บรายการเครื่องพิมพ์ USB
set "temp_file=%temp%\usb_printers.txt"
if exist "%temp_file%" del "%temp_file%"

:: ใช้ PowerShell เพื่อค้นหาเครื่องพิมพ์ USB และบันทึกลงไฟล์
powershell -Command "Get-PnpDevice -Class Printer | Where-Object { $_.Status -eq 'OK' } | Select-Object FriendlyName, InstanceId | Format-Table -AutoSize | Out-File -FilePath '%temp_file%' -Encoding UTF8"

:: ตรวจสอบว่ามีการพบเครื่องพิมพ์หรือไม่
findstr /C:"FriendlyName" "%temp_file%" >nul
if %errorlevel% NEQ 0 (
    echo ❌ ไม่พบเครื่องพิมพ์ที่เชื่อมต่อผ่าน USB
    echo.
    echo โปรดตรวจสอบว่า:
    echo 1. เครื่องพิมพ์เปิดอยู่
    echo 2. เชื่อมต่อสาย USB เรียบร้อยแล้ว
    echo 3. คอมพิวเตอร์รับรู้การเชื่อมต่อ USB
    echo.
    pause
    goto main_menu
)

:: นับจำนวนเครื่องพิมพ์ที่พบ
set /a printer_count=0
set "printer_list="

:: อ่านไฟล์และสร้างรายการเครื่องพิมพ์
for /f "skip=3 tokens=*" %%a in (%temp_file%) do (
    set "line=%%a"
    if "!line!" NEQ "" (
        if "!line:~0,1!" NEQ "-" (
            set /a printer_count+=1
            set "printer!printer_count!=!line!"
            set "printer_list=!printer_list!!printer_count!. !line!{NL}"
        )
    )
)

:: ถ้าไม่พบเครื่องพิมพ์
if %printer_count% EQU 0 (
    echo ❌ ไม่พบเครื่องพิมพ์ที่เชื่อมต่อผ่าน USB
    echo.
    pause
    goto main_menu
)

:: แสดงรายการเครื่องพิมพ์ที่พบ
cls
echo.
echo พบเครื่องพิมพ์ USB จำนวน %printer_count% เครื่อง:
echo.

:: แก้ไขวิธีการแสดงรายการเครื่องพิมพ์ให้เป็นการแสดงแต่ละรายการในบรรทัดใหม่
for /L %%i in (1,1,%printer_count%) do (
    echo %%i. !printer%%i!
)
echo.
echo %printer_count%+1. กลับไปเมนูหลัก
echo.

:: ให้ผู้ใช้เลือกเครื่องพิมพ์
set /p usb_choice=กรุณาเลือกเครื่องพิมพ์ (1-%printer_count% หรือ %printer_count%+1 เพื่อกลับ): 

:: ตรวจสอบว่าผู้ใช้ต้องการกลับไปเมนูหลัก
set /a back_option=%printer_count%+1
if "!usb_choice!"=="!back_option!" goto main_menu

:: ตรวจสอบว่าผู้ใช้เลือกหมายเลขที่ถูกต้อง
if !usb_choice! LSS 1 (
    echo ❌ กรุณาเลือกหมายเลขที่ถูกต้อง
    timeout /t 2 >nul
    goto detect_usb_printers
)
if !usb_choice! GTR %printer_count% (
    echo ❌ กรุณาเลือกหมายเลขที่ถูกต้อง
    timeout /t 2 >nul
    goto detect_usb_printers
)

:: ดึงชื่อเครื่องพิมพ์ที่ผู้ใช้เลือก
set "selected_printer=!printer%usb_choice%!"
echo.
echo คุณเลือกเครื่องพิมพ์: !selected_printer!

:: ทำการตรวจสอบว่าเป็นเครื่องพิมพ์ยี่ห้อไหน
set "detected_brand="
set "detected_model="

:: ตรวจสอบยี่ห้อและรุ่นจากชื่อเครื่องพิมพ์
echo !selected_printer! | findstr /i "Canon" >nul
if !errorlevel! equ 0 (
    set "detected_brand=Canon"
    
    echo !selected_printer! | findstr /i "3822" >nul
    if !errorlevel! equ 0 set "detected_model=Canon 3822"
    
    echo !selected_printer! | findstr /i "LBP6300" >nul
    if !errorlevel! equ 0 set "detected_model=Canon LBP6300"
)

echo !selected_printer! | findstr /i "HP" >nul
if !errorlevel! equ 0 (
    set "detected_brand=HP"
    
    echo !selected_printer! | findstr /i "Pro7740" >nul
    if !errorlevel! equ 0 set "detected_model=HP Pro7740"
    
    echo !selected_printer! | findstr /i "447dw" >nul
    if !errorlevel! equ 0 set "detected_model=HP 447dw"
)

echo !selected_printer! | findstr /i "Brother" >nul
if !errorlevel! equ 0 (
    set "detected_brand=Brother"
    
    echo !selected_printer! | findstr /i "HL-L2460DW" >nul
    if !errorlevel! equ 0 set "detected_model=Brother HL-L2460DW"
    
    echo !selected_printer! | findstr /i "HL-L3270CDW" >nul
    if !errorlevel! equ 0 set "detected_model=Brother HL-L3270CDW"
)

:: ถ้าตรวจสอบไม่พบยี่ห้อในรายการที่กำหนด
if "!detected_brand!"=="" (
    cls
    echo.
    echo ⚠️ ไม่สามารถระบุยี่ห้อของเครื่องพิมพ์ได้โดยอัตโนมัติ
    echo ชื่อเครื่องพิมพ์: !selected_printer!
    echo.
    echo กรุณาเลือกยี่ห้อด้วยตนเอง
    goto select_brand_usb
) else (
    :: ถ้าตรวจพบยี่ห้อ แต่ไม่พบรุ่นที่ตรงกับรายการ
    if "!detected_model!"=="" (
        cls
        echo.
        echo ⚠️ ตรวจพบว่าเป็นเครื่องพิมพ์ยี่ห้อ !detected_brand! แต่ไม่สามารถระบุรุ่นได้
        echo ชื่อเครื่องพิมพ์: !selected_printer!
        echo.
        set "brand=!detected_brand!"
        goto select_model_for_brand
    ) else (
        :: ถ้าตรวจพบทั้งยี่ห้อและรุ่น
        cls
        echo.
        echo ✅ ตรวจพบเครื่องพิมพ์: !detected_model!
        echo.
        set "brand=!detected_brand!"
        set "model=!detected_model!"
        
        :: กำหนด driver path และ driver name ตามรุ่นที่ตรวจพบ
        if "!model!"=="Canon 3822" (
            set "driver_path=%network_path%\Canon\iR-ADV C3822\CNLB0MA64.INF"
            set "driver_name=Canon Generic Plus UFR II"
        ) else if "!model!"=="Canon LBP6300" (
            set "driver_path=%network_path%\Canon\LBP6300dn\CNABBSTD.INF"
            set "driver_name=Canon LBP6300"
        ) else if "!model!"=="HP Pro7740" (
            set "driver_path=%network_path%\HP\Pro7740\hpcu250u.inf"
            set "driver_name=HP OfficeJet Pro 7740"
        ) else if "!model!"=="HP 447dw" (
            set "driver_path=%network_path%\HP\447dw\hpcm506a.inf"
            set "driver_name=HP Color LaserJet Pro MFP M447dw"
        ) else if "!model!"=="Brother HL-L2460DW" (
            set "driver_path=%network_path%\Brother\HL-L2460DW\gdi\BROHL22A.INF"
            set "driver_name=Brother HL-L2460DW Printer"
        ) else if "!model!"=="Brother HL-L3270CDW" (
            set "driver_path=%network_path%\Brother\HL-L3270CDW\BROHL14A.INF"
            set "driver_name=Brother HL-L3270CDW Printer"
        )
        
        echo ต้องการดำเนินการติดตั้ง !model! ใช่หรือไม่?
        echo 1. ใช่ ติดตั้งเลย
        echo 2. ไม่ ฉันต้องการเลือกรุ่นด้วยตัวเอง
        echo.
        set /p auto_install=กรุณาเลือก (1-2): 
        
        if "!auto_install!"=="1" goto install_usb_printer
        if "!auto_install!"=="2" goto select_model_for_brand
        
        echo ❌ กรุณาเลือกหมายเลข 1-2 เท่านั้น
        timeout /t 2 >nul
        goto detect_usb_printers
    )
)

:select_brand_usb
echo.
echo กรุณาเลือกยี่ห้อของ Printer:
echo 1. Canon
echo 2. HP
echo 3. Brother
echo 4. กลับไปเมนูหลัก
echo.
set /p brand_choice=กรุณาเลือกหมายเลขยี่ห้อ (1-4): 

if "!brand_choice!"=="1" (
    set brand=Canon
    goto select_model_for_brand
)
if "!brand_choice!"=="2" (
    set brand=HP
    goto select_model_for_brand
)
if "!brand_choice!"=="3" (
    set brand=Brother
    goto select_model_for_brand
)
if "!brand_choice!"=="4" goto main_menu

echo.
echo ❌ กรุณาเลือกหมายเลข 1-4 เท่านั้น
timeout /t 2 >nul
goto select_brand_usb

:select_model_for_brand
if "!brand!"=="Canon" goto select_canon_model_usb
if "!brand!"=="HP" goto select_hp_model_usb
if "!brand!"=="Brother" goto select_brother_model_usb

goto select_brand_usb

:select_canon_model_usb
cls
echo.
echo คุณใช้ Canon รุ่นอะไร:
echo 1. Canon 3822
echo 2. Canon LBP6300
echo 3. กลับไปเลือกยี่ห้อ
echo.
set /p model_choice=กรุณาเลือกรุ่น (1-3): 

if "!model_choice!"=="1" (
    set model=Canon 3822
    set "driver_path=%network_path%\Canon\iR-ADV C3822\CNLB0MA64.INF"
    set "driver_name=Canon Generic Plus UFR II"
    goto install_usb_printer
)
if "!model_choice!"=="2" (
    set model=Canon LBP6300
    set "driver_path=%network_path%\Canon\LBP6300dn\CNABBSTD.INF"
    set "driver_name=Canon LBP6300"
    goto install_usb_printer
)
if "!model_choice!"=="3" goto select_brand_usb

echo.
echo ❌ กรุณาเลือกหมายเลข 1-3 เท่านั้น
timeout /t 2 >nul
goto select_canon_model_usb

:select_hp_model_usb
cls
echo.
echo คุณใช้ HP รุ่นอะไร:
echo 1. HP Pro7740
echo 2. HP 447dw
echo 3. กลับไปเลือกยี่ห้อ
echo.
set /p model_choice=กรุณาเลือกรุ่น (1-3): 

if "!model_choice!"=="1" (
    set model=HP Pro7740
    set "driver_path=%network_path%\HP\Pro7740\hpcu250u.inf"
    set "driver_name=HP OfficeJet Pro 7740"
    goto install_usb_printer
)
if "!model_choice!"=="2" (
    set model=HP 447dw
    set "driver_path=%network_path%\HP\447dw\hpcm506a.inf"
    set "driver_name=HP Color LaserJet Pro MFP M447dw"
    goto install_usb_printer
)
if "!model_choice!"=="3" goto select_brand_usb

echo.
echo ❌ กรุณาเลือกหมายเลข 1-3 เท่านั้น
timeout /t 2 >nul
goto select_hp_model_usb

:select_brother_model_usb
cls
echo.
echo คุณใช้ Brother รุ่นอะไร:
echo 1. Brother HL-L2460DW
echo 2. Brother HL-L3270CDW
echo 3. กลับไปเลือกยี่ห้อ
echo.
set /p model_choice=กรุณาเลือกรุ่น (1-3): 

if "!model_choice!"=="1" (
    set model=Brother HL-L2460DW
    set "driver_path=%network_path%\Brother\HL-L2460DW\gdi\BROHL22A.INF"
    set "driver_name=Brother HL-L2460DW Printer"
    goto install_usb_printer
)
if "!model_choice!"=="2" (
    set model=Brother HL-L3270CDW
    set "driver_path=%network_path%\Brother\HL-L3270CDW\BROHL14A.INF"
    set "driver_name=Brother HL-L3270CDW Printer"
    goto install_usb_printer
)
if "!model_choice!"=="3" goto select_brand_usb

echo.
echo ❌ กรุณาเลือกหมายเลข 1-3 เท่านั้น
timeout /t 2 >nul
goto select_brother_model_usb

:install_usb_printer
cls
echo.
echo 🔧 กำลังติดตั้งเครื่องพิมพ์ USB: !model!
echo.

:: ตรวจสอบว่าไฟล์ไดรเวอร์มีอยู่จริง
echo 🔍 กำลังตรวจสอบไฟล์ไดรเวอร์...
if not exist "!driver_path!" (
    echo.
    echo ❌ ไม่พบไฟล์ไดรเวอร์ที่: !driver_path!
    echo กรุณาตรวจสอบว่าเชื่อมต่อกับเซิร์ฟเวอร์และไฟล์ไดรเวอร์มีอยู่จริง
    echo.
    echo กด Enter เพื่อกลับไปหน้าก่อนหน้า...
    pause >nul
    goto detect_usb_printers
)

echo ✅ พบไฟล์ไดรเวอร์ที่: !driver_path!
echo.

:: ตั้งชื่อเครื่องพิมพ์
set "printer_name=!model! (USB)"

echo 🔄 กำลังติดตั้งไดรเวอร์...
:: ใช้ PowerShell เพื่อติดตั้งไดรเวอร์
powershell -Command "Add-PrinterDriver -Name '!driver_name!' -InfPath '!driver_path!' -ErrorAction SilentlyContinue"

echo 🔄 กำลังติดตั้งเครื่องพิมพ์...
:: ดึง instance ID ของเครื่องพิมพ์ USB ที่ผู้ใช้เลือก (ถ้ามี)
for /f "tokens=2 delims= " %%u in ('echo !selected_printer!') do set "usb_instance=%%u"

:: ติดตั้งเครื่องพิมพ์โดยใช้ไดรเวอร์ที่เราติดตั้งไว้
rundll32 printui.dll,PrintUIEntry /if /b "!printer_name!" /f "!driver_path!" /m "!driver_name!"

:: ถ้าเกิดข้อผิดพลาด ให้ลองอีกวิธีที่เรียบง่ายกว่า
if not %errorlevel%==0 (
    echo ⚠️ วิธีแรกไม่สำเร็จ ลองวิธีที่ 2...
    powershell -Command "Add-Printer -Name '!printer_name!' -DriverName '!driver_name!' -ErrorAction SilentlyContinue"
)

:: ตรวจสอบว่าติดตั้งสำเร็จหรือไม่
powershell -Command "$printer = Get-Printer -Name '!printer_name!' -ErrorAction SilentlyContinue; if($printer) { exit 0 } else { exit 1 }" >nul
if %errorlevel%==0 (
    echo.
    echo ✅ ติดตั้ง Printer รุ่น !model! สำเร็จแล้ว
) else (
    echo.
    echo ⚠️ ไม่สามารถยืนยันการติดตั้งได้ ลองทางเลือกสุดท้าย...
    
    :: ทางเลือกสุดท้าย - สร้างคำสั่งสำหรับเปิด GUI ติดตั้งเครื่องพิมพ์
    echo.
    echo 🔄 กำลังเปิดตัวช่วยติดตั้งเครื่องพิมพ์...
    start "" rundll32 printui.dll,PrintUIEntry /il
    
    echo.
    echo โปรดทำตามขั้นตอนในหน้าต่างที่เปิดขึ้น:
    echo 1. เลือก "เพิ่มเครื่องพิมพ์ท้องถิ่นหรือเครื่องพิมพ์เครือข่ายด้วยการตั้งค่าด้วยตนเอง"
    echo 2. เลือก "ใช้พอร์ต USB หรือพอร์ตที่มีอยู่"
    echo 3. เลือกไดรเวอร์: !driver_name!
    echo.
    timeout /t 5 >nul
)
goto ask_install_more_usb

:ask_install_more_usb
echo.
echo กด 1: ติดตั้งเครื่องพิมพ์เพิ่มเติม
echo กด 2: กลับไปเมนูหลัก
echo กด 3: จบการทำงาน
echo.
set /p more_choice=กรุณาเลือกตัวเลือก (1-3): 

if "!more_choice!"=="1" goto detect_usb_printers
if "!more_choice!"=="2" goto main_menu
if "!more_choice!"=="3" goto end

:: ถ้าป้อนตัวเลือกไม่ถูกต้อง
echo.
echo ❌ กรุณาเลือกหมายเลข 1-3 เท่านั้น
timeout /t 2 >nul
goto ask_install_more_usb

:end
cls
echo.
echo การทำงานเสร็จสิ้น
echo.
pause
exit
