$script:itertimes = 10240

function encrypt {
    param (
        [string] $plaintxt,
        [alias("f")]
        [switch] $isfilepath
    )

    if ($isfilepath) {
        $plaintxt = Get-Content $plaintxt -Raw -Encoding utf8
    }

    $passwd = Read-Host -Prompt "enter key" -MaskInput
    if ([string]::IsNullOrEmpty($passwd)) {
        Write-Host "key is empty" -ForegroundColor Yellow
        return;
    }

    $salt = [byte[]]::new(16); 
    [Security.Cryptography.RandomNumberGenerator]::Fill($salt);

    $key = [System.Security.Cryptography.Rfc2898DeriveBytes]::new(
        $passwd,
        $salt,
        $itertimes,
        [System.Security.Cryptography.HashAlgorithmName]::SHA256
    )

    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $key.GetBytes(32)
    $aes.GenerateIV()
    $encryptor = $aes.CreateEncryptor()
    $plainBytes = [System.Text.Encoding]::UTF8.GetBytes($plaintxt)
    $cipherBytes = $encryptor.TransformFinalBlock($plainBytes, 0, $plainBytes.Length)
    $resultBytes = $aes.IV + $cipherBytes

    $salttxt = [Convert]::ToBase64String($salt)
    $ctxt = [Convert]::ToBase64String($resultBytes)
    return "$salttxt`::$ctxt"
}

function decrypt {
    param (
        [string] $ciphertxt,
        [alias("f")]
        [switch] $isfilepath
    )

    if ($isfilepath) {
        $ciphertxt = Get-Content $ciphertxt -Raw -Encoding utf8
    }

    $passwd = Read-Host -Prompt "enter key" -MaskInput
    if ([string]::IsNullOrEmpty($passwd)) {
        Write-Host "key is empty" -ForegroundColor Yellow
        return;
    }

    $idx = $ciphertxt.IndexOf("::");
    if ($idx -lt 0) {
        Write-Host "invalid ciphertxt" -ForegroundColor Yellow
        return;
    }
    $salttxt = $ciphertxt.Substring(0, $idx);
    $ctxt = $ciphertxt.Substring($idx + 2);
    $salt = [Convert]::FromBase64String($salttxt);

    $derive = [System.Security.Cryptography.Rfc2898DeriveBytes]::new(
        $passwd, $salt, $itertimes, [System.Security.Cryptography.HashAlgorithmName]::SHA256
    );

    $fullBytes = [Convert]::FromBase64String($ctxt)
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $derive.GetBytes(32)
    $ivLength = $aes.BlockSize / 8
    $aes.IV = [byte[]]$fullBytes[0..($ivLength - 1)]
    $decryptor = $aes.CreateDecryptor()
    $cipherBytes = $fullBytes[$ivLength..($fullBytes.Length - 1)]
    $plainBytes = $decryptor.TransformFinalBlock($cipherBytes, 0, $cipherBytes.Length)
    return [System.Text.Encoding]::UTF8.GetString($plainBytes)
}
