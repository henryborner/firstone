# init-project.ps1 - Java Project Initialization
param(
    [string]$ProjectName = "my-java-project",
    [switch]$OpenVSCode
)

Write-Host "=== Java Project Initialization ===" -ForegroundColor Cyan

# Create project directory
if (Test-Path $ProjectName) {
    Write-Host "WARNING: Directory exists: $ProjectName" -ForegroundColor Yellow
    $overwrite = Read-Host "Overwrite? (y/n)"
    if ($overwrite -ne 'y') {
        exit 1
    }
    Remove-Item $ProjectName -Recurse -Force
}

New-Item -ItemType Directory -Path $ProjectName -Force | Out-Null
Set-Location $ProjectName

Write-Host "Created project directory: $ProjectName" -ForegroundColor Green

# Create standard directory structure
$directories = @("src", "bin", "lib", "docs")
foreach ($dir in $directories) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Write-Host "  [DIR] $dir/" -ForegroundColor Gray
}

# Create .gitignore
$gitignoreContent = @"
# Java compiled files
*.class
*.jar
*.war

# IDE files
.vscode/
!.vscode/settings.json
!.vscode/tasks.json
!.vscode/launch.json

.idea/
*.iml

# Build output
bin/
target/
out/
build/

# System files
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Sensitive files
.env
*.key
*.pem
"@

$gitignoreContent | Out-File .gitignore -Encoding UTF8
Write-Host "  [FILE] .gitignore" -ForegroundColor Gray

# Create README.md
$readmeContent = @"
# $ProjectName

A Java project

## Project Structure

\`\`\`
$ProjectName/
├── src/           # Source code
├── bin/           # Compiled output
├── lib/           # Dependencies
└── docs/          # Documentation
\`\`\`

## Usage
1. Compile: \`javac -d bin src/*.java\`
2. Run: \`java -cp bin Main\`

## Development Scripts
- \`.\compile.ps1\` - Compile project
- \`.\run.ps1\` - Run project
- \`.\sync.ps1\` - Git sync
- \`.\dev.ps1\` - Development assistant
"@

$readmeContent | Out-File README.md -Encoding UTF8
Write-Host "  [FILE] README.md" -ForegroundColor Gray

# Create example Java file
$javaCodeContent = @'
public class Main {
    public static void main(String[] args) {
        System.out.println(" Java project initialized successfully!");
        System.out.println("Project: " + (args.length > 0 ? args[0] : "Unnamed"));
        System.out.println("Java version: " + System.getProperty("java.version"));
        System.out.println("Time: " + java.time.LocalDateTime.now());
        
        // Example functionality
        if (args.length > 0) {
            System.out.println("\nArguments:");
            for (int i = 0; i < args.length; i++) {
                System.out.println("  [" + i + "] " + args[i]);
            }
        }
    }
}
'@

$javaCodeContent | Out-File "src\Main.java" -Encoding UTF8
Write-Host "  [FILE] src/Main.java" -ForegroundColor Green

# Initialize Git
git init
git add .
git commit -m "Initialized Java project: $ProjectName"

Write-Host "`nSUCCESS: Git repository initialized" -ForegroundColor Green

# Copy development scripts (if available)
$scripts = @("compile.ps1", "run.ps1", "sync.ps1", "dev.ps1")
foreach ($script in $scripts) {
    if (Test-Path "..\$script") {
        Copy-Item "..\$script" . -Force
        Write-Host "  [SCRIPT] $script (copied)" -ForegroundColor Cyan
    }
}

Write-Host "`n Project '$ProjectName' created successfully!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "  1. cd $ProjectName" -ForegroundColor Gray
Write-Host "  2. .\dev.ps1              # Start development assistant" -ForegroundColor Gray
Write-Host "  3. .\compile.ps1          # Compile project" -ForegroundColor Gray
Write-Host "  4. .\run.ps1              # Run project" -ForegroundColor Gray

if ($OpenVSCode) {
    Start-Process code .
    Write-Host "Opened VS Code" -ForegroundColor Cyan
}