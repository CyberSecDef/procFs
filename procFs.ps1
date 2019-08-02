#install-module SHiPS

#https://en.wikipedia.org/wiki/CPUID
#https://github.com/Wiffzack/Imtoolazy/blob/master/logscan.py
#http://pinvoke.net/default.aspx/kernel32/IsProcessorFeaturePresent.html
#https://www.leeholmes.com/blog/2009/01/19/powershell-pinvoke-walkthrough/


clear
import-module SHiPS
import-module .\procFs.psm1 -force
Remove-PSDrive -Name ProcFs
New-PSDrive -Name ProcFs -PSProvider SHiPS -Root "ProcFs#Root"

$cpuinfo = get-item ProcFs:\cpuInfo

$cpuinfo | fl
$cpuinfo.model_name
