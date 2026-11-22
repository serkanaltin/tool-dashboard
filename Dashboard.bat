<# :
@echo off
cd /d "%~dp0"

:: CMD penceresini aninda kapatip PowerShell arayuzunu Yonetici olarak bagimsiz baslat
powershell -NoProfile -WindowStyle Hidden -Command "Start-Process powershell.exe -ArgumentList '-NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -Command \"Set-Location -LiteralPath ''%~dp0''; Invoke-Expression ([System.IO.File]::ReadAllText(''%~f0'', [System.Text.Encoding]::UTF8))\"' -Verb RunAs"
exit
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$BaseDir = (Get-Location).Path

# Indirilen dosyalarin SmartScreen / Zone.Identifier kilidini temizle
Get-ChildItem -Path $BaseDir -Recurse -File -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue

$Tools = @(
    [PSCustomObject]@{
        Id          = 1
        Key         = "1"
        Title       = "GenP v4.2.1"
        Category    = "UYGULAMA ARACI"
        Description = "Adobe Creative Cloud uygulamaları için yama ve yapılandırma aracı."
        RelPath     = "GenP-v4.2.1.exe"
        Fallbacks   = @("GenP*.exe")
        AccentHex   = "#3B82F6"
    },
    [PSCustomObject]@{
        Id          = 2
        Key         = "2"
        Title       = "MAS AIO (Activation Scripts)"
        Category    = "SİSTEM ARACI"
        Description = "Windows ve Office lisanslama / etkinleştirme yönetim konsolu."
        RelPath     = "MAS_AIO.cmd"
        Fallbacks   = @("Microsoft-Activation-Scripts-master\MAS\All-In-One-Version-KL\MAS_AIO.cmd", "Microsoft-Activation-Scripts-master\*\MAS_AIO.cmd", "MAS*.cmd", "MAS*.bat")
        AccentHex   = "#10B981"
    },
    [PSCustomObject]@{
        Id          = 3
        Key         = "3"
        Title       = "Windows Update Blocker"
        Category    = "GÜNCELLEME KONTROLÜ"
        Description = "Windows otomatik güncelleme servislerini tek tıkla açma ve kapatma aracı."
        RelPath     = "Wub.exe"
        Fallbacks   = @("Wub*.exe")
        AccentHex   = "#F59E0B"
    },
    [PSCustomObject]@{
        Id          = 4
        Key         = "4"
        Title       = "Defender Control & Ayarlar"
        Category    = "GÜVENLİK YÖNETİMİ"
        Description = "Windows Defender yönetim aracını veya tehdit koruma ayarlarını açar."
        RelPath     = "defender\dControl.exe"
        Fallbacks   = @("defender\dControl*.exe", "defender\*.exe", "defender\Defender_Settings.vbs", "defender\*.vbs")
        AccentHex   = "#8B5CF6"
    }
)

function Resolve-ToolPath {
    param($Tool)
    $direct = Join-Path $BaseDir $Tool.RelPath
    if (Test-Path $direct) { return $direct }
    foreach ($pattern in $Tool.Fallbacks) {
        $found = Get-ChildItem -Path (Join-Path $BaseDir $pattern) -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) { return $found.FullName }
    }
    return $null
}

# Renk Paleti (Modern Dark Slate)
$ColorBg         = [System.Drawing.ColorTranslator]::FromHtml("#0F172A")
$ColorSurface    = [System.Drawing.ColorTranslator]::FromHtml("#1E293B")
$ColorSurfaceHov = [System.Drawing.ColorTranslator]::FromHtml("#26354D")
$ColorBorder     = [System.Drawing.ColorTranslator]::FromHtml("#334155")
$ColorTextMain   = [System.Drawing.ColorTranslator]::FromHtml("#F8FAFC")
$ColorTextMuted  = [System.Drawing.ColorTranslator]::FromHtml("#94A3B8")
$ColorSuccess    = [System.Drawing.ColorTranslator]::FromHtml("#22C55E")
$ColorDanger     = [System.Drawing.ColorTranslator]::FromHtml("#EF4444")
$ColorStatusBg   = [System.Drawing.ColorTranslator]::FromHtml("#090D16")

# Ana Pencere
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Araç Yönetim Paneli"
$Form.Size = New-Object System.Drawing.Size(760, 560)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false
$Form.BackColor = $ColorBg
$Form.ForeColor = $ColorTextMain
$Form.KeyPreview = $true
$Form.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)

