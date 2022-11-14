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

Write-Host -NoNewline "- Wireless LAN Drivers from Realtek: "
Invoke-WebRequest -URI "https://catalog.s.download.windowsupdate.com/d/msdownload/update/driver/drvs/2022/09/5fdcc0af-6e27-49c3-94e1-9b9936427f67_62d4379506801391f4f1516d837d98c5d0133f22.cab" -OutFile ".\WLAN_Drivers.cab"
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

Write-Host -NoNewline "- ViGEmBus Setup: "
Invoke-WebRequest -URI "https://github.com/ViGEm/ViGEmBus/releases/download/v1.21.442.0/ViGEmBus_1.21.442_x64_x86_arm64.exe" -OutFile ".\ViGEmBus_Setup.exe"
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- HVDK Standard Setup (Tetherscript): "
Invoke-WebRequest -URI "https://tetherscript.s3-us-west-2.amazonaws.com/HVDK/HVDK+Standard_2.1_Installer.exe" -OutFile ".\HVDK_Setup.exe"
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- HidHide Setup: "
Invoke-WebRequest -URI "https://github.com/ViGEm/HidHide/releases/download/v1.2.98.0/HidHide_1.2.98_x64.exe" -OutFile ".\HidHide_Setup.exe"
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- SWICD Setup: "
Invoke-WebRequest -URI "https://github.com/mKenfenheuer/steam-deck-windows-usermode-driver/releases/download/v0.3.2/SWICD_Setup.exe" -OutFile ".\SWICD_Setup.exe"
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- SWICD Config: "
Invoke-WebRequest -URI "https://raw.githubusercontent.com/CelesteHeartsong/SteamDeckAutomatedInstall/main/app_config.json" -Outfile ".\app_config.json"
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- AutoHotkey Setup: "
Invoke-WebRequest -URI "https://www.autohotkey.com/download/ahk-install.exe" -OutFile ".\AutoHotkey_Setup.exe"
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- AutoHotkey Script: "
Invoke-WebRequest -URI "https://raw.githubusercontent.com/CelesteHeartsong/SteamDeckAutomatedInstall/main/SteamDeckAHK.ahk" -OutFile ".\SteamDeckAHK.ahk"
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- Nircmd Package: "
Invoke-WebRequest -URI "http://www.nirsoft.net/utils/nircmd-x64.zip" -OutFile ".\nircmd.zip"
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- RyzenAdj Package: "
Invoke-WebRequest -URI "https://github.com/FlyGoat/RyzenAdj/releases/download/v0.11.1/ryzenadj-win64.zip" -OutFile ".\ryzenadj.zip"
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- EqualizerAPO: "
Invoke-WebRequest -UserAgent "Wget" -URI "https://sourceforge.net/projects/equalizerapo/files/latest/download" -OutFile ".\EqualizerAPO_Setup.exe"
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- Peace GUI: "
Invoke-WebRequest -UserAgent "Wget" -URI "https://sourceforge.net/projects/peace-equalizer-apo-extension/files/latest/download" -OutFile ".\Peace_Setup.exe"
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- SteamDeck Peace Config: "
Invoke-WebRequest -URI "https://raw.githubusercontent.com/baldsealion/Steamdeck-Ultimate-Windows11-Guide/main/Peace%20settings/SteamDeck.peace" -OutFile ".\SteamDeck.peace"
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- EDID Setup: "
Invoke-WebRequest -URI "https://raw.githubusercontent.com/CelesteHeartsong/SteamDeckAutomatedInstall/main/EDID_Setup.bat" -OutFile ".\EDID_Setup.bat"
Write-Host -ForegroundColor Green "Done"



Write-Host "-----------------------------------------------------------------------"
Write-Host




Write-Host "Applying Windows OS Tweaks"
Write-Host "-----------------------------------------------------------------------"

