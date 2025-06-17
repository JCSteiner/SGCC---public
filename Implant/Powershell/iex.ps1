# shell - runs a cmd.exe command for us, the way we can start arbitrary processes and get output
function func_iex
{
    param([string] $args)

    # runs the shell command and gets the results as a string
    $results = (($args | iex) | Out-String)
    $res2 = $results.ToString()

    return $res2
}