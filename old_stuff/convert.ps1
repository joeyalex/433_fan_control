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