# Ust Baslik Alani
$HeaderPanel = New-Object System.Windows.Forms.Panel
$HeaderPanel.Location = New-Object System.Drawing.Point(28, 22)
$HeaderPanel.Size = New-Object System.Drawing.Size(688, 72)
$HeaderPanel.BackColor = $ColorBg
$Form.Controls.Add($HeaderPanel)

$TitleLabel = New-Object System.Windows.Forms.Label
$TitleLabel.Text = "Araç Yönetim Paneli"
$TitleLabel.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 18, [System.Drawing.FontStyle]::Bold)
$TitleLabel.ForeColor = $ColorTextMain
$TitleLabel.Location = New-Object System.Drawing.Point(0, 0)
$TitleLabel.AutoSize = $true
$HeaderPanel.Controls.Add($TitleLabel)

$AdminBadge = New-Object System.Windows.Forms.Label
$AdminBadge.Text = "● YÖNETİCİ YETKİSİ AKTİF"
$AdminBadge.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 8.5, [System.Drawing.FontStyle]::Bold)
$AdminBadge.ForeColor = $ColorSuccess
$AdminBadge.Location = New-Object System.Drawing.Point(255, 10)
$AdminBadge.AutoSize = $true
$HeaderPanel.Controls.Add($AdminBadge)

$SubTitleLabel = New-Object System.Windows.Forms.Label
$SubTitleLabel.Text = "Çalıştırmak istediğiniz aracın kartındaki 'Başlat' butonuna tıklayın veya klavyeden [1 - 4] tuşlarına basın."
$SubTitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$SubTitleLabel.ForeColor = $ColorTextMuted
$SubTitleLabel.Location = New-Object System.Drawing.Point(2, 42)
$SubTitleLabel.AutoSize = $true
$HeaderPanel.Controls.Add($SubTitleLabel)

# Alt Durum ve Kontrol Cubugu
$FooterPanel = New-Object System.Windows.Forms.Panel
$FooterPanel.Dock = "Bottom"
$FooterPanel.Height = 58
$FooterPanel.BackColor = $ColorStatusBg
$Form.Controls.Add($FooterPanel)

$StatusLabel = New-Object System.Windows.Forms.Label
$StatusLabel.Text = "Hazır — Klasör: $BaseDir"
$StatusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$StatusLabel.ForeColor = $ColorTextMuted
$StatusLabel.Location = New-Object System.Drawing.Point(28, 19)
$StatusLabel.Size = New-Object System.Drawing.Size(440, 22)
$FooterPanel.Controls.Add($StatusLabel)

$BtnRefresh = New-Object System.Windows.Forms.Button
$BtnRefresh.Text = "↻ Durumu Yenile"
$BtnRefresh.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
$BtnRefresh.Size = New-Object System.Drawing.Size(120, 34)
$BtnRefresh.Location = New-Object System.Drawing.Point(476, 12)
$BtnRefresh.FlatStyle = "Flat"
$BtnRefresh.BackColor = $ColorSurface
$BtnRefresh.ForeColor = $ColorTextMain
$BtnRefresh.FlatAppearance.BorderColor = $ColorBorder
$BtnRefresh.Cursor = [System.Windows.Forms.Cursors]::Hand
$FooterPanel.Controls.Add($BtnRefresh)

