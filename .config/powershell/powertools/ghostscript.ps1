function Merge-PDFs {
    param (
        [string]$FolderPath,     # Path to the folder containing PDF files
        [string]$OutputFile      # Path to the output PDF file
    )

    # Check if the folder exists
    if (-not (Test-Path $FolderPath)) {
        Write-Host "The specified folder does not exist." -ForegroundColor Red
        return
    }

    # Get all PDF files in the folder and sort them alphabetically
    $pdfFiles = Get-ChildItem -Path $FolderPath -Filter "*.pdf" | Sort-Object Name

    if ($pdfFiles.Count -eq 0) {
        Write-Host "No PDF files found in the specified folder." -ForegroundColor Yellow
        return
    }

    # Prepare an array of input PDF file paths
    $inputFiles = $pdfFiles | ForEach-Object { $_.FullName }

    # Check if Ghostscript is installed and accessible
    $ghostscriptPath = "gs"  # Assumes gs is in PATH. Adjust if Ghostscript isn't in PATH.
    $gsTest = Get-Command $ghostscriptPath -ErrorAction SilentlyContinue

    if (-not $gsTest) {
        Write-Host "Ghostscript is not installed or not in PATH." -ForegroundColor Red
        return
    }

    # Build the Ghostscript command
    $inputFilesString = $inputFiles -join " "
    $gsCommand = "-dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=`"$OutputFile`" $inputFilesString"

    try {
        # Run the Ghostscript command
        Start-Process $ghostscriptPath -ArgumentList $gsCommand -NoNewWindow -Wait
        Write-Host "PDF merge successful. Output file: $OutputFile" -ForegroundColor Green
    } catch {
        Write-Host "Error merging PDFs: $_" -ForegroundColor Red
    }
}

function Image-PDF {
    param (
        [string]$InputPath,                   # Path to the PDF file
        [string]$OutputFolder = $(Get-Location), # Default to current directory
        [string]$ImageFormat = "jpeg",          # Default image format is jpeg
        [int]$Resolution = 300                  # Default resolution is 300 DPI
    )

    # Check if the PDF file exists
    if (-not (Test-Path $InputPath)) {
        Write-Host "The specified PDF file does not exist." -ForegroundColor Red
        return
    }

    # Check if the output folder exists, if not, create it
    if (-not (Test-Path $OutputFolder)) {
        # Write-Host "Output folder does not exist. Creating it..." -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $OutputFolder
    }

    # Validate the image format
    if ($ImageFormat -ne "png" -and $ImageFormat -ne "jpeg") {
        Write-Host "Invalid image format specified. Supported formats are 'png' and 'jpeg'." -ForegroundColor Red
        return
    }

    # Check if Ghostscript is installed and accessible
    $ghostscriptPath = "gs"  # Assumes gs is in PATH. Adjust if Ghostscript isn't in PATH.
    $gsTest = Get-Command $ghostscriptPath -ErrorAction SilentlyContinue

    if (-not $gsTest) {
        Write-Host "Ghostscript is not installed or not in PATH." -ForegroundColor Red
        return
    }

    # Determine the Ghostscript device based on the image format
    $device = if ($ImageFormat -eq "png") { "pngalpha" } else { "jpeg" }

    # Build the Ghostscript output file pattern
    $outputPattern = Join-Path $OutputFolder ("$(Split-Path $InputPath -LeafBase)_page_%03d.$ImageFormat")


    # Build the Ghostscript command
    $gsCommand = "-dBATCH -dNOPAUSE -sDEVICE=$device -r$Resolution -sOutputFile=`"$outputPattern`" `"$InputPath`""

    try {
        # Run the Ghostscript command
        Start-Process $ghostscriptPath -ArgumentList $gsCommand -NoNewWindow -Wait
        Write-Host "PDF export successful. Images saved to: $OutputFolder" -ForegroundColor Green
    } catch {
        Write-Host "Error exporting PDF to images: $_" -ForegroundColor Red
    }
}

function Image-PDFs {
    param (
        [string]$FolderPath,     # Path to the folder containing the PDF files
        [string]$ImageFormat = "jpeg",  # Default image format is jpeg
        [int]$Resolution = 300   # Default resolution is 300 DPI
    )

    # Check if the folder exists
    if (-not (Test-Path $FolderPath)) {
        Write-Host "The specified folder does not exist." -ForegroundColor Red
        return
    }

    # Get all PDF files in the folder
    $pdfFiles = Get-ChildItem -Path $FolderPath -Filter "*.pdf"

    if ($pdfFiles.Count -eq 0) {
        Write-Host "No PDF files found in the specified folder." -ForegroundColor Yellow
        return
    }

    # Loop through each PDF file in the folder
    foreach ($pdf in $pdfFiles) {
        # Get the base name of the PDF (without extension) using Split-Path
        $pdfBaseName = $(Split-Path $pdf.FullName -LeafBase)
        $outputSubFolder = Join-Path $FolderPath $pdfBaseName

        # Check if the subfolder exists, if not, create it
        if (-not (Test-Path $outputSubFolder)) {
            Write-Host "Creating output folder for $pdfBaseName ..." -ForegroundColor Yellow
            New-Item -ItemType Directory -Path $outputSubFolder
        }

        Write-Host "Exporting images for $pdf..." -ForegroundColor Cyan

        # Call the previous singular Image-PDF function for each PDF
        Image-PDF -InputPath $pdf -OutputFolder $outputSubFolder -ImageFormat $ImageFormat -Resolution $Resolution
    }

    Write-Host "Export completed for all PDFs in $FolderPath." -ForegroundColor Green
}