# Load AWS PowerShell module
Import-Module AWSPowerShell

# Configuration file path
$configFilePath = "config\config.json"

# Load configuration
$config = Get-Content -Raw -Path $configFilePath | ConvertFrom-Json
$failedFolder = $config.failedFolder
$completedFolder = $config.completedFolder

# Function to upload files to S3
function Copy-FilesToS3 {
    param (
        [string]$tenantName,
        [string]$sourceFolder
    )

    $bucketName = "retailer-source-$tenantName"

    if($config.debug) {
        # enable S3 logging
        Add-AWSLoggingListener -Name "AWS Logs" -LogFilePath "/ps-logs.txt" # or any path
        Set-AWSResponseLogging Always
        Enable-AWSMetricsLogging -Namespace "MyNamespace" -DimensionName "MyDimension"
    }

    $tenantCompletedFolder = Join-Path -Path $completedFolder -ChildPath $tenantName
    $tenantFailedFolder = Join-Path -Path $failedFolder -ChildPath $tenantName

    # Check S3 bucket
    try {
        #Get-AWSCredential
        Write-Output "Testing S3 bucket $bucketName"
        Test-S3Bucket -BucketName $bucketName -ErrorAction Stop -ClientConfig $s3Config -Region "ap-southeast-2"
        Write-Output "Bucket $bucketName exists and you have permission to access it."
    }
    catch {
    
        Write-Error "Bucket $bucketName does not exist or you do not have permission to access it."
        return
    }

    # Get list of files to upload (only files, not directories)
    $files = Get-ChildItem -Path $sourceFolder -File

    if($files.Count -eq 0) {
        Write-Output "No files found in $sourceFolder"
        return
    }

    Write-Progress -Activity "Uploading files for tenant $tenantName" -Status "Starting" -PercentComplete 0

    # Generate a timestamp for the run
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"

    $completedCount = 0
    $failedCount = 0

    foreach ($file in $files) {
        try {
            # Upload file to S3 with timestamp folder
            $s3Key = "$timestamp\$($file.Name)"
            Write-Progress -Activity "Uploading files for tenant $tenantName" -Status "Uploading file: $s3Key" -PercentComplete (($files.IndexOf($file) / $files.Count) * 100)
            
            Write-S3Object -BucketName $bucketName -File $file.FullName -Key $s3Key -ErrorAction Stop -ContentType "text/csv" -Region "ap-southeast-2" -ClientConfig $s3Config
            #Write-S3Object -BucketName $bucketName -Folder .\samples\$tenantName  -KeyPrefix $s3Key -ErrorAction Stop -ContentType "text/csv" -Region "ap-southeast-2"

            # Ensure completed folder exists
            if (-not (Test-Path -Path $tenantCompletedFolder)) {
                New-Item -ItemType Directory -Path $tenantCompletedFolder
            }
            # Move file to completed folder
            Move-Item -Path $file.FullName -Destination $tenantCompletedFolder
            $completedCount++
        }
        catch {
            # Log the error
            $errorMessage = "Error uploading file $($file.FullName) for tenant $tenantName\\: $($_.Exception.Message)"
            Write-Error $errorMessage

            # Optionally, you can retry the operation or take other actions
            # For example, you can move the file to a "failed" folder for later review

            if (-not (Test-Path -Path $tenantFailedFolder)) {
                New-Item -ItemType Directory -Path $tenantFailedFolder
            }
            Move-Item -Path $file.FullName -Destination $tenantFailedFolder
            $failedCount++
        }
    }
    Write-Progress -Activity "Uploading files for tenant $tenantName" -Status "Completed" -PercentComplete 100
    Write-Output "Upload completed for tenant $tenantName"
    Write-Output "Processed $($files.Count) files. $completedCount files uploaded successfully, $failedCount files failed."
}

# Iterate through each tenant in the configuration
foreach ($tenant in $config.tenants) {
    Write-Output "Uploading files for tenant $($tenant.name)"
    Copy-FilesToS3 -tenantName $tenant.name `
                     -accessKey $tenant.accessKey `
                     -secretKey $tenant.secretKey `
                     -sourceFolder $tenant.sourceFolder `
                     -bucketName $tenant.bucketName
}