$BtnOpenFolder = New-Object System.Windows.Forms.Button
$BtnOpenFolder.Text = "📁 Klasörü Aç"
$BtnOpenFolder.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
$BtnOpenFolder.Size = New-Object System.Drawing.Size(110, 34)
$BtnOpenFolder.Location = New-Object System.Drawing.Point(606, 12)
$BtnOpenFolder.FlatStyle = "Flat"
$BtnOpenFolder.BackColor = $ColorSurface
$BtnOpenFolder.ForeColor = $ColorTextMain
$BtnOpenFolder.FlatAppearance.BorderColor = $ColorBorder
$BtnOpenFolder.Cursor = [System.Windows.Forms.Cursors]::Hand
$BtnOpenFolder.Add_Click({
    Start-Process "explorer.exe" -ArgumentList "`"$BaseDir`""
    $StatusLabel.Text = "✔ Klasör Dosya Gezgini'nde açıldı."
    $StatusLabel.ForeColor = $ColorTextMain
})
$FooterPanel.Controls.Add($BtnOpenFolder)

# Araci Baslatma Fonksiyonu
$LaunchTool = {
    param($Tool)
    $targetPath = Resolve-ToolPath $Tool

    if (-not $targetPath) {
        $StatusLabel.Text = "✖ '$($Tool.RelPath)' bulunamadı! Dosyayı kontrol edin."
        $StatusLabel.ForeColor = $ColorDanger
        [System.Windows.Forms.MessageBox]::Show(
            "'$($Tool.RelPath)' dosyası klasörde bulunamadı.`n`nEğer Windows Defender tarafından karantinaya alındıysa geri yükleyip 'Durumu Yenile' butonuna basın.",
            "Dosya Bulunamadı",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    $workDir = Split-Path $targetPath -Parent
    $ext = [System.IO.Path]::GetExtension($targetPath).ToLower()

    try {
        Unblock-File -Path $targetPath -ErrorAction SilentlyContinue
        $StatusLabel.Text = "⏳ '$($Tool.Title)' başlatılıyor..."
        $StatusLabel.ForeColor = $ColorTextMain
        $Form.Refresh()

        if ($ext -eq ".vbs") {
            Start-Process "wscript.exe" -ArgumentList "`"$targetPath`"" -WorkingDirectory $workDir
        } elseif ($ext -in ".cmd", ".bat") {
            # GitHub'dan indirildiginde olusabilecek LF (Unix) satir sonu sorununu otomatik CRLF'e onar
            $rawBytes = [System.IO.File]::ReadAllBytes($targetPath)
            if (($rawBytes -contains 10) -and -not ($rawBytes -contains 13)) {
                $contentStr = [System.IO.File]::ReadAllText($targetPath, [System.Text.Encoding]::UTF8)
                $fixedStr = $contentStr -replace "`r?`n", "`r`n"
                [System.IO.File]::WriteAllText($targetPath, $fixedStr, (New-Object System.Text.UTF8Encoding($false)))
            }
            Start-Process "cmd.exe" -ArgumentList "/c `"`"$targetPath`"`"" -WorkingDirectory $workDir
        } else {
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = $targetPath
            $psi.WorkingDirectory = $workDir
            $psi.UseShellExecute = $true
            [void][System.Diagnostics.Process]::Start($psi)
        }

        $StatusLabel.Text = "✔ '$($Tool.Title)' başarıyla başlatıldı."
        $StatusLabel.ForeColor = $ColorSuccess
    } catch {
        $StatusLabel.Text = "✖ '$($Tool.Title)' başlatılamadı: $($_.Exception.Message)"
        $StatusLabel.ForeColor = $ColorDanger
        [System.Windows.Forms.MessageBox]::Show(
            "'$($Tool.Title)' çalıştırılırken bir hata oluştu:`n`n$($_.Exception.Message)",
            "Çalıştırma Hatası",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
}

# 2x2 Kart Izgarasi Olusturma
$CardReferences = @()
$StartX = 28
$StartY = 108
$CardWidth = 334
$CardHeight = 162
$GapX = 20
$GapY = 18

for ($i = 0; $i -lt $Tools.Count; $i++) {
    $t = $Tools[$i]
    $col = $i % 2
    $row = [math]::Floor($i / 2)
    $posX = $StartX + ($col * ($CardWidth + $GapX))
    $posY = $StartY + ($row * ($CardHeight + $GapY))
    $accentColor = [System.Drawing.ColorTranslator]::FromHtml($t.AccentHex)

    $Card = New-Object System.Windows.Forms.Panel
    $Card.Location = New-Object System.Drawing.Point($posX, $posY)
    $Card.Size = New-Object System.Drawing.Size($CardWidth, $CardHeight)
    $Card.BackColor = $ColorSurface
    $Form.Controls.Add($Card)

    # Sol Renk Seridi
    $AccentBar = New-Object System.Windows.Forms.Panel
    $AccentBar.Location = New-Object System.Drawing.Point(0, 0)
    $AccentBar.Size = New-Object System.Drawing.Size(5, $CardHeight)
    $AccentBar.BackColor = $accentColor
    $Card.Controls.Add($AccentBar)

    # Kategori Etiketi
    $CatLabel = New-Object System.Windows.Forms.Label
    $CatLabel.Text = "[$($t.Key)] $($t.Category)"
    $CatLabel.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 8, [System.Drawing.FontStyle]::Bold)
    $CatLabel.ForeColor = $accentColor
    $CatLabel.Location = New-Object System.Drawing.Point(20, 14)
    $CatLabel.AutoSize = $true
    $Card.Controls.Add($CatLabel)

    # Dosya Durum Rozeti
    $FileStatusBadge = New-Object System.Windows.Forms.Label
    $FileStatusBadge.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 8)
    $FileStatusBadge.Location = New-Object System.Drawing.Point(215, 14)
    $FileStatusBadge.Size = New-Object System.Drawing.Size(105, 18)
    $FileStatusBadge.TextAlign = "TopRight"
    $Card.Controls.Add($FileStatusBadge)

    # Arac Adi
    $ToolTitle = New-Object System.Windows.Forms.Label
    $ToolTitle.Text = $t.Title
    $ToolTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 12.5, [System.Drawing.FontStyle]::Bold)
    $ToolTitle.ForeColor = $ColorTextMain
    $ToolTitle.Location = New-Object System.Drawing.Point(18, 34)
    $ToolTitle.Size = New-Object System.Drawing.Size(298, 25)
    $Card.Controls.Add($ToolTitle)

    # Aciklama
    $ToolDesc = New-Object System.Windows.Forms.Label
    $ToolDesc.Text = $t.Description
    $ToolDesc.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $ToolDesc.ForeColor = $ColorTextMuted
    $ToolDesc.Location = New-Object System.Drawing.Point(19, 62)
    $ToolDesc.Size = New-Object System.Drawing.Size(296, 42)
    $Card.Controls.Add($ToolDesc)

    # Baslat Butonu
    $BtnLaunch = New-Object System.Windows.Forms.Button
    $BtnLaunch.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9.5, [System.Drawing.FontStyle]::Bold)
    $BtnLaunch.Location = New-Object System.Drawing.Point(20, 112)
    $BtnLaunch.Size = New-Object System.Drawing.Size(296, 36)
    $BtnLaunch.FlatStyle = "Flat"
    $BtnLaunch.FlatAppearance.BorderSize = 1
    $BtnLaunch.Cursor = [System.Windows.Forms.Cursors]::Hand
    $BtnLaunch.Tag = $t
    $BtnLaunch.Add_Click({
        param($sender, $e)
        & $LaunchTool $sender.Tag
    })
    $Card.Controls.Add($BtnLaunch)

    $CardReferences += [PSCustomObject]@{
        Tool        = $t
        Card        = $Card
        StatusBadge = $FileStatusBadge
        Button      = $BtnLaunch
        Accent      = $accentColor
    }
}

