# run.ps1 - Java Run Script
param(
    [string]$ClassName,
    [string]$ClassPath = "bin",
    [string[]]$ProgramArguments,
    [switch]$FindMain,
    [switch]$ListClasses
)

Write-Host "=== Java Runner ===" -ForegroundColor Cyan

# List all runnable classes
if ($ListClasses) {
    if (!(Test-Path $ClassPath)) {
        Write-Host "ERROR: Directory $ClassPath not found" -ForegroundColor Red
        exit 1
    }
    
    $classFiles = Get-ChildItem -Path $ClassPath -Filter "*.class" -Recurse
    if (!$classFiles) {
        Write-Host "ERROR: No class files found, please compile first" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Runnable main classes:" -ForegroundColor Green
    
    # Try to detect classes with main method
    $mainClasses = @()
    foreach ($file in $classFiles) {
        $fullClassName = ($file.FullName.Replace("$ClassPath\", "") -replace '\\', '.' -replace '\.class$', '')
        try {
            # Check if has main method
            $check = java -cp $ClassPath -Djava.security.manager -Djava.security.policy==$null $fullClassName 2>&1
            if ($check -match "main") {
                $mainClasses += $fullClassName
                Write-Host "  $fullClassName" -ForegroundColor Green
            }
        } catch {}
    }
    
    if ($mainClasses.Count -eq 0) {
        Write-Host "No main classes detected" -ForegroundColor Yellow
        if (Test-Path "$ClassPath\App.class") {
            Write-Host "  App (commonly used)" -ForegroundColor Gray
        }
    }
    exit 0
}

# If no class name specified, try to find
if ([string]::IsNullOrWhiteSpace($ClassName) -or $FindMain) {
    # First check common class names
    $possibleClasses = @("App", "Main", "Application", "Start")
    
    foreach ($possible in $possibleClasses) {
        if (Test-Path "$ClassPath\$possible.class") {
            $ClassName = $possible
            Write-Host "Auto-selected class: $ClassName" -ForegroundColor Yellow
            break
        }
    }
    
    if ([string]::IsNullOrWhiteSpace($ClassName)) {
        Write-Host "ERROR: No class name specified and no common main class found" -ForegroundColor Red
        Write-Host "Use one of these methods:" -ForegroundColor Yellow
        Write-Host "  1. .\run.ps1 -ListClasses (show all classes)" -ForegroundColor Gray
        Write-Host "  2. .\run.ps1 -ClassName ClassName (specify class)" -ForegroundColor Gray
        Write-Host "  3. .\run.ps1 -FindMain (auto-find)" -ForegroundColor Gray
        exit 1
    }
}

# Check if class file exists
$classFile = "$ClassPath\$ClassName.class"
if (!(Test-Path $classFile)) {
    Write-Host "ERROR: Class file not found: $classFile" -ForegroundColor Red
    
    # Check if compilation is needed
    $compile = Read-Host "Compile project now? (y/n)"
    if ($compile -eq 'y') {
        Write-Host "Compiling..." -ForegroundColor Yellow
        if (Test-Path ".\compile.ps1") {
            .\compile.ps1
        } else {
            if (!(Test-Path "bin")) { New-Item -ItemType Directory -Path "bin" -Force }
            $javaFiles = Get-ChildItem -Path "src" -Filter "*.java" -Recurse
            if ($javaFiles) {
                javac -d bin $javaFiles.FullName
            }
        }
        
        # Re-check
        if (Test-Path $classFile) {
            Write-Host "SUCCESS: Compiled, continuing..." -ForegroundColor Green
        } else {
            Write-Host "ERROR: $ClassName.class still not found after compilation" -ForegroundColor Red
            exit 1
        }
    } else {
        exit 1
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
        java -cp $ClassPath $ClassName $ProgramArguments
    } else {
        java -cp $ClassPath $ClassName
    }
} catch {
    Write-Host "ERROR: Runtime error: $_" -ForegroundColor Red
}

$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "-" * 60 -ForegroundColor DarkGray
Write-Host "Run time: $($duration.TotalSeconds.ToString('0.000')) seconds" -ForegroundColor Gray
Write-Host "Exit code: $LASTEXITCODE" -ForegroundColor Gray