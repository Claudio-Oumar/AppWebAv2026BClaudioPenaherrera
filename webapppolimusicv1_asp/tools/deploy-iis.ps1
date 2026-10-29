# =============================================================================
#  PoliMusic - Despliegue en IIS (ejecutar como Administrador)
#  - Habilita Classic ASP
#  - Copia la aplicacion a C:\inetpub\wwwroot
#  - Configura el App Pool y los permisos de escritura
# =============================================================================
#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
$src = 'D:\EPN\2026B\WebAvanzada\Lab02\webapppolimusicv1_asp'
$dst = 'C:\inetpub\wwwroot'
$log = Join-Path $src 'tools\deploy-log.txt'

function Log($msg) {
    $line = "[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss'), $msg
    Write-Host $line
    Add-Content -Path $log -Value $line -Encoding UTF8
}

Set-Content -Path $log -Value "PoliMusic deployment $(Get-Date)" -Encoding UTF8

try {
    # ---------------------------------------------------------------- 1. ASP
    Log 'Revisando caracteristica Classic ASP...'
    $asp = Get-WindowsOptionalFeature -Online -FeatureName IIS-ASP -ErrorAction SilentlyContinue
    if ($asp.State -ne 'Enabled') {
        Log 'Habilitando IIS-ASP (Classic ASP)...'
        $r = Enable-WindowsOptionalFeature -Online -FeatureName IIS-ASP -All -NoRestart
        Log ("IIS-ASP: " + $r.RestartNeeded)
    } else {
        Log 'IIS-ASP ya estaba habilitado.'
    }

    foreach ($f in @('IIS-ISAPIExtensions', 'IIS-ISAPIFilter')) {
        $feat = Get-WindowsOptionalFeature -Online -FeatureName $f -ErrorAction SilentlyContinue
        if ($feat -and $feat.State -ne 'Enabled') {
            Log "Habilitando $f ..."
            Enable-WindowsOptionalFeature -Online -FeatureName $f -All -NoRestart | Out-Null
        }
    }

    if (-not (Test-Path 'C:\Windows\System32\inetsrv\asp.dll')) {
        throw 'No se encontro asp.dll: Classic ASP no quedo instalado.'
    }
    Log 'asp.dll presente.'

    # -------------------------------------------------------------- 2. Copia
    Log "Copiando archivos a $dst ..."
    if (-not (Test-Path $dst)) { New-Item -ItemType Directory -Path $dst -Force | Out-Null }

    $robolog = & robocopy $src $dst /E /XD tools preview SongFilesAndImages_resources .workbuddy-ai /XF *.sql /NFL /NDL /NJH /NJS /NP /R:2 /W:1
    Log ("robocopy exit=" + $LASTEXITCODE)

    foreach ($old in @('iisstart.htm', 'iisstart.png')) {
        $p = Join-Path $dst $old
        if (Test-Path $p) { Remove-Item $p -Force; Log "Eliminado $old" }
    }

    # ---------------------------------------------------------- 3. App Pool
    Import-Module WebAdministration
    Log 'Configurando App Pool PoliMusicPool ...'
    if (-not (Test-Path 'IIS:\AppPools\PoliMusicPool')) {
        New-WebAppPool -Name 'PoliMusicPool' | Out-Null
    }
    Set-ItemProperty 'IIS:\AppPools\PoliMusicPool' -Name managedRuntimeVersion -Value ''
    Set-ItemProperty 'IIS:\AppPools\PoliMusicPool' -Name enable32BitAppOnWin64 -Value $false
    Set-ItemProperty 'IIS:\AppPools\PoliMusicPool' -Name startMode -Value 'AlwaysRunning'

    # -------------------------------------------------------------- 4. Sitio
    if (-not (Test-Path 'IIS:\Sites\Default Web Site')) {
        Log 'Creando Default Web Site ...'
        New-Website -Name 'Default Web Site' -PhysicalPath $dst -Port 80 -AppPool 'PoliMusicPool' | Out-Null
    } else {
        Set-ItemProperty 'IIS:\Sites\Default Web Site' -Name physicalPath -Value $dst
        Set-ItemProperty 'IIS:\Sites\Default Web Site' -Name applicationPool -Value 'PoliMusicPool'
        Log 'Default Web Site apunta a wwwroot con PoliMusicPool.'
    }

    # ------------------------------------------------------- 5. Permisos
    Log 'Otorgando permisos de escritura a IIS_IUSRS en carpetas de medios ...'
    foreach ($folder in @('songFiles', 'albumImages', 'ArtistImages', 'playlistImages', 'userImages')) {
        $path = Join-Path $dst $folder
        if (-not (Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
        $acl = Get-Acl $path
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            'IIS_IUSRS', 'Modify', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
        $acl.SetAccessRule($rule)
        Set-Acl -Path $path -AclObject $acl
        Log "  permisos -> $folder"
    }

    # ------------------------------------------------------- 6. MIME types
    Log 'Registrando tipos MIME adicionales ...'
    $existing = (Get-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' `
        -Filter 'system.webServer/staticContent' -Name '.' -ErrorAction SilentlyContinue |
        Where-Object { $_.fileExtension } )
    foreach ($m in @(
            @{ ext = '.webp'; mime = 'image/webp' },
            @{ ext = '.m4a';  mime = 'audio/mp4' },
            @{ ext = '.ogg';  mime = 'audio/ogg' })) {
        $has = $existing | Where-Object { $_.fileExtension -eq $m.ext }
        if (-not $has) {
            Add-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' `
                -Filter 'system.webServer/staticContent' -Name '.' `
                -Value @{ fileExtension = $m.ext; mimeType = $m.mime }
            Log ("  agregado " + $m.ext)
        } else {
            Log ("  ya existe " + $m.ext)
        }
    }

    # --------------------------------------------- 7. ISAPI restriction check
    try {
        $aspRestriction = Get-WebConfiguration -PSPath 'MACHINE/WEBROOT/APPHOST' `
            -Filter 'system.webServer/security/isapiCgiRestriction/add[@path="%windir%\system32\inetsrv\asp.dll"]'
        if ($aspRestriction) {
            if ($aspRestriction.allowed -ne $true) {
                Set-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' `
                    -Filter 'system.webServer/security/isapiCgiRestriction/add[@path="%windir%\system32\inetsrv\asp.dll"]' `
                    -Name allowed -Value $true
                Log 'ISAPI asp.dll habilitado.'
            } else {
                Log 'ISAPI asp.dll ya permitido.'
            }
        }
    } catch {
        Log ('Aviso ISAPI: ' + $_.Exception.Message)
    }

    # ----------------------------------------------------------- 8. Reinicio
    Log 'Reiniciando IIS ...'
    & iisreset /noforce | Out-Null
    Start-Sleep -Seconds 2

    $svc = Get-Service W3SVC
    Log ("W3SVC = " + $svc.Status)

    Log 'DESPLIEGUE COMPLETADO'
}
catch {
    Log ('ERROR: ' + $_.Exception.Message)
    exit 1
}
