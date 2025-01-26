# beállítások

## ide írd be a site url-jét, hasonló formában
$siteUrl = "https://domain-my.sharepoint.com/personal/username_domain_hu"
## ide írd be a siteon belüli elérési utat
$skipDirRef = '/personal/username_domain_hu/Documents/'
## ide írd hova tegye a fájlokat
$destinationPath = "C:\folder\path\somewhere\"

# Import SharePointPnPPowerShellOnline module
if (-not (Get-Module SharePointPnPPowerShellOnline -ListAvailable)) {
    Write-Host "Module error"
    Exit
}
Import-Module SharePointPnPPowerShellOnline -Force

## use web login (safer than plaintext password)
Connect-PnPOnline -Url $siteUrl -UseWebLogin

# Download folder
$folderItems = Get-PnPListItem -List "Documents" -PageSize 500

$totalItems = $folderItems.Count
$completedItems = 0

$szar = [System.Collections.ArrayList]@()

try{
    foreach ($item in $folderItems) {
        ## ha mappa
        $fileUrl = $item.FieldValues.FileRef
        $fileName = $item.FieldValues.FileLeafRef

        $lmappa = $fileUrl -split $skipDirRef
        $lmappa = $lmappa[-1].Replace('/','\')
        $strukt = $destinationPath+'\'+$lmappa

        if($null -ne $item.FieldValues.File_x0020_Type){
            ## ha fájl
            $fPath = $strukt.Replace('\'+$fileName,'')
            if (!(Test-Path $fPath)) {
                $p = New-Item -ItemType Directory -Path $fPath
            }
            try{
                Get-PnpFile -Url $fileUrl -Path $fPath -AsFile -ErrorAction Stop
            }catch{
                $szar.Add(@($fileUrl,$_))
                Write-Host "  > $($_)" -BackgroundColor Red
            }
        }
        
        Write-Host "OK: $($fileName)"
        $completedItems++
        $i = [math]::Round(($completedItems / $totalItems) * 100)
        Write-Progress -Activity "Downloading items..." -Status "$i% complete" -PercentComplete $i
    }
}
catch {
    Write-Host "Error happened"
}

Disconnect-PnPOnline

Write-Host $szar
