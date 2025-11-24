$path='d:\Project\spendly\lib\screens\summary_tab.dart'
$lines=Get-Content $path
for($i=270;$i -le 300;$i++){
  if($i -lt $lines.Length) { Write-Output ('{0,4}: {1}' -f ($i+1), $lines[$i]) }
}