Write-Host -NoNewline "- Disabling Hibernation: "
Start-Process -FilePath "PowerCfg" -ArgumentList "-hibernate off"
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- Setting CPU Idle Min to 0% (Reduce fan speed): "
Start-Process -FilePath "PowerCfg" -ArgumentList "/SETACVALUEINDEX SCHEME_CURRENT SUB_PROCESSOR IDLEDISABLE 000" -Wait
Start-Process -FilePath "PowerCfg" -ArgumentList "/SETACTIVE SCHEME_CURRENT" -Wait
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- Setting internal Clock to UTC: "
Start-Process -FilePath "reg" -ArgumentList "add `"HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\TimeZoneInformation`" /v RealTimeIsUniversal /d 1 /t REG_DWORD /f" -Wait
Write-Host -ForegroundColor Green "Done"

Write-Host "-----------------------------------------------------------------------"
Write-Host




Write-Host "Installing Drivers (Don't reboot on APU install!)"
Write-Host "-----------------------------------------------------------------------"

Write-Host -NoNewline "- Installing APU Chipset: "
Expand-Archive ".\APU_Drivers.zip" -DestinationPath ".\APU_Drivers" -Force
Start-Process ".\APU_Drivers\Aerith Windows Driver_2209130944\220913a-383120E-2209130944\Setup.exe" -Wait
$apicall::SystemParametersInfo(0x009F, 4294967295, $null, 1) | Out-Null
Set-ScreenResolutionAndOrientation
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
New-Item .\WLAN_Drivers -ItemType Directory -ErrorAction SilentlyContinue >> $null
Start-Process -FilePath "expand.exe" -ArgumentList "-F:* .\WLAN_Drivers.cab .\WLAN_Drivers" -Wait
Start-Process -FilePath "PNPUtil.exe" -ArgumentList "/add-driver `".\WLAN_Drivers\netrtwlane.inf`" /install" -Wait
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

Write-Host "-----------------------------------------------------------------------"
Write-Host



Write-Host "Installing Software (Use Default Paths)"
Write-Host "-----------------------------------------------------------------------"

Write-Host -NoNewline "- ViGEmBus: "
Start-Process -FilePath ".\ViGEmBus_Setup.exe" -Wait
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- HVDK (Tetherscript): "
Start-Process -FilePath ".\HVDK_Setup.exe" -ArgumentList "/VERYSILENT" -Wait
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- HidHide: "
Start-Process -FilePath ".\HidHide_Setup.exe" -Wait
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- SWICD: "
Start-Process -FilePath ".\SWICD_Setup.exe" -Wait
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- AutoHotkey: "
Start-Process -FilePath ".\AutoHotkey_Setup.exe" -Wait
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- Create C:\DeckUtils: "
New-Item C:\DeckUtils -ItemType Directory -ErrorAction SilentlyContinue >> $null
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- NirCmd: "
Expand-Archive ".\nircmd.zip" "C:\DeckUtils\nircmd" -Force
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- RyzenAdj: "
Expand-Archive ".\ryzenadj.zip" "C:\DeckUtils\ryzenadj" -Force
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- EqualizerAPO: "
Start-Process -FilePath ".\EqualizerAPO_Setup.exe" -Wait
Write-Host -ForegroundColor Green "Done"

Write-Host "-----------------------------------------------------------------------"
Write-Host



Write-Host "Configuring Software"
Write-Host "-----------------------------------------------------------------------"

Write-Host -NoNewline "- Uninstalling HVDK Gamepad/Joystick Drivers: "
Start-Process -FilePath "C:\Program Files (x86)\HID Virtual Device Kit Standard 2.1\Drivers Signed\Gamepad\uninstall.bat" -Wait
Start-Process -FilePath "C:\Program Files (x86)\HID Virtual Device Kit Standard 2.1\Drivers Signed\Joystick\uninstall.bat" -Wait
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- Adding Default SWICD config: "
New-Item ~\Documents\SWICD -ItemType Directory -ErrorAction SilentlyContinue >> $null
Copy-Item ".\app_config.json" -Destination "~\Documents\SWICD\app_config.json" -Force
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- Setting AHK Script to run on login: "
Copy-Item ".\SteamDeckAHK.ahk" -Destination "C:\DeckUtils\SteamDeckAHK.ahk" -Force
$action = New-ScheduledTaskAction -Execute "C:\Program Files\AutoHotkey\AutoHotkey.exe" -Argument "C:\DeckUtils\SteamDeckAHK.ahk" 
$trigger = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries
$description = "Start AutoHotkey at Login"
Register-ScheduledTask -TaskName "AutoHotkey" -Action $action -Trigger $trigger -RunLevel Highest -Description $description -Settings $settings >> $null
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- Setting up Peace Config: "
Copy-Item ".\SteamDeck.peace" -Destination "C:\Program Files\EqualizerAPO\config\SteamDeck.peace" -Force
Start-Process -FilePath ".\Peace_Setup.exe" -Wait
Write-Host -ForegroundColor Green "Done"

Write-Host -NoNewline "- Overwriting EDID: "
Start-Process -FilePath ".\EDID_Setup.bat" -Wait
Write-Host -ForegroundColor Green "Done"

Write-Host "-----------------------------------------------------------------------"
Write-Host

Write-Host " Script Completed! Please reboot your system to apply drivers/EDID/configuration."
