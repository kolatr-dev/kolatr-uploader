# Kolatr file uploader

This repository contains a script to upload files from a set of folders to defined S3 buckets.

## Requirements

1. Add AWS Powershell module if it's not already avaialable: run `Install-Module AWSPowerShell` as administrator.

2. Store some aws credentials:

``` 
  Set-AWSCredential `
      -AccessKey [access key here] `
      -SecretKey [access secret here] `
      -StoreAs kolatr
```

*NB: If you choose to use a different `StoreAs` name, you'll need to change the `awsCredentialsProfile` in config.json*

3. For each tenant, you will need a folder of files, and configuration details in config.json:
 a. Retailer "alias" (provided by Kolatr)
 b. A source folder that has files to upload

4. [Execution policy](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy?view=powershell-7.4) might need to be changed to run the script, or run it as Administrator.

## Usage

Add or modify any details in `config/config.json`. The format of this file should be self-explanatory.

Run the `upload.ps1` script at any time. Ideally on a schedule immediately after files are created in the source folder.

The script will upload files, then if the upload is successful it will move the completed files into the completed folder.

If additional files are added to the folder during the upload process, these files will not be uploaded until the next time the upload script is run.

