# Define the folder where the files will be created
$folderPath = "samples"
$tenantName = "active-luna"
$folderPath = Join-Path -Path $folderPath -ChildPath $tenantName

# Ensure the folder exists
if (-not (Test-Path -Path $folderPath)) {
    New-Item -ItemType Directory -Path $folderPath
}

# Define file sizes in bytes (10KB to 1MB)
$fileSizes = @(10240, 20480, 51200, 104857, 1048576)

# Function to generate Lorem Ipsum text
function Get-LoremIpsum {
    param (
        [int]$sizeInBytes
    )

    $loremIpsum = @"
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
"@

    $loremIpsum += "`nTenant Name: $tenantName"

    $text = ""
    while ($text.Length -lt $sizeInBytes) {
        $text += $loremIpsum
    }

    return $text.Substring(0, $sizeInBytes)
}

# Create 5 files with varying sizes
for ($i = 1; $i -le 5; $i++) {
    $fileName = "fakefile$i.txt"
    $filePath = Join-Path -Path $folderPath -ChildPath $fileName
    $fileSize = $fileSizes[$i - 1]

    # Generate Lorem Ipsum text of the specified size
    $fileContent = Get-LoremIpsum -sizeInBytes $fileSize

    # Write the content to the file
    Set-Content -Path $filePath -Value $fileContent
}

Write-Output "5 fake files created in $folderPath"
