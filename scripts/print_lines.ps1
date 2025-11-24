$path='d:\Project\spendly\lib\screens\summary_tab.dart'
$lines=Get-Content $path
for($i=1788;$i -le 1810;$i++){
  if($i -lt $lines.Length) { Write-Output ('{0,5}: {1}' -f ($i+1), $lines[$i]) }
}