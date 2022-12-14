# DPI Adjustment found at https://stackoverflow.com/questions/35233182/how-can-i-change-windows-10-display-scaling-programmatically-using-c-sharp
$source = @’
[DllImport("user32.dll", EntryPoint = "SystemParametersInfo")]
public static extern bool SystemParametersInfo(
                uint uiAction,
                uint uiParam,
                uint pvParam,
                uint fWinIni);
‘@
$apicall = Add-Type -MemberDefinition $source -Name WinAPICall -Namespace SystemParamInfo –PassThru


# Function Set-ScreenResolutionAndOrentiong found at: https://stackoverflow.com/questions/12644786/powershell-script-to-change-screen-orientation/24346514#24346514
Function Set-ScreenResolutionAndOrientation { 

<# 
    .Synopsis 
        Sets the Screen Resolution of the primary monitor 
    .Description 
        Uses Pinvoke and ChangeDisplaySettings Win32API to make the change 
    .Example 
        Set-ScreenResolutionAndOrientation         
#>

$pinvokeCode = @" 

using System; 
using System.Runtime.InteropServices; 

namespace Resolution 
{ 

    [StructLayout(LayoutKind.Sequential)] 
    public struct DEVMODE 
    { 
       [MarshalAs(UnmanagedType.ByValTStr,SizeConst=32)]
       public string dmDeviceName;

       public short  dmSpecVersion;
       public short  dmDriverVersion;
       public short  dmSize;
       public short  dmDriverExtra;
       public int    dmFields;
       public int    dmPositionX;
       public int    dmPositionY;
       public int    dmDisplayOrientation;
       public int    dmDisplayFixedOutput;
       public short  dmColor;
       public short  dmDuplex;
       public short  dmYResolution;
       public short  dmTTOption;
       public short  dmCollate;

       [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
       public string dmFormName;

       public short  dmLogPixels;
       public short  dmBitsPerPel;
       public int    dmPelsWidth;
       public int    dmPelsHeight;
       public int    dmDisplayFlags;
       public int    dmDisplayFrequency;
       public int    dmICMMethod;
       public int    dmICMIntent;
       public int    dmMediaType;
       public int    dmDitherType;
       public int    dmReserved1;
       public int    dmReserved2;
       public int    dmPanningWidth;
       public int    dmPanningHeight;
    }; 

    class NativeMethods 
    { 
        [DllImport("user32.dll")] 
        public static extern int EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE devMode); 
        [DllImport("user32.dll")] 
        public static extern int ChangeDisplaySettings(ref DEVMODE devMode, int flags); 

        public const int ENUM_CURRENT_SETTINGS = -1; 
        public const int CDS_UPDATEREGISTRY = 0x01; 
        public const int CDS_TEST = 0x02; 
        public const int DISP_CHANGE_SUCCESSFUL = 0; 
        public const int DISP_CHANGE_RESTART = 1; 
        public const int DISP_CHANGE_FAILED = -1;
        public const int DMDO_DEFAULT = 0;
        public const int DMDO_90 = 1;
        public const int DMDO_180 = 2;
        public const int DMDO_270 = 3;
    } 



    public class PrmaryScreenResolution 
    { 
        static public string ChangeResolution() 
        { 

            DEVMODE dm = GetDevMode(); 

            if (0 != NativeMethods.EnumDisplaySettings(null, NativeMethods.ENUM_CURRENT_SETTINGS, ref dm)) 
            {

                // swap width and height
                int temp = dm.dmPelsHeight;
                dm.dmPelsHeight = dm.dmPelsWidth;
                dm.dmPelsWidth = temp;

                // determine new orientation based on the current orientation
                switch(dm.dmDisplayOrientation)
                {
                    case NativeMethods.DMDO_DEFAULT:
                        dm.dmDisplayOrientation = NativeMethods.DMDO_270;
                        break;
                    case NativeMethods.DMDO_270:
                        dm.dmDisplayOrientation = NativeMethods.DMDO_180;
                        break;
                    case NativeMethods.DMDO_180:
                        dm.dmDisplayOrientation = NativeMethods.DMDO_90;
                        break;
                    case NativeMethods.DMDO_90:
                        dm.dmDisplayOrientation = NativeMethods.DMDO_DEFAULT;
                        break;
                    default:
                        // unknown orientation value
                        // add exception handling here
                        break;
                }


                int iRet = NativeMethods.ChangeDisplaySettings(ref dm, NativeMethods.CDS_TEST); 

                if (iRet == NativeMethods.DISP_CHANGE_FAILED) 
                { 
                    return "Unable To Process Your Request. Sorry For This Inconvenience."; 
                } 
                else 
                { 
                    iRet = NativeMethods.ChangeDisplaySettings(ref dm, NativeMethods.CDS_UPDATEREGISTRY); 
                    switch (iRet) 
                    { 
                        case NativeMethods.DISP_CHANGE_SUCCESSFUL: 
                            { 
                                return "Success"; 
                            } 
                        case NativeMethods.DISP_CHANGE_RESTART: 
                            { 
                                return "You Need To Reboot For The Change To Happen.\n If You Feel Any Problem After Rebooting Your Machine\nThen Try To Change Resolution In Safe Mode."; 
                            } 
                        default: 
                            { 
                                return "Failed To Change The Resolution"; 
                            } 
                    } 

                } 


            } 
            else 
            { 
                return "Failed To Change The Resolution."; 
            } 
        } 

        private static DEVMODE GetDevMode() 
        { 
            DEVMODE dm = new DEVMODE(); 
            dm.dmDeviceName = new String(new char[32]); 
            dm.dmFormName = new String(new char[32]); 
            dm.dmSize = (short)Marshal.SizeOf(dm); 
            return dm; 
        } 
    } 
} 

"@ 

Add-Type $pinvokeCode -ErrorAction SilentlyContinue 
[Resolution.PrmaryScreenResolution]::ChangeResolution() 
}


