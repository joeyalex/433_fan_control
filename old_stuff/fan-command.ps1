param (
    [string] $command,
    [string] $remoteID = "00001101011011002"
)

function Convert-Code {
    param (
    [string] $codeblock,
    [string] $shortLen = 290,
    [string] $longLen = 860,
    [string] $resetLen = 4375
)
$output = "";
$codeblock.ToCharArray() | foreach {
    if ($_ -eq "0") {
        $output += "$longLen $shortLen ";
    } elseif ($_ -eq "1") {
        $output += "$shortLen $longLen ";
    } elseif ($_ -eq "2") {
        $output += "$shortLen $resetLen";
    }
}
$output;
}

$code = "";
switch ($command) {
    "power" {$code = "1110111011101110"; break;}
    "1hr" {$code = "1111001111110011"; break;}
    "4hr" {$code = "1111010111110101"; break;}
    "8hr" {$code = "1111001011110010"; break;}
    "thermo" {$code = "1111000111110001"; break;}
    "wind" {$code = "1111000011110000"; break;}
    "1" {$code = "1111110111111101"; break;}
    "2" {$code = "1111110011111100"; break;}
    "3" {$code = "1111101111111011"; break;}
    "4" {$code = "1111101011111010"; break;}
    "5" {$code = "1111100111111001"; break;}
    "6" {$code = "1111100011111000"; break;}
    "reverse" {$code = "1111011011110110"; break;}
    "light_on" {$code = "1111111111111111"; break;}
    "light_off" {$code = "1111111011111110"; break;}
}
$rawCode = Convert-Code -codeblock "$code$remoteID";
write-host "pilight-send -p raw -c ""$rawCode"" -S 127.0.0.1 -P 5000";