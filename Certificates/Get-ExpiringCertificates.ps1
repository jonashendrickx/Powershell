param (
	[string] $Days = "90"
)

$allCertificates = Get-ChildItem Cert:\ -Recurse | Where-Object {$_ -is [System.Security.Cryptography.X509Certificates.X509Certificate2]}
$expiringCertificates = $allCertificates | Where-Object {$_.NotAfter -gt (Get-Date) -and $_.NotAfter -lt (Get-Date).AddDays($Days)}