Clear

$ProgressPreference = 'SilentlyContinue'

Write-Host "Downloading Required Files"
Write-Host "-----------------------------------------------------------------------"

Write-Host -NoNewline "- APU Chipset Drivers from Valve: "
Invoke-WebRequest -URI "https://steamdeck-packages.steamos.cloud/misc/windows/drivers/Aerith%20Windows%20Driver_2209130944.zip" -OutFile ".\APU_Drivers.zip"
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- Audio Drivers 1/2 from Valve (cs35l41): "
Invoke-WebRequest -URI "https://steamdeck-packages.steamos.cloud/misc/windows/drivers/cs35l41-V1.2.1.0.zip" -OutFile ".\Audio_Drivers_1.zip"
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- Audio Drivers 2/2 from Valve (NAU88L21): "
Invoke-WebRequest -URI "https://steamdeck-packages.steamos.cloud/misc/windows/drivers/NAU88L21_x64_1.0.6.0_WHQL%20-%20DUA_BIQ_WHQL.zip" -OutFile ".\Audio_Drivers_2.zip"
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- Unlocked Wireless LAN Drivers from RTK: "
Invoke-WebRequest -URI "https://www.techpowerup.com/forums/attachments/rtk-killer-wi-fi-5-8822ce-xtreme-802-11ac_v2024-10-227-2-self-signed-fix2-zip.271297/" -OutFile ".\WLAN_Drivers.zip"
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- Bluetooth Drivers from Realtek: "
Invoke-WebRequest -URI "https://catalog.s.download.windowsupdate.com/d/msdownload/update/driver/drvs/2022/08/ad501382-9e48-4720-92c7-bcee5374671e_501f5f234304610bbbc221823de181e544c1bc09.cab" -OutFile ".\Bluetooth_Drivers.cab"
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- MicroSD Card Reader Drivers from BayHubTech: "
Invoke-WebRequest -URI "https://catalog.s.download.windowsupdate.com/c/msdownload/update/driver/drvs/2022/10/4f20ec00-bee5-4df2-873c-3a49cf4d4f8b_0aaf931a756473e6f8be1ef890fb60c283e9e82e.cab" -OutFile ".\MicroSD_Drivers.cab"
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- VC++ All in One Redistributable: "
Invoke-WebRequest -URI "https://github.com/abbodi1406/vcredist/releases/download/v0.64.0/VisualCppRedist_AIO_x86_x64_64.zip" -OutFile ".\VCpp.zip"
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- DirectX Web Setup: "
Invoke-WebRequest -URI "https://download.microsoft.com/download/1/7/1/1718CCC4-6315-4D8E-9543-8E28A4E18C4C/dxwebsetup.exe" -OutFile ".\DirectX.exe"
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- .NET 6.0 Setup: "
Invoke-WebRequest -URI "https://download.visualstudio.microsoft.com/download/pr/08ada4db-1e64-4829-b36d-5beb71f67bff/b77050cf7e0c71d3b95418651db1a9b8/dotnet-sdk-6.0.403-win-x64.exe" -OutFile ".\dotnet6.0_Setup.exe"
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- ViGEmBus Setup: "
Invoke-WebRequest -URI "https://github.com/ViGEm/ViGEmBus/releases/download/v1.21.442.0/ViGEmBus_1.21.442_x64_x86_arm64.exe" -OutFile ".\ViGEmBus_Setup.exe"
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- RivaTuner Setup: "
Invoke-WebRequest -URI "https://www.filecroco.com/download-file/download-rivatuner-statistics-server/14914/2360/" -OutFile ".\RivaTuner_Setup.exe"
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- SteamDeckTools: "
Invoke-WebRequest -URI "https://github.com/ayufan/steam-deck-tools/releases/download/0.5.36/SteamDeckTools-0.5.36-portable.zip" -OutFile ".\SteamDeckTools.zip"
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- EqualizerAPO: "
Invoke-WebRequest -UserAgent "Wget" -URI "https://sourceforge.net/projects/equalizerapo/files/latest/download" -OutFile ".\EqualizerAPO_Setup.exe"
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- EqualizerAPO Config: "
Invoke-WebRequest -UserAgent "Wget" -URI "https://raw.githubusercontent.com/CelesteHeartsong/SteamDeckAutomatedInstall/main/EqualizerAPO_Config.txt" -OutFile ".\EqualizerAPO_Config.txt"
Write-Host -ForegroundColor Green "Done"

