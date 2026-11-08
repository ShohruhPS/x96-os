@echo off
rem Run an X96 OS image in QEMU on Windows as a "virtual X96 Mini":
rem 4x Cortex-A53, 2 GB RAM, image attached as a USB stick (how the real box boots it).
rem
rem   run-qemu.bat X96OS-1.0-cli-x96mini-s905w-YYYYMMDD.img.xz
rem   (or drag the .img.xz file onto run-qemu.bat)
rem
rem Needs QEMU (winget install SoftwareFreedomConservancy.QEMU) and 7-Zip (winget install 7zip.7zip).
rem Put x96os-qemu-vmlinuz and x96os-qemu-initrd.img from the same release next to the image.
setlocal EnableDelayedExpansion

if "%~1"=="" (
  echo usage: run-qemu.bat X96OS-...img.xz
  pause & exit /b 1
)
set "IMG=%~f1"
set "DIR=%~dp1"
set "QEMU=%ProgramFiles%\qemu"
set "SEVENZIP=%ProgramFiles%\7-Zip\7z.exe"

if not exist "%QEMU%\qemu-system-aarch64.exe" (
  echo QEMU not found. Install it with:  winget install SoftwareFreedomConservancy.QEMU
  pause & exit /b 1
)
if not exist "%DIR%x96os-qemu-vmlinuz" (
  echo Missing %DIR%x96os-qemu-vmlinuz - download it from the same release.
  pause & exit /b 1
)
if not exist "%DIR%x96os-qemu-initrd.img" (
  echo Missing %DIR%x96os-qemu-initrd.img - download it from the same release.
  pause & exit /b 1
)

if /i "%IMG:~-3%"==".xz" (
  set "RAW=%IMG:~0,-3%"
  if not exist "!RAW!" (
    if not exist "%SEVENZIP%" (
      echo Unpack the .img.xz first, or install 7-Zip:  winget install 7zip.7zip
      pause & exit /b 1
    )
    echo Unpacking %IMG% ...
    "%SEVENZIP%" e "%IMG%" -o"%DIR%" -y >nul
  )
  set "IMG=!RAW!"
)

rem room to grow: X96 OS expands its root partition to fill the disk on first boot
"%QEMU%\qemu-img.exe" resize -f raw "%IMG%" 16G >nul

echo Starting the virtual X96 Mini. On a PC the ARM CPU is emulated, so it is slower than the real box.
echo SSH into it later with:  ssh -p 2222 x96@localhost

"%QEMU%\qemu-system-aarch64.exe" -M virt -accel tcg,thread=multi -cpu cortex-a53 -smp 4 -m 2048 ^
  -kernel "%DIR%x96os-qemu-vmlinuz" -initrd "%DIR%x96os-qemu-initrd.img" ^
  -append "root=LABEL=ROOTFS rootwait rw console=ttyAMA0 console=tty0 net.ifnames=0 fsck.repair=yes" ^
  -device qemu-xhci,id=xhci ^
  -drive "if=none,id=x96disk,file=%IMG%,format=raw" ^
  -device usb-storage,bus=xhci.0,drive=x96disk ^
  -device usb-kbd,bus=xhci.0 -device usb-tablet,bus=xhci.0 ^
  -device virtio-gpu-pci,xres=1920,yres=1080 ^
  -netdev "user,id=net0,hostfwd=tcp::2222-:22" -device virtio-net-pci,netdev=net0
