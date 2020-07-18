function Get-TrackerLatest {
    param (
        [string] $trackerRepo
    )
    
    Push-Location $trackerRepo

    Write-Host "Getting latest from GitHub"
    sudo git pull

    Pop-Location
}

function Write-BlockList {
    param (
        [string] $trackerRepo,
        [string] $blockListRepo,
        [string] $file
    )

    $blockFile = Join-Path -Path $blockListRepo -ChildPath $file

    Push-Location $trackerRepo    

    if (Test-Path ".\domains") {
        Write-Host "Creating block list"
        Set-Content $blockFile $null
        
        (Get-ChildItem '.\domains') | ForEach-Object {
            $domainCount++
            
            (Get-Content -Raw -Path $_) | ConvertFrom-Json | ForEach-Object {
                if ($null -ne $_.domain) {
                    $domain = $_.domain
                    $_.subdomains | ForEach-Object {
                        $subdomainCount++
                        Add-Content -Path $blockFile -Value 127.0.0.0`t$_.$domain
                    }                    
                }                
            }
        }       

        Get-Content $blockFile | Sort-Object | Set-Content $blockFile

        Write-Host "Added $subdomainCount subdomains from $domainCount domains"
    }     

    Pop-Location
}

function Push-BlockList {
    param (
        [string] $blockListRepo
    )

    Push-Location $blockListRepo

    $isChanged = $(git status --porcelain | Measure-Object | Select-Object -ExpandProperty Count) -gt 0

    if($isChanged) {
        Write-Host "Adding file"
        git add -A
        Write-Host "Commiting change"
        git commit -m "Auto-updating blocklist $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")"
        Write-Host "Pushing change"
        git push
    }
    else {
        Write-Host "No changes detected, skipping."
    }

    Pop-Location
}

Clear-Host

Write-Host "DuckDuckGo tracker pi-hole blocklist generator"

Get-TrackerLatest -trackerRepo '../tracker-radar'
Write-BlockList -trackerRepo '../tracker-radar' -blockListRepo (Resolve-Path '.') -file 'block-list.txt'
Push-BlockList 'duckduckgo-tracker-radar-blocklist'