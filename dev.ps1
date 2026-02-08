# dev.ps1 - Java Development Assistant
Write-Host "=== Java Development Assistant ===" -ForegroundColor Cyan
Write-Host "Project: firstone" -ForegroundColor Gray
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor Gray

# Check environment
function Test-Environment {
    if (!(Get-Command java -ErrorAction SilentlyContinue)) {
        Write-Host "ERROR: Java not installed or not in PATH" -ForegroundColor Red
        return $false
    }
    if (!(Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "ERROR: Git not installed" -ForegroundColor Red
        return $false
    }
    return $true
}

if (!(Test-Environment)) { exit 1 }

# Process choice
function Invoke-Choice($choice) {
    switch ($choice) {
        "1" { 
            Write-Host "`n[1] Edit code..." -ForegroundColor Cyan
            code .
        }
        "2" { 
            Write-Host "`n[2] Compile project..." -ForegroundColor Green
            if (Test-Path ".\compile.ps1") {
                .\compile.ps1
            } else {
                if (!(Test-Path "bin")) { New-Item -ItemType Directory -Path "bin" -Force }
                $javaFiles = Get-ChildItem -Path "src" -Filter "*.java" -Recurse
                if ($javaFiles) {
                    javac -d bin $javaFiles.FullName
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "SUCCESS: Compiled successfully!" -ForegroundColor Green
                    }
                } else {
                    Write-Host "ERROR: No Java files found" -ForegroundColor Red
                }
            }
        }
        "3" { 
            Write-Host "`n[3] Run program..." -ForegroundColor Magenta
            if (Test-Path ".\run.ps1") {
                .\run.ps1
            } else {
                $mainClass = "App"
                if (Test-Path "bin\$mainClass.class") {
                    java -cp bin $mainClass
                } else {
                    Write-Host "ERROR: Please compile first" -ForegroundColor Red
                }
            }
        }
        "4" { 
            Write-Host "`n[4] Git sync..." -ForegroundColor Blue
            if (Test-Path ".\sync.ps1") {
                .\sync.ps1
            } else {
                git status
                $doSync = Read-Host "Sync now? (y/n)"
                if ($doSync -eq 'y') {
                    git pull origin main
                    git add .
                    $msg = Read-Host "Commit message"
                    if ([string]::IsNullOrWhiteSpace($msg)) { $msg = "Update $(Get-Date -Format 'yyyy-MM-dd HH:mm')" }
                    git commit -m $msg
                    git push origin main
                }
            }
        }
        "5" { 
            Write-Host "`n[5] View status..." -ForegroundColor White
            Write-Host "=== Git Status ===" -ForegroundColor Cyan
            git status
            Write-Host "`n=== Java Info ===" -ForegroundColor Cyan
            java -version
            if (Test-Path "src") {
                $javaCount = (Get-ChildItem "src" -Filter "*.java" -Recurse).Count
                Write-Host "Java files: $javaCount" -ForegroundColor Gray
            }
            if (Test-Path "bin") {
                $classCount = (Get-ChildItem "bin" -Filter "*.class" -Recurse).Count
                Write-Host "Class files: $classCount" -ForegroundColor Gray
            }
        }
        "6" { 
            Write-Host "`n[6] Clean project..." -ForegroundColor DarkYellow
            $confirm = Read-Host "Delete all compiled files? (y/n)"
            if ($confirm -eq 'y') {
                if (Test-Path "bin") {
                    Remove-Item bin\* -Recurse -Force
                    Write-Host "SUCCESS: Cleaned compiled files" -ForegroundColor Green
                }
                if (Test-Path "target") {
                    Remove-Item target\* -Recurse -Force
                    Write-Host "SUCCESS: Cleaned Maven output" -ForegroundColor Green
                }
            }
        }
        "7" { 
            Write-Host "`n[7] Open GitHub..." -ForegroundColor DarkCyan
            $repoUrl = "https://github.com/henryborner/firstone"
            Write-Host "Repository: $repoUrl" -ForegroundColor Cyan
            Start-Process $repoUrl
        }
        "8" { 
            Write-Host "`n[8] Project management..." -ForegroundColor DarkGreen
            Write-Host "1. Create new Java class" -ForegroundColor Gray
            Write-Host "2. View project structure" -ForegroundColor Gray
            Write-Host "3. Export project" -ForegroundColor Gray
            $subChoice = Read-Host "Select sub-option (1-3)"
            switch ($subChoice) {
                "1" {
                    $className = Read-Host "Enter class name (e.g., MyClass)"
                    if (![string]::IsNullOrWhiteSpace($className)) {
                        $filePath = "src\$className.java"
                        if (!(Test-Path $filePath)) {
                            @"
public class $className {
    public static void main(String[] args) {
        System.out.println("Hello from $className!");
    }
}
"@ | Out-File $filePath -Encoding UTF8
                            Write-Host "SUCCESS: Created $className.java" -ForegroundColor Green
                        } else {
                            Write-Host "ERROR: File already exists" -ForegroundColor Red
                        }
                    }
                }
                "2" {
                    Write-Host "`nProject structure:" -ForegroundColor Cyan
                    Get-ChildItem -Recurse | ForEach-Object {
                        $indent = "  " * (($_.FullName.Split("\").Length - (Get-Location).Path.Split("\").Length) - 1)
                        if ($_.PSIsContainer) {
                            Write-Host "$indent[DIR] $($_.Name)/" -ForegroundColor DarkCyan
                        } else {
                            $color = switch ($_.Extension) {
                                ".java" { "Green" }
                                ".class" { "DarkGray" }
                                ".ps1" { "Blue" }
                                default { "Gray" }
                            }
                            Write-Host "$indent[FILE] $($_.Name)" -ForegroundColor $color
                        }
                    }
                }
                "3" {
                    $exportPath = Read-Host "Enter export path (e.g., E:\backups\firstone)"
                    if (![string]::IsNullOrWhiteSpace($exportPath)) {
                        Copy-Item . $exportPath -Recurse -Force
                        Write-Host "SUCCESS: Project exported to: $exportPath" -ForegroundColor Green
                    }
                }
            }
        }
        "0" { 
            Write-Host "`nGoodbye!" -ForegroundColor Cyan
            exit 0
        }
        default {
            Write-Host "ERROR: Invalid choice" -ForegroundColor Red
        }
    }
}

# Main menu
function Show-Menu {
    Write-Host "`nSelect operation:" -ForegroundColor Yellow
    Write-Host "1. 📝 Edit code" -ForegroundColor Cyan
    Write-Host "2. 🔨 Compile project" -ForegroundColor Green
    Write-Host "3. ▶️  Run program" -ForegroundColor Magenta
    Write-Host "4. 🔄 Git sync" -ForegroundColor Blue
    Write-Host "5. 📊 View status" -ForegroundColor White
    Write-Host "6. 🧹 Clean project" -ForegroundColor DarkYellow
    Write-Host "7. 🌐 Open GitHub" -ForegroundColor DarkCyan
    Write-Host "8. 🛠️  Project management" -ForegroundColor DarkGreen
    Write-Host "0. ❌ Exit" -ForegroundColor Red
    Write-Host ""
}

# Main loop
do {
    Show-Menu
    $choice = Read-Host "Enter choice (0-8)"
    Invoke-Choice $choice
    if ($choice -ne "0") {
        Read-Host "`nPress Enter to continue..."
    }
} while ($choice -ne "0")