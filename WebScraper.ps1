#powershell
cls
$ProgressPreference = 'SilentlyContinue'

for( [int]$yyyy = 1999; $yyyy -le 1999; $yyyy++ ){
    for( [int]$m = 5; $m -le 12; $m++ ){
        [string]$mm = $m.tostring('00')
        write-host "Importing $yyyy-$mm"
        [string[]]$data  = @()
        for( [int]$d = 1; $d -le [datetime]::DaysInMonth($yyyy,$mm); $d++ ){
            [string]$dd = $d.tostring('00') 
            $URI = "https://www.nrc.gov/reading-rm/doc-collections/event-status/reactor-status/$yyyy/$yyyy$mm$dd`ps.html"
            
            write-host "$URI`r`nImporting" -NoNewline
            
            $NRC = $null
            [int]$counter = 0
            $bad = $false
            do {
                try  { $NRC = Invoke-WebRequest -Uri $URI -TimeoutSec 6 -ErrorAction SilentlyContinue }
                catch{ Write-Host '.' -NoNewline; $counter++; $bad =  $counter -gt 20 }
            }until( $NRC.StatusDescription -eq 'OK' -or $bad)
            if( $bad ){ 
                Add-Content -Value "Error importing $URI" -Path 'errors.log'
                Write-Host " Error!"
                continue

            }

            Write-Host " Done!`r`nProcessing" -NoNewline            

            $tables = @($NRC.ParsedHtml.getElementsByTagName('table'))
            for( [int]$ii = 1; $ii -le $tables.Count; $ii++ ){
                $table = $tables[$ii]

                foreach( $row in $table.rows ){
                    $cells = @($row.cells)
                    
                    [string]$value = $cells | ForEach-Object -Begin { [string]$temp = '' } -Process { $temp += ","+[string]($_.innertext) } -End { $temp.Substring(1) } 
                    
                    if( $cells[0].tagName -eq 'TH' ){
                        [string[]]$titles = "Date,$value"
                    }elseif( $cells[0].tagName -eq 'TD' ){
                        if( $value -match '(.*,\d+,)(\d+)\/(\d+)\/(\d{4})(,.*,[ \*],.*)' ){
                            $value = $Matches[1] + $Matches[4] + "-" + $Matches[2] + "-" + $Matches[3] + $Matches[5]
                        }
                        $data += "$yyyy-$mm-$dd,$value"
                    }
                }
                Write-Host '.' -NoNewline
            }
            write-host ' Done!' 
        }
        ($titles + $data) | Set-Content "$pwd\$yyyy-$mm.csv" -Encoding Ascii
    }
}



$ProgressPreference = 'Continue'