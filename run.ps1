# run.ps1 - Java Runner with Interactive Menu
param(
    [string]$ClassName,
    [string]$ClassPath = "bin",
    [string[]]$ProgramArguments,
    [switch]$FindMain,
    [switch]$ListClasses,
    [switch]$Interactive
)

Write-Host "=== Java Runner ===" -ForegroundColor Cyan

# Function to detect main classes
# Function to detect main classes
function Get-MainClasses {
    param([string]$Path = "bin")
    
    if (!(Test-Path $Path)) {
        return @()
    }
    
    $classFiles = Get-ChildItem -Path $Path -Filter "*.class" -Recurse
    if (!$classFiles) {
        return @()
    }
    
    $mainClasses = @()
    
    foreach ($file in $classFiles) {
        # 修复：获取相对于bin目录的路径
        $relativePath = $file.FullName.Replace("$(Resolve-Path $Path)\", "")
        
        # 修复：跳过内部类（包含$的）
        if ($relativePath.Contains('$')) {
            continue
        }
        
        # 修复：将路径分隔符替换为点，并移除.class扩展名
        $fullClassName = $relativePath.Replace('\', '.').Replace('.class', '')
        
        if ([string]::IsNullOrWhiteSpace($fullClassName)) {
            continue
        }
        
        $mainClasses += @{
            Name      = $fullClassName
            File      = $file
            ShortName = $fullClassName.Split('.')[-1]
        }
    }
    
    return $mainClasses
}

# Function to verify if a class has main method
function Test-MainClass {
    param([string]$ClassName, [string]$ClassPath)
    
    # Quick check - try to run with --version flag (for testing)
    try {
        $output = java -cp $ClassPath $ClassName --version 2>&1
        # If it runs without "main method not found" error, it probably has main
        if ($output -notmatch "main" -and $output -notmatch "Main method not found") {
            return $true
        }
    }
    catch {}
    
    # Alternative: Try to run with no arguments
    try {
        # Use a timeout to prevent hanging
        $job = Start-Job -ScriptBlock {
            param($cp, $cn)
            java -cp $cp $cn 2>&1
        } -ArgumentList $ClassPath, $ClassName
        
        $result = $job | Wait-Job -Timeout 2 | Receive-Job
        $job | Remove-Job -Force
        
        # If we get output or no "main method not found", assume it's runnable
        if ($result -and $result -notmatch "Main method not found") {
            return $true
        }
    }
    catch {}
    
    return $false
}

# Interactive menu
function Show-InteractiveMenu {
    param([string]$ClassPath)
    
    Write-Host "`n=== Select Java Class to Run ===" -ForegroundColor Magenta
    
    $mainClasses = Get-MainClasses -Path $ClassPath
    
    if ($mainClasses.Count -eq 0) {
        Write-Host "No compiled classes found!" -ForegroundColor Red
        Write-Host "Please compile your project first." -ForegroundColor Yellow
        Write-Host "Use: .\compile.ps1 or option 2 in dev.ps1" -ForegroundColor Gray
        
        $compile = Read-Host "`nCompile now? (y/n)"
        if ($compile -eq 'y') {
            if (Test-Path ".\compile.ps1") {
                .\compile.ps1
                $mainClasses = Get-MainClasses -Path $ClassPath
            }
            else {
                Write-Host "compile.ps1 not found!" -ForegroundColor Red
                return $null
            }
        }
        else {
            return $null
        }
    }
    
    if ($mainClasses.Count -eq 0) {
        Write-Host "Still no classes found after compilation." -ForegroundColor Red
        return $null
    }
    
    Write-Host "`nAvailable classes:" -ForegroundColor Green
    
    $menuItems = @()
    $index = 1
    
    # First, show common classes
    $commonNames = @("App", "Main", "Application", "Start", "Program", "Jiecheng")
    foreach ($common in $commonNames) {
        $found = $mainClasses | Where-Object { $_.ShortName -eq $common }
        if ($found) {
            Write-Host "$index. [$common] - $($found.Name)" -ForegroundColor Cyan
            $menuItems += @{
                Index = $index
                Class = $found.Name
                Short = $common
            }
            $index++
        }
    }
    
    # Then show other classes
    if ($menuItems.Count -lt $mainClasses.Count) {
        Write-Host "---" -ForegroundColor DarkGray
        
        foreach ($class in $mainClasses) {
            if ($commonNames -notcontains $class.ShortName) {
                Write-Host "$index. $($class.ShortName) - $($class.Name)" -ForegroundColor White
                $menuItems += @{
                    Index = $index
                    Class = $class.Name
                    Short = $class.ShortName
                }
                $index++
            }
        }
    }
    
    Write-Host "`n0. Exit" -ForegroundColor Red
    Write-Host "L. List all classes" -ForegroundColor Gray
    Write-Host "R. Refresh list" -ForegroundColor Gray
    Write-Host "C. Compile project" -ForegroundColor Gray
    
    $choice = Read-Host "`nEnter choice"
    
    switch ($choice) {
        "0" { return "exit" }
        "L" {
            Write-Host "`nAll compiled classes:" -ForegroundColor Green
            foreach ($class in $mainClasses) {
                Write-Host "  $($class.Name)" -ForegroundColor Gray
            }
            Read-Host "Press Enter to continue"
            return Show-InteractiveMenu -ClassPath $ClassPath
        }
        "R" { 
            return Show-InteractiveMenu -ClassPath $ClassPath 
        }
        "C" {
            if (Test-Path ".\compile.ps1") {
                .\compile.ps1
            }
            else {
                Write-Host "Compiling manually..." -ForegroundColor Yellow
                javac -d bin src/*.java
            }
            return Show-InteractiveMenu -ClassPath $ClassPath
        }
        default {
            if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $menuItems.Count) {
                $selected = $menuItems[[int]$choice - 1]
                return $selected.Class
            }
            else {
                Write-Host "Invalid choice!" -ForegroundColor Red
                Read-Host "Press Enter to continue"
                return Show-InteractiveMenu -ClassPath $ClassPath
            }
        }
    }
}

# Function to run Java class
function Run-JavaClass {
    param(
        [string]$ClassName,
        [string]$ClassPath,
        [string[]]$ProgramArguments
    )
    
    # Check if class file exists
    $simpleName = $ClassName.Split('.')[-1]
    $classFile = "$ClassPath\$($ClassName.Replace('.', '\')).class"
    
    if (!(Test-Path $classFile)) {
        # Try simple name
        $classFile = "$ClassPath\$simpleName.class"
        if (!(Test-Path $classFile)) {
            Write-Host "ERROR: Class file not found: $ClassName" -ForegroundColor Red
            return $false
        }
    }
    
    # Prepare arguments
    $argString = ""
    if ($ProgramArguments) {
        $argString = $ProgramArguments -join " "
        Write-Host "Arguments: $argString" -ForegroundColor Gray
    }
    
    # Run Java program
    Write-Host "`nRunning $ClassName" -ForegroundColor Magenta
    Write-Host "Classpath: $(Resolve-Path $ClassPath)" -ForegroundColor Gray
    Write-Host "-" * 60 -ForegroundColor DarkGray
    
    $startTime = Get-Date
    try {
        if ($ProgramArguments) {
            java -cp $ClassPath $ClassName @ProgramArguments
        }
        else {
            java -cp $ClassPath $ClassName
        }
    }
    catch {
        Write-Host "ERROR: Runtime error: $_" -ForegroundColor Red
    }
    
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    Write-Host "-" * 60 -ForegroundColor DarkGray
    Write-Host "Run time: $($duration.TotalSeconds.ToString('0.000')) seconds" -ForegroundColor Gray
    Write-Host "Exit code: $LASTEXITCODE" -ForegroundColor Gray
    
    return $true
}

# Main logic
if ($ListClasses) {
    $mainClasses = Get-MainClasses -Path $ClassPath
    if ($mainClasses.Count -eq 0) {
        Write-Host "No classes found in $ClassPath" -ForegroundColor Yellow
    }
    else {
        Write-Host "Compiled classes:" -ForegroundColor Green
        foreach ($class in $mainClasses) {
            Write-Host "  $($class.Name)" -ForegroundColor Gray
        }
    }
    exit 0
}

# Interactive mode
if ($Interactive -or ([string]::IsNullOrWhiteSpace($ClassName) -and !$FindMain)) {
    $selectedClass = Show-InteractiveMenu -ClassPath $ClassPath
    
    if ($selectedClass -eq "exit") {
        Write-Host "Exiting..." -ForegroundColor Gray
        exit 0
    }
    
    if ($selectedClass) {
        Run-JavaClass -ClassName $selectedClass -ClassPath $ClassPath -ProgramArguments $ProgramArguments
        exit 0
    }
    else {
        Write-Host "No class selected." -ForegroundColor Yellow
        exit 1
    }
}

# Auto-find mode
if ($FindMain -or [string]::IsNullOrWhiteSpace($ClassName)) {
    $possibleClasses = @("App", "Main", "Application", "Start", "Program", "Jiecheng")
    
    foreach ($possible in $possibleClasses) {
        if (Test-Path "$ClassPath\$possible.class") {
            $ClassName = $possible
            Write-Host "Auto-selected class: $ClassName" -ForegroundColor Yellow
            break
        }
    }
    
    if ([string]::IsNullOrWhiteSpace($ClassName)) {
        Write-Host "ERROR: No main class found" -ForegroundColor Red
        Write-Host "Use: .\run.ps1 -Interactive (for menu)" -ForegroundColor Gray
        Write-Host "Or: .\run.ps1 -ClassName <name> (to specify)" -ForegroundColor Gray
        exit 1
    }
}

# Normal execution with specified class
if (![string]::IsNullOrWhiteSpace($ClassName)) {
    Run-JavaClass -ClassName $ClassName -ClassPath $ClassPath -ProgramArguments $ProgramArguments
    exit 0
}

Write-Host "ERROR: No class specified" -ForegroundColor Red
Write-Host "Usage:" -ForegroundColor Yellow
Write-Host "  .\run.ps1 -Interactive    (show menu)" -ForegroundColor Gray
Write-Host "  .\run.ps1 -ListClasses    (list all classes)" -ForegroundColor Gray
Write-Host "  .\run.ps1 -FindMain       (auto-find main class)" -ForegroundColor Gray
Write-Host "  .\run.ps1 -ClassName Name (run specific class)" -ForegroundColor Gray
exit 1