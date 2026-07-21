param(
  [string]$Source = "Mowathfak Landing.html"
)

$ErrorActionPreference = "Stop"
$raw = [IO.File]::ReadAllText((Resolve-Path $Source), [Text.Encoding]::UTF8)

$manifestMatch = [regex]::Match($raw, '(?s)<script type="__bundler/manifest">\s*(.*?)\s*</script>')
$templateMatch = [regex]::Match($raw, '(?s)<script type="__bundler/template">\s*(.*?)\s*</script>')
if (-not $manifestMatch.Success -or -not $templateMatch.Success) {
  throw "The source bundle is missing its manifest or page template."
}

$manifest = $manifestMatch.Groups[1].Value | ConvertFrom-Json
$template = $templateMatch.Groups[1].Value | ConvertFrom-Json

foreach ($property in $manifest.PSObject.Properties) {
  $resource = $property.Value
  $bytes = [Convert]::FromBase64String($resource.data)
  if ($resource.compressed) {
    $input = [IO.MemoryStream]::new($bytes)
    $gzip = [IO.Compression.GZipStream]::new($input, [IO.Compression.CompressionMode]::Decompress)
    $output = [IO.MemoryStream]::new()
    $gzip.CopyTo($output)
    $bytes = $output.ToArray()
    $output.Dispose()
    $gzip.Dispose()
    $input.Dispose()
  }
  [IO.File]::WriteAllBytes((Join-Path "public" $property.Name), $bytes)
}

$styles = [regex]::Matches($template, '(?s)<style>(.*?)</style>') | ForEach-Object {
  [regex]::Replace($_.Groups[1].Value, 'url\("([0-9a-f-]{36})"\)', 'url("/$1")')
}
$baseStyles = @'
html { scroll-behavior: smooth; }
body { margin: 0; background: #0d101f; }
#root { min-height: 100vh; }
'@
[IO.File]::WriteAllText((Join-Path "src" "styles.css"), $baseStyles + "`n" + ($styles -join "`n"), [Text.UTF8Encoding]::new($false))

$xdc = [regex]::Match($template, '(?s)<x-dc>.*?</x-dc>').Value
$xdc = [regex]::Replace($xdc, '(?s)<style>.*?</style>', '')
$xdc = [regex]::Replace($xdc, '<script\s+src="(?:aa62f711-588e-44d2-8499-3c5c5181ed22|78c3f5aa-d2bd-4a2c-acb5-64265534d4c3)"></script>', '')
$xdc = [regex]::Replace($xdc, '(?s)<script type="application/ld\+json">.*?</script>', '')
$logicMatch = [regex]::Matches($template, '(?s)<script(?:\s+[^>]*)?>(.*?)</script>') |
  Where-Object { $_.Groups[1].Value -match 'class\s+Component\s+extends\s+DCLogic' } |
  Select-Object -Last 1
if (-not $logicMatch) {
  throw "The source page logic was not found."
}
$xdc += "`n" + $logicMatch.Value
$xdcJson = $xdc | ConvertTo-Json -Compress
$module = "const pageTemplate = $xdcJson`n`nexport default pageTemplate`n"
[IO.File]::WriteAllText((Join-Path "src" "pageTemplate.ts"), $module, [Text.UTF8Encoding]::new($false))

Write-Output "Extracted the original resources, template, styles, and interaction logic."
