$ErrorActionPreference = "Stop"

$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$psql = "C:\Program Files\PostgreSQL\18\bin\psql.exe"
$databaseName = "content_agency_db"
$postgresUser = "postgres"
$postgresPort = "5432"

if (-not (Test-Path $psql)) {
    throw "psql.exe was not found: $psql"
}

Write-Host "PostgreSQL setup for the content agency project"
Write-Host "Server: localhost:${postgresPort}, PostgreSQL 18"
Write-Host ""

$securePassword = Read-Host "Enter password for PostgreSQL user postgres" -AsSecureString
$passwordPtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)

try {
    $env:PGPASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPtr)

    Write-Host ""
    Write-Host "1/3 Checking connection..."
    & $psql -h localhost -p $postgresPort -U $postgresUser -d postgres -v ON_ERROR_STOP=1 -c "SELECT version();"

    Write-Host ""
    Write-Host "2/3 Creating database if needed..."
    $databaseExists = & $psql -h localhost -p $postgresPort -U $postgresUser -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '$databaseName';"
    if ($databaseExists -ne "1") {
        & $psql -h localhost -p $postgresPort -U $postgresUser -d postgres -v ON_ERROR_STOP=1 -c "CREATE DATABASE $databaseName ENCODING 'UTF8';"
    }
    else {
        Write-Host "Database $databaseName already exists. Tables will be recreated by 00_run_all.sql."
    }

    Write-Host ""
    Write-Host "3/3 Loading schema and seed data..."
    Push-Location $projectDir
    try {
        & $psql -h localhost -p $postgresPort -U $postgresUser -d $databaseName -v ON_ERROR_STOP=1 -f ".\00_run_all.sql"
    }
    finally {
        Pop-Location
    }

    Write-Host ""
    Write-Host "Done. Database $databaseName is ready."
    Write-Host "Open it in pgAdmin or DBeaver: host=localhost, port=${postgresPort}, database=$databaseName, user=$postgresUser."
}
finally {
    if ($passwordPtr -ne [IntPtr]::Zero) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPtr)
    }
    Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
}
