@{
  RootModule = 'PowerADIF.psm1'

  ModuleVersion = '1.1.0'

  GUID = 'c6fe5929-1021-4f6a-99cc-571fea3912da'

  Author = 't3hn3rd (kjm@kieronmorris.me)'

  CompanyName = 'Spexeah'

  Description = 'PowerADIF - A PowerShell module for parsing ADIF (.adi) files.'

  RequiredModules = @()

  FunctionsToExport = @('Import-ADIF',
                        'Export-ADIF',
                        'ConvertTo-ADIF',
                        'ConvertFrom-ADIF',
                        'ConvertTo-ADIFTokens',
                        'ConvertFrom-ADIFTokens',
                        'Get-ADIFEnumerations'
                      )

  PrivateData = @{
    PSData = @{
      Tags = @('ADIF', 'Radio', 'Amateur', 'Data', 'Interchange', 'Format')
      LicenseUri = 'https://github.com/t3hn3rd/PowerADIF/blob/master/LICENSE'
      ProjectUri = 'https://github.com/t3hn3rd/PowerADIF'
      IconUri = 'https://github.com/t3hn3rd/PowerADIF/raw/master/media/icon_256.png'
    }
  }
}
