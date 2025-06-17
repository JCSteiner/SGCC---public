# get-pwd - performs a pwd command and returns the results
function func_pwd
{

    # returns the pwd results as a powershell string variable    
    $results = pwd | Out-String
    $res2 = $results.ToString()

    return $results
}