# Erstellt ein Backup von den wichtigsten Ordnern im System des jetzigen BENUTZERS

$BackupDrive = "G:"

# Benutzervariable richtig setzen
$USERPROFILE = $env:USERPROFILE

# USB angesteckt?
if(!(Test-Path -Path $BackupDrive))
{
	echo "Bitte Backup USB anstecken!"
	exit 2
}

# Nachsehen ob das Skript als Administrator ausgeführt wurde
$CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($CurrentUser)

if (-not $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Bitte PowerShell als Administrator starten!"
    exit 3
}

# _BACKUP Ordner erstellen, falls nicht vorhanden
if(!(Test-Path -Path "$BackupDrive\_BACKUP"))
{
	New-Item -Path "$BackupDrive\" -Name "_BACKUP" -ItemType "Directory"
}

# Benutzer Ordner erstellen, falls nicht vorhanden
if(!(Test-Path -Path "$BackupDrive\_BACKUP\$Env:UserName"))
{
	New-Item -Path "$BackupDrive\_BACKUP" -Name "$Env:UserName" -ItemType "Directory"
}

# Datum-Uhrzeit Ordner fürs Backup anlegen
$backupdate = Get-Date -Format "dd-MM-yyyy_HH-mm-ss"
New-Item -Path "$BackupDrive\_BACKUP\$Env:UserName" -Name "$backupdate" -ItemType "Directory"

# Userordner kopieren
$Source = "C:\Users\$env:USERNAME"
$Destination = "$BackupDrive\_BACKUP\$env:USERNAME\$backupdate"

# Diese Ordner werden nicht kopiert
$ExcludeDirs = @(
    "$Source\AppData\Local\Temp"
    "$Source\AppData\Local\Microsoft\Windows\INetCache"
    "$Source\AppData\Local\CrashDumps"
)

# Diese Dateien (+Endungen) werden nicht kopiert
$ExcludeFiles = @(
	"*.tmp"
	"*.log"
	"desktop.ini"
)

$LogFile = "$Destination\backup.log"

# Kopieren der Dateien: E: Alle Suborder, R:2 W:2 - 2 Versuche bei Fehlschlag der Kopierung mit 2 Sek. warten
# XJ: Abzweigungpunkte überspringen (Recursionprobleme), COPY:DAT - Daten, Attribute und Zeitstempel werden übernommen
# XD: Ausgenommene Order, XF: Ausgenommene Dateien, /LOG: wo die Log-Datei erstellt wird
# V, FP, TS, ETA, TEE: Alle Operationen in die PowerShell schreiben
robocopy $Source $Destination /E /R:2 /W:2 /XJ /XD $ExcludeDirs /XF $ExcludeFiles /COPY:DAT /LOG:$LogFile /V /FP /TS /ETA /TEE

# Exitcode von robocopy analysieren und sehen ob das Backup erfolgreich erstellt wurde.
if ($LASTEXITCODE -le 7) {
    Write-Host "Backup erfolgreich."
	exit 0
}
else {
    Write-Host "Backup Fehler! Robocopy Code: $LASTEXITCODE"
	exit 1
}