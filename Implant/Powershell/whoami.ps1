# whoami-all - the results of the whoami /all command
function func_whoami 
{
    $results = whoami /all | Out-String
    return $results
}