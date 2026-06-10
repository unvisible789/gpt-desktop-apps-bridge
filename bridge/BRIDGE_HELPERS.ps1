# BRIDGE_HELPERS.ps1
# Human-like desktop control primitives for Grok / Codex bridge
# Robust mouse + keyboard using SendInput (fixes previous reliability issues on modern Windows / high DPI)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# P/Invoke SendInput for reliable absolute mouse positioning and clicks
Add-Type @"
using System;
using System.Runtime.InteropServices;

[StructLayout(LayoutKind.Sequential)]
public struct INPUT {
    public uint type;
    public MOUSEINPUT mi;
}

[StructLayout(LayoutKind.Sequential)]
public struct MOUSEINPUT {
    public int dx;
    public int dy;
    public uint mouseData;
    public uint dwFlags;
    public uint time;
    public IntPtr dwExtraInfo;
}

public class SendInputHelper {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);

    public const uint INPUT_MOUSE = 0;
    public const uint MOUSEEVENTF_MOVE = 0x0001;
    public const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
    public const uint MOUSEEVENTF_LEFTUP = 0x0004;
    public const uint MOUSEEVENTF_ABSOLUTE = 0x8000;

    public static void MoveMouseAbsolute(int screenX, int screenY) {
        var screen = System.Windows.Forms.Screen.PrimaryScreen.Bounds;
        INPUT input = new INPUT();
        input.type = INPUT_MOUSE;
        input.mi.dx = screenX * 65535 / screen.Width;
        input.mi.dy = screenY * 65535 / screen.Height;
        input.mi.dwFlags = MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE;
        SendInput(1, new INPUT[] { input }, Marshal.SizeOf(typeof(INPUT)));
    }

    public static void LeftClick() {
        INPUT down = new INPUT(); down.type = INPUT_MOUSE; down.mi.dwFlags = MOUSEEVENTF_LEFTDOWN;
        INPUT up = new INPUT(); up.type = INPUT_MOUSE; up.mi.dwFlags = MOUSEEVENTF_LEFTUP;
        SendInput(1, new INPUT[] { down }, Marshal.SizeOf(typeof(INPUT)));
        System.Threading.Thread.Sleep(45);
        SendInput(1, new INPUT[] { up }, Marshal.SizeOf(typeof(INPUT)));
    }
}
"@

function Wait-Human {
    param([int]$MinMs = 110, [int]$MaxMs = 420)
    Start-Sleep -Milliseconds (Get-Random -Minimum $MinMs -Maximum $MaxMs)
}

function Log-HumanAction {
    param([string]$Action, [string]$Details = "")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $line = "[$ts] $Action | $Details"
    $logPath = "$env:USERPROFILE\GrokBridgeAssets\HUMAN_ACTION.log"
    New-Item -ItemType Directory -Path (Split-Path $logPath) -Force -ErrorAction SilentlyContinue | Out-Null
    Add-Content -Path $logPath -Value $line -ErrorAction SilentlyContinue
    Write-Host $line -ForegroundColor Cyan
}

function Move-MouseHumanLike {
    param(
        [Parameter(Mandatory)] [int] $TargetX,
        [Parameter(Mandatory)] [int] $TargetY,
        [int] $DurationMs = 620,
        [switch] $AddMicroJitter
    )
    $start = [System.Windows.Forms.Cursor]::Position
    $steps = [math]::Max(10, [math]::Floor($DurationMs / 35))

    for ($i = 0; $i -le $steps; $i++) {
        $t = $i / $steps
        $ease = $t * $t * (3 - 2 * $t)  # smoothstep Bezier-like
        $x = [math]::Round($start.X + ($TargetX - $start.X) * $ease)
        $y = [math]::Round($start.Y + ($TargetY - $start.Y) * $ease)

        if ($AddMicroJitter -and ($i % 2 -eq 0)) {
            $x += Get-Random -Min -2 -Max 3
            $y += Get-Random -Min -1 -Max 2
        }
        [SendInputHelper]::MoveMouseAbsolute($x, $y)
        Start-Sleep -Milliseconds ([math]::Max(6, $DurationMs / $steps))
    }
    [SendInputHelper]::MoveMouseAbsolute($TargetX, $TargetY)
    Wait-Human -MinMs 70 -MaxMs 160
    Log-HumanAction "MouseMove" "($TargetX, $TargetY) over ${DurationMs}ms"
}

function Click-HumanLike {
    param([int]$X, [int]$Y, [string]$Button = "Left")
    Move-MouseHumanLike -TargetX $X -TargetY $Y -DurationMs (Get-Random -Min 380 -Max 720) -AddMicroJitter
    Wait-Human -MinMs 55 -MaxMs 130
    if ($Button -eq "Left") { [SendInputHelper]::LeftClick() }
    Wait-Human -MinMs 80 -MaxMs 200
    Log-HumanAction "Click$Button" "at ($X,$Y)"
}

function Type-HumanLike {
    param([string]$Text)
    foreach ($c in $Text.ToCharArray()) {
        [System.Windows.Forms.SendKeys]::SendWait("$c")
        $d = 48 + (Get-Random -Min -18 -Max 42)
        if ($c -match '[ .,!?]') { $d += 90 }
        Start-Sleep -Milliseconds $d
    }
    Log-HumanAction "Typed" $Text
}

function FindAndClickHuman {
    param([string]$SearchText)
    # Placeholder - replace with real UIA or vision later
    Write-Warning "FindAndClickHuman is placeholder. Provide real vision coords or implement UIA."
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    Click-HumanLike -X ([int]($screen.Width * 0.5)) -Y ([int]($screen.Height * 0.45))
}

Write-Host "[BRIDGE_HELPERS] Loaded - robust human-like mouse/keyboard ready (SendInput)" -ForegroundColor Green
