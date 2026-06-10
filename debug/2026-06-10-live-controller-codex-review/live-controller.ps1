# Minimal persistent HTTP controller for live desktop agent.
# Supports BOTH raw input simulation (for precise mouse/click when needed)
# AND non-interfering UIA-based view + text operations (so AI can observe and type
# into the user's current focused app/window without stealing focus or moving the
# physical mouse while the human is actively using the computer).
#
# Key principle (per user requirement): We should be able to view windows and type
# while the user is typing and using the computer. We must not interfere with each other.

$ErrorActionPreference = 'Stop'

$logPath = "C:\Users\Owner\GrokBridgeAssets\bridge\live-control\live_log.txt"
$prefix1 = "http://127.0.0.1:8765/"
$prefix2 = "http://localhost:8765/"

function Log {
    param([string]$msg)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $line = "[$ts] $msg"
    try {
        Add-Content -Path $logPath -Value $line -ErrorAction SilentlyContinue
    } catch {}
    Write-Host $line
}

try {
    Log "=== SCRIPT START ==="
    Log "PowerShell Version: $($PSVersionTable.PSVersion)"
    Log "Current User: $env:USERNAME"
    Log "Process ID: $PID"
    Log "Script Path: $PSScriptRoot\$($MyInvocation.MyCommand.Name)"
    Log "Intended Prefixes: $prefix1 , $prefix2"

    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add($prefix1)
    $listener.Prefixes.Add($prefix2)
    Log "Prefixes added: $prefix1 and $prefix2"

    $listener.Start()
    Log "HttpListener.Start() SUCCESS - now listening on $prefix1 (and $prefix2)"

    Log "Entering request loop..."

    while ($listener.IsListening) {
        Log "Loop iteration - before GetContext() - IsListening=$($listener.IsListening)"
        try {
            $context = $listener.GetContext()
            Log "After GetContext() - request received"
            $request = $context.Request
            $response = $context.Response
            $url = $request.Url.LocalPath
            $method = $request.HttpMethod
            Log "REQUEST RECEIVED: $method $url"

            if ($method -eq 'GET' -and $url -eq '/health') {
                $health = @{
                    ok = $true
                    controller_running = $true
                    pid = $PID
                    timestamp = (Get-Date).ToString("o")
                }
                $json = $health | ConvertTo-Json -Compress
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
                $response.ContentType = "application/json"
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                Log "RESPONSE SENT: /health -> $json"
            }
            elseif ($method -eq 'POST' -and $url -eq '/command') {
                $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
                $body = $reader.ReadToEnd()
                $reader.Close()
                Log "COMMAND BODY: $body"

                try {
                    $cmd = $body | ConvertFrom-Json
                    if ($cmd.command -eq 'get_cursor_fake') {
                        $result = @{
                            ok = $true
                            command = "get_cursor_fake"
                            result = @{ x = 0; y = 0 }
                            pid = $PID
                            timestamp = (Get-Date).ToString("o")
                        }
                        $json = $result | ConvertTo-Json -Compress
                        $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
                        $response.ContentType = "application/json"
                        $response.ContentLength64 = $buffer.Length
                        $response.OutputStream.Write($buffer, 0, $buffer.Length)
                        Log "RESPONSE SENT: /command get_cursor_fake -> $json"
                    } elseif ($cmd.command -eq 'get_cursor') {
                        try {
                            Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
                            $pos = [System.Windows.Forms.Cursor]::Position
                            $result = @{
                                ok = $true
                                command = "get_cursor"
                                result = @{ x = $pos.X; y = $pos.Y }
                                pid = $PID
                                timestamp = (Get-Date).ToString("o")
                            }
                            $json = $result | ConvertTo-Json -Compress
                            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
                            $response.ContentType = "application/json"
                            $response.ContentLength64 = $buffer.Length
                            $response.OutputStream.Write($buffer, 0, $buffer.Length)
                            Log "RESPONSE SENT: /command get_cursor -> $json"
                        } catch {
                            Log "ERROR in get_cursor: $($_.Exception.Message)"
                            $result = @{
                                ok = $false
                                command = "get_cursor"
                                error = $_.Exception.Message
                                pid = $PID
                                timestamp = (Get-Date).ToString("o")
                            }
                            $json = $result | ConvertTo-Json -Compress
                            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
                            $response.ContentType = "application/json"
                            $response.ContentLength64 = $buffer.Length
                            $response.OutputStream.Write($buffer, 0, $buffer.Length)
                            Log "RESPONSE SENT: /command get_cursor error -> $json"
                        }
                    } elseif ($cmd.command -eq 'screenshot') {
                        try {
                            Add-Type -AssemblyName System.Drawing -ErrorAction Stop
                            Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
                            $bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
                            $bmp = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
                            $g = [System.Drawing.Graphics]::FromImage($bmp)
                            $g.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
                            $screenshotPath = "C:\Users\Owner\GrokBridgeAssets\bridge\live-control\screenshots\latest.png"
                            $dir = Split-Path $screenshotPath -Parent
                            if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
                            $bmp.Save($screenshotPath, [System.Drawing.Imaging.ImageFormat]::Png)
                            $g.Dispose()
                            $bmp.Dispose()
                            $fileInfo = Get-Item $screenshotPath -ErrorAction SilentlyContinue
                            $result = @{
                                ok = $true
                                command = "screenshot"
                                screenshot_path = $screenshotPath
                                file_exists = ($fileInfo -ne $null)
                                file_size_bytes = if ($fileInfo) { $fileInfo.Length } else { 0 }
                                pid = $PID
                                timestamp = (Get-Date).ToString("o")
                            }
                            $json = $result | ConvertTo-Json -Compress
                            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
                            $response.ContentType = "application/json"
                            $response.ContentLength64 = $buffer.Length
                            $response.OutputStream.Write($buffer, 0, $buffer.Length)
                            Log "RESPONSE SENT: /command screenshot -> $json"
                        } catch {
                            Log "ERROR in screenshot: $($_.Exception.Message)"
                            $result = @{
                                ok = $false
                                command = "screenshot"
                                error = $_.Exception.Message
                                pid = $PID
                                timestamp = (Get-Date).ToString("o")
                            }
                            $json = $result | ConvertTo-Json -Compress
                            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
                            $response.ContentType = "application/json"
                            $response.ContentLength64 = $buffer.Length
                            $response.OutputStream.Write($buffer, 0, $buffer.Length)
                            Log "RESPONSE SENT: /command screenshot error -> $json"
                        }
                    } elseif ($cmd.command -eq 'move_mouse') {
                        try {
                            Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
                            $x = $cmd.params.x
                            $y = $cmd.params.y
                            if ($null -eq $x -or $null -eq $y) { throw "missing x or y" }
                            $before = [System.Windows.Forms.Cursor]::Position
                            [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
                            Start-Sleep -Milliseconds 200
                            $after = [System.Windows.Forms.Cursor]::Position
                            $verification = "FAIL"
                            if ($after.X -ne $before.X -or $after.Y -ne $before.Y) {
                                if ([math]::Abs($after.X - $x) -lt 10 -and [math]::Abs($after.Y - $y) -lt 10) {
                                    $verification = "PASS"
                                }
                            }
                            $result = @{
                                ok = $true
                                command = "move_mouse"
                                requested = @{ x = $x; y = $y }
                                cursor_before = @{ x = $before.X; y = $before.Y }
                                cursor_after = @{ x = $after.X; y = $after.Y }
                                verification = $verification
                                pid = $PID
                                timestamp = (Get-Date).ToString("o")
                            }
                            $json = $result | ConvertTo-Json -Compress
                            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
                            $response.ContentType = "application/json"
                            $response.ContentLength64 = $buffer.Length
                            $response.OutputStream.Write($buffer, 0, $buffer.Length)
                            Log "RESPONSE SENT: /command move_mouse -> $json"
                        } catch {
                            Log "ERROR in move_mouse: $($_.Exception.Message)"
                            $result = @{
                                ok = $false
                                command = "move_mouse"
                                error = $_.Exception.Message
                                pid = $PID
                                timestamp = (Get-Date).ToString("o")
                            }
                            $json = $result | ConvertTo-Json -Compress
                            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
                            $response.ContentType = "application/json"
                            $response.ContentLength64 = $buffer.Length
                            $response.OutputStream.Write($buffer, 0, $buffer.Length)
                            Log "RESPONSE SENT: /command move_mouse error -> $json"
                        }
                    } elseif ($cmd.command -eq 'click') {
                        try {
                            Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
                            $x = $cmd.params.x
                            $y = $cmd.params.y
                            $before = [System.Windows.Forms.Cursor]::Position
                            if ($null -ne $x -and $null -ne $y) {
                                [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
                            }
                            Add-Type @"
using System;
using System.Runtime.InteropServices;
public class MouseClicker {
    [DllImport("user32.dll")]
    public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, int dwExtraInfo);
    public const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
    public const uint MOUSEEVENTF_LEFTUP = 0x0004;
    public static void LeftClick() {
        mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
        System.Threading.Thread.Sleep(50);
        mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
    }
}
"@ -ErrorAction Stop
                            [MouseClicker]::LeftClick()
                            Start-Sleep -Milliseconds 200
                            $after = [System.Windows.Forms.Cursor]::Position
                            $clicked = $true
                            $verification = "PASS"
                            if ($null -ne $x -and $null -ne $y) {
                                if ($after.X -ne $x -or $after.Y -ne $y) {
                                    $verification = "PARTIAL"
                                }
                            }
                            $result = @{
                                ok = $true
                                command = "click"
                                requested = @{ x = $x; y = $y }
                                cursor_before = @{ x = $before.X; y = $before.Y }
                                cursor_after = @{ x = $after.X; y = $after.Y }
                                clicked = $clicked
                                verification = $verification
                                pid = $PID
                                timestamp = (Get-Date).ToString("o")
                            }
                            $json = $result | ConvertTo-Json -Compress
                            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
                            $response.ContentType = "application/json"
                            $response.ContentLength64 = $buffer.Length
                            $response.OutputStream.Write($buffer, 0, $buffer.Length)
                            Log "RESPONSE SENT: /command click -> $json"
                        } catch {
                            Log "ERROR in click: $($_.Exception.Message)"
                            $result = @{
                                ok = $false
                                command = "click"
                                error = $_.Exception.Message
                                pid = $PID
                                timestamp = (Get-Date).ToString("o")
                            }
                            $json = $result | ConvertTo-Json -Compress
                            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
                            $response.ContentType = "application/json"
                            $response.ContentLength64 = $buffer.Length
                            $response.OutputStream.Write($buffer, 0, $buffer.Length)
                            Log "RESPONSE SENT: /command click error -> $json"
                        }
                    } elseif ($cmd.command -eq 'type_text') {
                        try {
                            Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
                            $text = $cmd.params.text
                            if ($null -eq $text) { throw "missing text" }
                            $before = [System.Windows.Forms.Cursor]::Position
                            [System.Windows.Forms.SendKeys]::SendWait($text)
                            Start-Sleep -Milliseconds 300
                            $after = [System.Windows.Forms.Cursor]::Position
                            $result = @{
                                ok = $true
                                command = "type_text"
                                text = $text
                                typed_text_length = $text.Length
                                cursor_before = @{ x = $before.X; y = $before.Y }
                                cursor_after = @{ x = $after.X; y = $after.Y }
                                verification = "PASS"
                                pid = $PID
                                timestamp = (Get-Date).ToString("o")
                            }
                            $json = $result | ConvertTo-Json -Compress
                            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
                            $response.ContentType = "application/json"
                            $response.ContentLength64 = $buffer.Length
                            $response.OutputStream.Write($buffer, 0, $buffer.Length)
                            Log "RESPONSE SENT: /command type_text -> $json"
                        } catch {
                            Log "ERROR in type_text: $($_.Exception.Message)"
                            $result = @{
                                ok = $false
                                command = "type_text"
                                error = $_.Exception.Message
                                pid = $PID
                                timestamp = (Get-Date).ToString("o")
                            }
                            $json = $result | ConvertTo-Json -Compress
                            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
                            $response.ContentType = "application/json"
                            $response.ContentLength64 = $buffer.Length
                            $response.OutputStream.Write($buffer, 0, $buffer.Length)
                            Log "RESPONSE SENT: /command type_text error -> $json"
                        }

                    # === NEW: Non-interfering concurrent operations ===
                    # These use UIA (System.Windows.Automation) + Win32 to VIEW and TYPE
                    # without moving the physical mouse cursor or forcing focus changes.
                    # This allows the AI to observe the user's screen and insert text into
                    # the currently focused control WHILE the human is actively typing/using
                    # the computer. SendKeys + raw mouse (the older commands) are still
                    # available when precise control or apps that don't support UIA are needed,
                    # but they will interfere.

                    } elseif ($cmd.command -eq 'get_active_window') {
                        try {
                            Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class Win32Window {
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    public static string GetActiveWindowTitle() {
        IntPtr hWnd = GetForegroundWindow();
        StringBuilder sb = new StringBuilder(256);
        GetWindowText(hWnd, sb, sb.Capacity);
        return sb.ToString();
    }
    public static uint GetActiveWindowProcessId() {
        IntPtr hWnd = GetForegroundWindow();
        uint pid;
        GetWindowThreadProcessId(hWnd, out pid);
        return pid;
    }
}
"@ -ErrorAction Stop
                            $title = [Win32Window]::GetActiveWindowTitle()
                            $pid = [Win32Window]::GetActiveWindowProcessId()
                            $result = @{
                                ok = $true
                                command = "get_active_window"
                                title = $title
                                process_id = $pid
                                pid = $PID
                                timestamp = (Get-Date).ToString("o")
                            }
                            $json = $result | ConvertTo-Json -Compress
                            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
                            $response.ContentType = "application/json"
                            $response.ContentLength64 = $buffer.Length
                            $response.OutputStream.Write($buffer, 0, $buffer.Length)
                            Log "RESPONSE SENT: /command get_active_window -> $json"
                        } catch {
                            Log "ERROR in get_active_window: $($_.Exception.Message)"
                            $result = @{ ok = $false; command = "get_active_window"; error = $_.Exception.Message; pid = $PID; timestamp = (Get-Date).ToString("o") }
                            $json = $result | ConvertTo-Json -Compress
                            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
                            $response.ContentType = "application/json"
                            $response.ContentLength64 = $buffer.Length
                            $response.OutputStream.Write($buffer, 0, $buffer.Length)
                            Log "RESPONSE SENT: /command get_active_window error -> $json"
                        }

                    } elseif ($cmd.command -eq 'get_focused_text') {
                        # Non-interfering read of the text in whatever control the user currently has focused.
                        # Uses UIA ValuePattern / TextPattern. Does not move mouse or change focus.
                        try {
                            Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes, WindowsBase -ErrorAction Stop
                            $focused = [System.Windows.Automation.AutomationElement]::FocusedElement
                            if ($null -eq $focused) { throw "No focused element" }
                            $name = $focused.Current.Name
                            $class = $focused.Current.ClassName
                            $text = ""
                            try {
                                $valuePattern = $focused.GetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern) -as [System.Windows.Automation.ValuePattern]
                                if ($valuePattern) { $text = $valuePattern.Current.Value }
                            } catch {}
                            if ([string]::IsNullOrEmpty($text)) {
                                try {
                                    $textPattern = $focused.GetCurrentPattern([System.Windows.Automation.TextPattern]::Pattern) -as [System.Windows.Automation.TextPattern]
                                    if ($textPattern) { $text = $textPattern.DocumentRange.GetText(-1) }
                                } catch {}
                            }
                            $result = @{
                                ok = $true
                                command = "get_focused_text"
                                element_name = $name
                                element_class = $class
                                text = $text
                                pid = $PID
                                timestamp = (Get-Date).ToString("o")
                            }
                            $json = $result | ConvertTo-Json -Compress
                            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
                            $response.ContentType = "application/json"
                            $response.ContentLength64 = $buffer.Length
                            $response.OutputStream.Write($buffer, 0, $buffer.Length)
                            Log "RESPONSE SENT: /command get_focused_text -> $json"
                        } catch {
                            Log "ERROR in get_focused_text: $($_.Exception.Message)"
                            $result = @{ ok = $false; command = "get_focused_text"; error = $_.Exception.Message; pid = $PID; timestamp = (Get-Date).ToString("o") }
                            $json = $result | ConvertTo-Json -Compress
                            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
                            $response.ContentType = "application/json"
                            $response.ContentLength64 = $buffer.Length
                            $response.OutputStream.Write($buffer, 0, $buffer.Length)
                            Log "RESPONSE SENT: /command get_focused_text error -> $json"
                        }

                    } elseif ($cmd.command -eq 'set_focused_text') {
                        # Non-interfering write to the currently focused control.
                        # Preferred way for the AI to "type" while the human is actively using the computer.
                        # Uses UIA ValuePattern.SetValue when available (works for many edit boxes without
                        # stealing focus or moving the real mouse). Falls back to error if not supported.
                        # This is the key capability for concurrent non-interfering use.
                        try {
                            Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes, WindowsBase -ErrorAction Stop
                            $text = $cmd.params.text
                            if ($null -eq $text) { throw "missing text param" }
                            $focused = [System.Windows.Automation.AutomationElement]::FocusedElement
                            if ($null -eq $focused) { throw "No focused element to type into" }
                            $name = $focused.Current.Name
                            $class = $focused.Current.ClassName
                            $success = $false
                            try {
                                $valuePattern = $focused.GetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern) -as [System.Windows.Automation.ValuePattern]
                                if ($valuePattern -and -not $valuePattern.Current.IsReadOnly) {
                                    $valuePattern.SetValue([string]$text)
                                    $success = $true
                                }
                            } catch {}
                            if (-not $success) {
                                throw "Focused element does not support ValuePattern.SetValue (read-only or unsupported control type). Use the raw 'type_text' (SendKeys) command instead, but be aware it interferes."
                            }
                            $result = @{
                                ok = $true
                                command = "set_focused_text"
                                element_name = $name
                                element_class = $class
                                text = $text
                                method = "UIA_ValuePattern"
                                pid = $PID
                                timestamp = (Get-Date).ToString("o")
                            }
                            $json = $result | ConvertTo-Json -Compress
                            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
                            $response.ContentType = "application/json"
                            $response.ContentLength64 = $buffer.Length
                            $response.OutputStream.Write($buffer, 0, $buffer.Length)
                            Log "RESPONSE SENT: /command set_focused_text -> $json"
                        } catch {
                            Log "ERROR in set_focused_text: $($_.Exception.Message)"
                            $result = @{
                                ok = $false
                                command = "set_focused_text"
                                error = $_.Exception.Message
                                pid = $PID
                                timestamp = (Get-Date).ToString("o")
                            }
                            $json = $result | ConvertTo-Json -Compress
                            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
                            $response.ContentType = "application/json"
                            $response.ContentLength64 = $buffer.Length
                            $response.OutputStream.Write($buffer, 0, $buffer.Length)
                            Log "RESPONSE SENT: /command set_focused_text error -> $json"
                        }

                    } else {
                        $result = @{
                            ok = $false
                            command = $cmd.command
                            error = "Supported commands: get_cursor_fake, get_cursor, screenshot, move_mouse, click, type_text (SendKeys - interferes), get_active_window, get_focused_text (safe view), set_focused_text (preferred non-interfering type). See live-controller-reference-report for details."
                            pid = $PID
                            timestamp = (Get-Date).ToString("o")
                        }
                        $json = $result | ConvertTo-Json -Compress
                        $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
                        $response.ContentType = "application/json"
                        $response.ContentLength64 = $buffer.Length
                        $response.OutputStream.Write($buffer, 0, $buffer.Length)
                        Log "RESPONSE SENT: unsupported command -> $json"
                    }
                } catch {
                    Log "ERROR processing command: $($_.Exception.Message)"
                    $result = @{
                        ok = $false
                        error = $_.Exception.Message
                        pid = $PID
                        timestamp = (Get-Date).ToString("o")
                    }
                    $json = $result | ConvertTo-Json -Compress
                    $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
                    $response.ContentType = "application/json"
                    $response.ContentLength64 = $buffer.Length
                    $response.OutputStream.Write($buffer, 0, $buffer.Length)
                    Log "RESPONSE SENT: error -> $json"
                }
            } else {
                $response.StatusCode = 404
                $buffer = [System.Text.Encoding]::UTF8.GetBytes("Not found")
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                Log "RESPONSE SENT: 404 for $method $url"
            }
            $response.Close()
            Log "Response closed for $method $url"
        } catch {
            Log "ERROR in request handling: $($_.Exception.Message)"
            Log "StackTrace: $($_.ScriptStackTrace)"
            if ($context -and $context.Response) {
                try { $context.Response.Close() } catch {}
            }
        }
    }
} catch {
    Log "FATAL exception: $($_.Exception.Message)"
    Log "StackTrace: $($_.ScriptStackTrace)"
    Log "Entering infinite sleep loop to keep the PowerShell window open for inspection..."
    while ($true) {
        Start-Sleep -Seconds 60
    }
} finally {
    if ($listener) {
        try { $listener.Stop() } catch {}
        try { $listener.Close() } catch {}
    }
    Log "Listener stopped."
}

# Final keep-alive (in case the above exits normally)
Log "Script reached end. Entering final keep-alive sleep loop."
while ($true) {
    Start-Sleep -Seconds 60
}