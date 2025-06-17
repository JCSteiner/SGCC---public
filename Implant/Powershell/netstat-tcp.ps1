# netstat-tcp - enumerates tcp connections and returns the output
function func_netstat-tcp 
{
   $results = Get-NetTCPConnection | Out-String
   return $results
}