# Kartlarin Dosya Durumunu Guncelleme Fonksiyonu
$UpdateCardStates = {
    foreach ($ref in $CardReferences) {
        $resolved = Resolve-ToolPath $ref.Tool
        if ($null -ne $resolved) {
            $leaf = Split-Path $resolved -Leaf
            $ref.StatusBadge.Text = "● Hazır"
            $ref.StatusBadge.ForeColor = $ColorSuccess
            $ref.Button.Text = "▶  Başlat ($leaf)"
            $ref.Button.BackColor = $ref.Accent
            $ref.Button.ForeColor = [System.Drawing.Color]::White
            $ref.Button.FlatAppearance.BorderColor = $ref.Accent
        } else {
            $ref.StatusBadge.Text = "✖ Dosya Eksik"
            $ref.StatusBadge.ForeColor = $ColorDanger
            $ref.Button.Text = "⚠  $($ref.Tool.RelPath) Bulunamadı"
            $ref.Button.BackColor = $ColorSurfaceHov
            $ref.Button.ForeColor = $ColorTextMuted
            $ref.Button.FlatAppearance.BorderColor = $ColorBorder
        }
    }
}

$BtnRefresh.Add_Click({
    & $UpdateCardStates
    $StatusLabel.Text = "✔ Dosya durumları güncellendi."
    $StatusLabel.ForeColor = $ColorSuccess
})

# Klavye Kisayollari (1-4 arasi tuslar, F5 yenile, Esc cikis)
$Form.Add_KeyDown({
    param($sender, $e)
    switch ($e.KeyCode) {
        { $_ -in "D1", "NumPad1" } { & $LaunchTool $Tools[0] }
        { $_ -in "D2", "NumPad2" } { & $LaunchTool $Tools[1] }
        { $_ -in "D3", "NumPad3" } { & $LaunchTool $Tools[2] }
        { $_ -in "D4", "NumPad4" } { & $LaunchTool $Tools[3] }
        "F5" {
            & $UpdateCardStates
            $StatusLabel.Text = "✔ Dosya durumları güncellendi."
            $StatusLabel.ForeColor = $ColorSuccess
        }
        "Escape" { $Form.Close() }
    }
})

& $UpdateCardStates
[void]$Form.ShowDialog()