Write-Host "-----------------------------------------------------------------------"
Write-Host




Write-Host "Applying Windows OS Tweaks"
Write-Host "-----------------------------------------------------------------------"

Write-Host -NoNewline "- Disabling Hibernation: "
Start-Process -FilePath "PowerCfg" -ArgumentList "/h /type reduced"
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- Setting CPU Idle Min to 0% (Reduce fan speed): "
Start-Process -FilePath "PowerCfg" -ArgumentList "/SETACVALUEINDEX SCHEME_CURRENT SUB_PROCESSOR IDLEDISABLE 000" -Wait
Start-Process -FilePath "PowerCfg" -ArgumentList "/SETACTIVE SCHEME_CURRENT" -Wait
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- Setting internal Clock to UTC: "
Start-Process -FilePath "reg" -ArgumentList "add `"HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\TimeZoneInformation`" /v RealTimeIsUniversal /d 1 /t REG_DWORD /f" -Wait
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- Disable GameDVR: "
Start-Process -FilePath "reg" -ArgumentList "add `"HKEY_CURRENT_USER\System\GameConfigStore`" /f /v GameDVR_Enabled /t REG_DWORD /d 0" -Wait
Write-Host -ForegroundColor Green "Done"

Write-Host "-----------------------------------------------------------------------"
Write-Host




Write-Host "Installing Drivers (Don't reboot on APU install!)"
Write-Host "-----------------------------------------------------------------------"

Write-Host -NoNewline "- Installing APU Chipset: "
Expand-Archive ".\APU_Drivers.zip" -DestinationPath ".\APU_Drivers" -Force
Start-Process ".\APU_Drivers\Aerith Windows Driver_2209130944\220913a-383120E-2209130944\Setup.exe" -Wait | Out-Null
$apicall::SystemParametersInfo(0x009F, 4294967295, $null, 1) | Out-Null
Set-ScreenResolutionAndOrientation | Out-Null
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- Audio Drivers 1/2: "
Expand-Archive ".\Audio_Drivers_1.zip" ".\Audio_Drivers_1" -Force
Start-Process -FilePath "PNPUtil.exe" -ArgumentList "/add-driver `".\Audio_Drivers_1\cs35l41-V1.2.1.0\cs35l41.inf`" /install" -Wait
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- Audio Drivers 2/2: "
Expand-Archive ".\Audio_Drivers_2.zip" ".\Audio_Drivers_2" -Force
Start-Process -FilePath "PNPUtil.exe" -ArgumentList "/add-driver `".\Audio_Drivers_2\NAU88L21_x64_1.0.6.0_WHQL - DUA_BIQ_WHQL\NAU88L21.inf`" /install" -Wait
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- WLAN Drivers: "
Expand-Archive ".\WLAN_Drivers.zip" ".\WLAN_Drivers" -Force
Start-Process  -FilePath "cmd.exe" -ArgumentList '/c  ".\WLAN_Drivers\RTK Killer Wi-Fi 5 8822CE Xtreme 802.11ac_v2024.10.227.2-[Self-Signed]Fix2\setup.bat"' -Wait
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- Bluetooth Drivers: "
New-Item .\Bluetooth_Drivers -ItemType Directory -ErrorAction SilentlyContinue >> $null
Start-Process -FilePath "expand.exe" -ArgumentList "-F:* .\Bluetooth_Drivers.cab .\Bluetooth_Drivers" -Wait
Start-Process -FilePath "PNPUtil.exe" -ArgumentList "/add-driver `".\Bluetooth_Drivers\Rtkfilter.inf`" /install" -Wait
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- MicroSD Drivers: "
New-Item .\MicroSD_Drivers -ItemType Directory -ErrorAction SilentlyContinue >> $null
Start-Process -FilePath "expand.exe" -ArgumentList "-F:* .\MicroSD_Drivers.cab .\MicroSD_Drivers" -Wait
Start-Process -FilePath "PNPUtil.exe" -ArgumentList "/add-driver `".\MicroSD_Drivers\bhtsddr.inf`" /install" -Wait
Write-Host -ForegroundColor Green "Done"

