param(
    [string]$LogoPath = "$(Split-Path -Parent $PSScriptRoot)\flutter\assets\jcx_remote_logo.png"
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

if (-not (Test-Path -LiteralPath $LogoPath -PathType Leaf)) {
    throw "JCX remote support logo not found: $LogoPath"
}

$targets = @(
    (Join-Path $PSScriptRoot '..\res\icon.ico'),
    (Join-Path $PSScriptRoot '..\flutter\windows\runner\resources\app_icon.ico')
)
$sizes = @(16, 24, 32, 48, 64, 128, 256)
$source = [System.Drawing.Image]::FromFile((Resolve-Path -LiteralPath $LogoPath))

try {
    $frames = foreach ($size in $sizes) {
        $bitmap = [System.Drawing.Bitmap]::new(
            $size,
            $size,
            [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
        )
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.Clear([System.Drawing.Color]::Transparent)
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $graphics.DrawImage($source, 0, 0, $size, $size)
            $stream = [System.IO.MemoryStream]::new()
            $bitmap.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
            [pscustomobject]@{ Size = $size; Bytes = $stream.ToArray() }
            $stream.Dispose()
        }
        finally {
            $graphics.Dispose()
            $bitmap.Dispose()
        }
    }

    foreach ($target in $targets) {
        $fullTarget = [System.IO.Path]::GetFullPath($target)
        $directory = Split-Path -Parent $fullTarget
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
        $output = [System.IO.File]::Create($fullTarget)
        try {
            $writer = [System.IO.BinaryWriter]::new($output)
            $writer.Write([UInt16]0)
            $writer.Write([UInt16]1)
            $writer.Write([UInt16]$frames.Count)
            $offset = 6 + (16 * $frames.Count)
            foreach ($frame in $frames) {
                $dimension = if ($frame.Size -eq 256) { [byte]0 } else { [byte]$frame.Size }
                $writer.Write($dimension)
                $writer.Write($dimension)
                $writer.Write([byte]0)
                $writer.Write([byte]0)
                $writer.Write([UInt16]1)
                $writer.Write([UInt16]32)
                $writer.Write([UInt32]$frame.Bytes.Length)
                $writer.Write([UInt32]$offset)
                $offset += $frame.Bytes.Length
            }
            foreach ($frame in $frames) {
                $writer.Write($frame.Bytes)
            }
            $writer.Flush()
        }
        finally {
            if ($writer) { $writer.Dispose() }
            $output.Dispose()
        }
    }
}
finally {
    $source.Dispose()
}

Write-Output "Created JCX Windows icons: $($targets -join ', ')"
