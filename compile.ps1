# compile.ps1 - Java Compilation Script (Fixed Version)
param(
    [string]$SourceDir = "src",
    [string]$OutputDir = "bin",
    [switch]$Verbose,
    [switch]$Clean
)

Write-Host "=== Java Compilation ===" -ForegroundColor Cyan

# Check Java
if (!(Get-Command java -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Java not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Clean mode
if ($Clean) {
    if (Test-Path $OutputDir) {
        Remove-Item $OutputDir -Recurse -Force
        Write-Host "SUCCESS: Cleaned output directory" -ForegroundColor Green
    }
    exit 0
}

# Ensure output directory exists
if (!(Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    Write-Host "Created output directory: $OutputDir" -ForegroundColor Green
}

# Find Java files
$javaFiles = Get-ChildItem -Path $SourceDir -Filter "*.java" -Recurse

if (!$javaFiles) {
    Write-Host "ERROR: No Java files found in $SourceDir" -ForegroundColor Red
    Write-Host "Suggestions:" -ForegroundColor Yellow
    Write-Host "  1. Ensure Java files are in $SourceDir directory" -ForegroundColor Gray
    Write-Host "  2. Use .\dev.ps1 and select 8 then 1 to create new Java class" -ForegroundColor Gray
    exit 1
}

Write-Host "Found $($javaFiles.Count) Java files" -ForegroundColor Green

if ($Verbose) {
    Write-Host "File list:" -ForegroundColor Cyan
    $javaFiles | ForEach-Object { Write-Host "  $($_.Name)" -ForegroundColor Gray }
}

# Compile
Write-Host "`nCompiling..." -ForegroundColor Yellow
$startTime = Get-Date

# 使用正确的方法传递文件路径给 javac
$filePaths = @()
foreach ($file in $javaFiles) {
    $filePaths += $file.FullName
}

# 方法1：直接传递所有文件路径
Write-Host "Executing: javac -d $OutputDir -cp $OutputDir (list of files)" -ForegroundColor Gray
javac -d $OutputDir -cp $OutputDir @filePaths 2>&1 | Tee-Object -Variable compileOutput

$endTime = Get-Date
$duration = $endTime - $startTime

# Check result
if ($LASTEXITCODE -eq 0) {
    Write-Host "SUCCESS: Compiled successfully!" -ForegroundColor Green
    Write-Host "Time: $($duration.TotalSeconds.ToString('0.00')) seconds" -ForegroundColor Gray
    Write-Host "Output directory: $(Resolve-Path $OutputDir)" -ForegroundColor Gray
    
    # Show generated class files
    $classFiles = Get-ChildItem -Path $OutputDir -Filter "*.class" -Recurse
    if ($classFiles) {
        Write-Host "Generated $($classFiles.Count) class files:" -ForegroundColor Cyan
        if ($Verbose) {
            $classFiles | ForEach-Object { Write-Host "  $($_.Name)" -ForegroundColor Gray }
        } else {
            $mainClasses = $classFiles | Where-Object { $_.Name -match ".*[Mm]ain.*" -or $_.Name -eq "App.class" }
            if ($mainClasses) {
                Write-Host "Runnable main classes:" -ForegroundColor Yellow
                $mainClasses | ForEach-Object { Write-Host "  $($_.BaseName)" -ForegroundColor Green }
            }
        }
    }
} else {
    Write-Host "ERROR: Compilation failed" -ForegroundColor Red
    Write-Host "Error details:" -ForegroundColor Yellow
    $compileOutput
    
    # 尝试备用方法
    Write-Host "`nTrying alternative compilation method..." -ForegroundColor Yellow
    Write-Host "Using simple javac command..." -ForegroundColor Gray
    javac -d $OutputDir $javaFiles.FullName
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS: Compiled using alternative method!" -ForegroundColor Green
    }
}