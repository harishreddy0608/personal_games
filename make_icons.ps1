# Generates PWA PNG icons using .NET System.Drawing (built into Windows).
# Draws a coiled snake on a Game Boy green rounded tile.
Add-Type -AssemblyName System.Drawing

function New-Icon {
    param(
        [int]$Size,
        [string]$Path,
        [double]$Pad = 0.0   # fraction of size reserved as safe padding (for maskable)
    )

    $bmp = New-Object System.Drawing.Bitmap($Size, $Size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

    # Colors
    $bgOuter = [System.Drawing.ColorTranslator]::FromHtml("#9bbc0f")
    $bgInner = [System.Drawing.ColorTranslator]::FromHtml("#8bac0f")
    $snake   = [System.Drawing.ColorTranslator]::FromHtml("#0f380f")
    $head    = [System.Drawing.ColorTranslator]::FromHtml("#1b4d1b")
    $eye     = [System.Drawing.ColorTranslator]::FromHtml("#f4f7d0")

    # Fill background
    $g.Clear($bgOuter)

    $s = $Size
    $pad = [int]($s * $Pad)
    $inner = $s - 2 * $pad

    # Inner rounded panel
    $panelMargin = [int]($inner * 0.08) + $pad
    $panelRect = New-Object System.Drawing.Rectangle($panelMargin, $panelMargin, ($s - 2*$panelMargin), ($s - 2*$panelMargin))
    $brushInner = New-Object System.Drawing.SolidBrush($bgInner)
    $g.FillRectangle($brushInner, $panelRect)

    # Scale: design is in a 512 space, map into the drawable area.
    $scale = $inner / 512.0
    $ox = $pad
    $oy = $pad
    # Build a single-precision PointF from design coords.
    $mk = {
        param($x, $y)
        New-Object System.Drawing.PointF([single]($ox + $x * $scale), [single]($oy + $y * $scale))
    }

    # Snake body as a bezier path matching the SVG curve.
    $penW = [single](56 * $scale)
    $pen = New-Object System.Drawing.Pen($snake, $penW)
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round

    # Draw the body as connected cubic beziers (10 points = 3 segments).
    # DrawBeziers avoids GraphicsPath, which is unreliable to construct in WinPS 5.1.
    $pts = @(
        (& $mk 150 360), (& $mk 150 250), (& $mk 203 250), (& $mk 256 250),
        (& $mk 309 250), (& $mk 362 210), (& $mk 362 170),
        (& $mk 362 140), (& $mk 326 110), (& $mk 290 110)
    )
    $ptArr = [System.Drawing.PointF[]]$pts
    $g.DrawBeziers($pen, $ptArr)

    $brushHead = New-Object System.Drawing.SolidBrush($head)
    $brushEye = New-Object System.Drawing.SolidBrush($eye)
    $brushPupil = New-Object System.Drawing.SolidBrush($snake)

    # Head
    $headR = [single](40 * $scale); $hp = & $mk 290 110
    $g.FillEllipse($brushHead, [single]($hp.X - $headR), [single]($hp.Y - $headR), [single](2*$headR), [single](2*$headR))

    # Eye + pupil
    $eyeR = [single](9 * $scale); $ep = & $mk 300 96
    $g.FillEllipse($brushEye, [single]($ep.X - $eyeR), [single]($ep.Y - $eyeR), [single](2*$eyeR), [single](2*$eyeR))
    $pupilR = [single](4 * $scale); $pp = & $mk 302 96
    $g.FillEllipse($brushPupil, [single]($pp.X - $pupilR), [single]($pp.Y - $pupilR), [single](2*$pupilR), [single](2*$pupilR))

    # Tail tip
    $tailR = [single](28 * $scale); $tp = & $mk 150 360
    $g.FillEllipse($brushHead, [single]($tp.X - $tailR), [single]($tp.Y - $tailR), [single](2*$tailR), [single](2*$tailR))

    $g.Dispose()
    $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "wrote $Path ($Size x $Size)"
}

$dir = $PSScriptRoot
New-Icon -Size 192 -Path (Join-Path $dir "icon-192.png")
New-Icon -Size 512 -Path (Join-Path $dir "icon-512.png")
New-Icon -Size 512 -Path (Join-Path $dir "icon-maskable.png") -Pad 0.14
