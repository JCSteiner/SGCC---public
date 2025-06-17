# ipconfig-all - the results of the ipconfig /all command
function func_ipconfig 
{
    $results = ipconfig /all | Out-String
    return $results

}