# get-dir - performs an ls and returns the results
function func_dir
{
    param([string] $directory) # the directory or file we are enumerating

    # converts the output of "ls" to a string and returns it
    $results = ls $directory | Out-String
    $res2 = $results.ToString()

    return $res2
    
}