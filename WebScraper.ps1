#powershell


for( [int]$yyyy = 2013; $yyyy -le 2013; $yyyy++ ){
    
    $leapyear = ($yyyy%4 -eq 0) -and -not ($yyyy%400 -eq 0)

    for( [int]$mm = 1; $mm -le 12; $mm++ ){

        [string[]]$data  = @()
        for( [int]$dd = 1; $dd -le [datetime]::DaysInMonth($yyyy,$mm); $dd++ ){
            [string]$datefmt1 = $yyyy.ToString('0000' ) + $mm.ToString('00' ) + $dd.ToString('00')
            [string]$datefmt2 = $yyyy.ToString('0000-') + $mm.ToString('00-') + $dd.ToString('00')

            $URI = "https://www.nrc.gov/reading-rm/doc-collections/event-status/reactor-status/$yyyy/$datefmt1`ps.html"
            $HTML = Invoke-WebRequest -Uri $URI
                        
            $tables = @($HTML.ParsedHtml.getElementsByTagName('table'))
            for( [int]$ii = 1; $ii -le 1; $ii++ ){
                $table = $tables[$ii]

                foreach( $row in $table.rows ){
                    $cells = @($row.cells)

                    Measure-Command {
                    [string]$value = $cells | % { [string]$_.innertext } # ForEach-Object -Begin { [string]$temp = '' } -Process { $temp += ","+[string]($_.innertext) } -End { $temp.Substring(1) } 
                    } | Select-Object -ExpandProperty totalseconds
        
                    if( $cells[0].tagName -eq 'TH' ){
                        [string[]]$titles = "Date,$value"
                    }elseif( $cells[0].tagName -eq 'TD' ){
                        $data += "$datefmt2,$value"
                    }

    
                }
            }
        }
        [string[]]$CSV = $titles
        $CSV += $data

        $csv | Set-Content "$pwd\$datefmt2.csv" -Encoding Ascii
    }
}