Write-Host "-----------------------------------------------------------------------"
Write-Host




Write-Host "Installing Redistributables"
Write-Host "-----------------------------------------------------------------------"

Write-Host -NoNewline "- VC++ All in One: "
Expand-Archive ".\VCpp.zip" -DestinationPath ".\Vcpp" -Force
Start-Process .\Vcpp\VisualCppRedist_AIO_x86_x64.exe /ai -Wait
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- DirectX Web Setup: "
Start-Process -FilePath ".\DirectX.exe" -ArgumentList "/Q" -Wait
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- .NET 6.0: "
Start-Process -FilePath ".\dotnet6.0_Setup.exe" -ArgumentList "/quiet /norestart" -Wait
Write-Host -ForegroundColor Green "Done"

Write-Host "-----------------------------------------------------------------------"
Write-Host



Write-Host "Installing Software (Select Speakers when requested)"
Write-Host "-----------------------------------------------------------------------"

Write-Host -NoNewline "- ViGEmBus: "
Start-Process -FilePath ".\ViGEmBus_Setup.exe" -ArgumentList "/qn /norestart" -Wait
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- Create C:\DeckUtils: "
New-Item C:\DeckUtils -ItemType Directory -ErrorAction SilentlyContinue >> $null
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- RivaTuner: "
Start-Process -FilePath ".\RivaTuner_Setup.exe" -ArgumentList "/S" -Wait
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- SteamDeckTools: "
Expand-Archive ".\SteamDeckTools.zip" "C:\DeckUtils\SteamDeckTools" -Force
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- EqualizerAPO: "
Start-Process -FilePath ".\EqualizerAPO_Setup.exe" -ArgumentList "/S" -Wait
Copy-Item ".\EqualizerAPO_Config.txt" -Destination "C:\Program Files\EqualizerAPO\config\config.txt" -Force
Write-Host -ForegroundColor Green "Done"

Write-Host "-----------------------------------------------------------------------"
Write-Host



Write-Host "Configuring Software"
Write-Host "-----------------------------------------------------------------------"

$trigger = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Write-Host -NoNewline "- Setting RivaTuner to run on login: "
$action = New-ScheduledTaskAction -Execute "C:\Program Files (x86)\RivaTuner Statistics Server\RTSS.exe"
$description = "Start RivaTuner at Login"
Register-ScheduledTask -TaskName "RivaTuner" -Action $action -Trigger $trigger -RunLevel Highest -Description $description -Settings $settings >> $null
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- Setting FanControl to run on login: "
Start-Process -FilePath "C:\DeckUtils\SteamDeckTools\FanControl.exe" -ArgumentList "-run-on-startup"
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- Setting PerformanceOverlay to run on login: "
Start-Process -FilePath "C:\DeckUtils\SteamDeckTools\PerformanceOverlay.exe" -ArgumentList "-run-on-startup"
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- Setting PowerControl to run on login: "
Start-Process -FilePath "C:\DeckUtils\SteamDeckTools\PowerControl.exe" -ArgumentList "-run-on-startup"
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- Setting SteamController to run on login: "
Start-Process -FilePath "C:\DeckUtils\SteamDeckTools\SteamController.exe" -ArgumentList "-run-on-startup"
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- Creating Desktop Shortcuts for SteamDeckTools: "
$shell = New-Object -comObject WScript.Shell
$shortcut = $shell.CreateShortcut("$Home\Desktop\FanControl.lnk")
$shortcut.TargetPath = "C:\DeckUtils\SteamDeckTools\FanControl.exe"
$shortcut.Save()

$shell = New-Object -comObject WScript.Shell
$shortcut = $shell.CreateShortcut("$Home\Desktop\PerformanceOverlay.lnk")
$shortcut.TargetPath = "C:\DeckUtils\SteamDeckTools\PerformanceOverlay.exe"
$shortcut.Save()

$shell = New-Object -comObject WScript.Shell
$shortcut = $shell.CreateShortcut("$Home\Desktop\PowerControl.lnk")
$shortcut.TargetPath = "C:\DeckUtils\SteamDeckTools\PowerControl.exe"
$shortcut.Save()

$shell = New-Object -comObject WScript.Shell
$shortcut = $shell.CreateShortcut("$Home\Desktop\SteamController.lnk")
$shortcut.TargetPath = "C:\DeckUtils\SteamDeckTools\SteamController.exe"
$shortcut.Save()

Write-Host -ForegroundColor Green "Done"

Write-Host "-----------------------------------------------------------------------"
Write-Host

Write-Host " Script Completed! Please reboot your system to apply drivers/configuration. Press enter key to exit."
Read-Host
