# 📜 PowerADIF

[![PSMimeTypes PSGallary Version](https://img.shields.io/powershellgallery/v/PowerADIF?label="PSGallery")](https://www.powershellgallery.com/packages/PowerADIF) [![PSGallery Downloads](https://img.shields.io/powershellgallery/dt/PowerADIF?label=PSGallery%20Downloads)](https://www.powershellgallery.com/packages/PowerADIF)

## 🌍 Overview
**PowerADIF** is a PowerShell module designed to parse (import/export) ADIF (Amateur Data Interchange Format) files in the `.adi` format. This module allows amateur radio operators to process log data efficiently.

## 🎯 Features
- Import ADIF `.adi` files and parse them into PowerShell objects.
- Export PowerShell objects into valid ADIF format.
- Adheres to the [ADIF 3.1.6 specification](https://adif.org/316/ADIF_316.htm) for `.adi` files.

## ❌ Non-Features
- Does not intend to support or parse `.adx` files for the time being. An XML parser should work for this.
- Includes the enumerations defined by the spec for use by the user, but does not enforce type checking, nor perform automatic value resolution via the enumerations. Although this would be a nice feature in the future.

## 💿 Installation

### Manual Installation
1. Download the `PowerADIF.psm1` file.
2. Place it in your PowerShell module directory:
   ```powershell
   $modulePath = "$HOME\Documents\PowerShell\Modules\PowerADIF"
   New-Item -ItemType Directory -Path $modulePath -Force
   Copy-Item -Path PowerADIF.psm1 -Destination $modulePath
   ```
3. Import the module:
   ```powershell
   Import-Module PowerADIF
   ```

### PSGallery
```powershell
Install-Module PowerADIF
Import-Module PowerADIF
```

## 🖥️ Usage

### Import an ADIF file
```powershell
$ADIF = Import-ADIF -Path "C:\Logs\log.adif"
$ADIF.Header
$ADIF.Records
```

### Export ADIF data
```powershell
Export-ADIF -ADIF $ADIF -Path "C:\Logs\exported.adif"
```

### Retrieve ADIF Enumerations
```powershell
$Enumerations = Get-ADIFEnumerations
$Enumerations
```

### Convert an ADIFStructure Object Back to Raw ADIF
```powershell
$ADIFString = $ADIFStructure | ConvertTo-ADIF
$ADIFString
```

## ⚙️ Functions
- **`Import-ADIF`** - Reads an ADIF file from disk and converts it to an `ADIFStructure` object.
- **`Export-ADIF`** - Converts an `ADIFStructure` object into ADIF format and saves it to a file.
- **`ConvertFrom-ADIF`** - Parses raw ADIF data into a structured object containing headers and records.
- **`ConvertTo-ADIF`** - Converts an `ADIFStructure` object into raw ADIF format.
- **`ConvertTo-ADIFTokens`** - Converts raw ADIF data into tokenized objects.
- **`ConvertFrom-ADIFTokens`** - Converts tokenized ADIF objects back into ADIF format.
- **`Get-ADIFEnumerations`** - Retrieves ADIF enumerations available in the ADIF specification.

## 📄 License
This module is licensed under the Apache 2.0 License.

## 🤝 Contributing
Contributions are welcome! Feel free to open issues or submit pull requests to enhance functionality.

## 👨‍💻 Contributors
- **Kieron Morris** (t3hn3rd) - [kjm@kieronmorris.me](mailto:kjm@kieronmorris.me)

