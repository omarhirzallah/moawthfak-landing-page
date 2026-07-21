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
.site-booting { overflow: hidden; }
.runtime-page { visibility: hidden; }
.runtime-page.is-ready { visibility: visible; }
.site-loader {
  position: fixed;
  inset: 0;
  z-index: 99999;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 16px;
  background: #0d101f;
  color: #b7bcce;
  font: 600 14px/1.5 'Manrope', system-ui, sans-serif;
  transition: opacity 180ms ease, visibility 180ms ease;
}
.site-loader img {
  width: 56px;
  height: 56px;
  border-radius: 14px;
  animation: loaderPulse 1.2s ease-in-out infinite;
}
.site-loader button {
  border: 0;
  border-radius: 999px;
  background: #6935d3;
  color: #fff;
  padding: 11px 18px;
  font: inherit;
  font-weight: 700;
  cursor: pointer;
}
.site-loader button:hover { background: #5425bd; }
.site-loader.is-hidden {
  opacity: 0;
  visibility: hidden;
  pointer-events: none;
}
@keyframes loaderPulse {
  0%, 100% { transform: scale(1); box-shadow: 0 0 0 rgba(114,58,213,0); }
  50% { transform: scale(1.06); box-shadow: 0 0 32px rgba(114,58,213,0.48); }
}
@media (prefers-reduced-motion: reduce) {
  .site-loader img { animation: none; }
}
'@
[IO.File]::WriteAllText((Join-Path "src" "styles.css"), $baseStyles + "`n" + ($styles -join "`n"), [Text.UTF8Encoding]::new($false))

$xdc = [regex]::Match($template, '(?s)<x-dc>.*?</x-dc>').Value
$xdc = [regex]::Replace($xdc, '(?s)<style>.*?</style>', '')
$xdc = [regex]::Replace($xdc, '<script\s+src="(?:aa62f711-588e-44d2-8499-3c5c5181ed22|78c3f5aa-d2bd-4a2c-acb5-64265534d4c3)"></script>', '')
$xdc = [regex]::Replace($xdc, '(?s)<script type="application/ld\+json">.*?</script>', '')
$xdc = [regex]::Replace($xdc, '(?s)<p[^>]*>[^<]*Placeholder prices.*?</p>', '')
$logicMatch = [regex]::Matches($template, '(?s)<script(?:\s+[^>]*)?>(.*?)</script>') |
  Where-Object { $_.Groups[1].Value -match 'class\s+Component\s+extends\s+DCLogic' } |
  Select-Object -Last 1
if (-not $logicMatch) {
  throw "The source page logic was not found."
}
$logic = $logicMatch.Value.Replace('jod: "100", usd: "41"', 'jod: "29", usd: "41"')
$logic = $logic.Replace("dur: '70s'", "dur: '30s'")
$logic = $logic.Replace("delay: '-14s'", "delay: '-6s'")
$logic = $logic.Replace("delay: '-28s'", "delay: '-12s'")
$logic = $logic.Replace("delay: '-42s'", "delay: '-18s'")
$logic = $logic.Replace("delay: '-56s'", "delay: '-24s'")
$xdc += "`n" + $logic
$xdcJson = $xdc | ConvertTo-Json -Compress
$module = "const pageTemplate = $xdcJson`n`nexport default pageTemplate`n"
[IO.File]::WriteAllText((Join-Path "src" "pageTemplate.ts"), $module, [Text.UTF8Encoding]::new($false))

Write-Output "Extracted the original resources, template, styles, and interaction logic."
