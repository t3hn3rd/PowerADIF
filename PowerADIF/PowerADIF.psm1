<#
	.SYNOPSIS
		A PowerShell module for parsing the ADIF format.
	.DESCRIPTION
		This module exposes a set of functions in order to
		import and process the Amateur Data Interchange Format.

		Format specification here: https://adif.org.uk/316/ADIF_316.htm
	.NOTES
        FILE NAME:
            PowerADIF.psm1
        AUTHOR:
            Kieron Morris (kjm@kieronmorris.me)
        VERSION:
            1.0
        GUID:
            c6fe5929-1021-4f6a-99cc-571fea3912da
        COPYRIGHT:
            None - MIT License
#>

enum TokenizerState {
	None
	FieldName
	FieldLength
	FieldDataType
	Value
	Comment
}

class ADIFEnumerations {
	static [PSCustomObject] DataTypes() {
		return [PSCustomObject]@{
			"AwardList"                = ""
			"CreditList"               = ""
			"SponsoredAwardList"       = ""
			"Boolean"                  = "B"
			"Digit"                    = ""
			"Integer"                  = ""
			"Number"                   = "N"
			"PositiveInteger"          = ""
			"Character"                = ""
			"IntlCharacter"            = ""
			"Date"                     = "D"
			"Time"                     = "T"
			"IOTARefNo"                = ""
			"String"                   = "S"
			"IntlString"               = "I"
			"MultilineString"          = "M"
			"IntlMultilineString"      = "G"
			"Enumeration"              = "E"
			"GridSquare"               = ""
			"GridSquareExt"            = ""
			"GridSquareList"           = ""
			"Location"                 = "L"
			"POTARef"                  = ""
			"POTARefList"              = ""
			"SecondarySubdivisionList"    = ""
			"SecondarySubdivisionListAlt" = ""
			"SOTARef"                     = ""
			"WWFFRef"                  = ""
		}
	}

	static [PSCustomObject] AntPath() {
		return [PSCustomObject]@{
			"G" = "grayline"
			"O" = "other"
			"S" = "short path"
			"L" = "long path"
		}
	}

	static [PSCustomObject] ARRLSection() {
		return [PSCustomObject]@{
			'AL'	=	[PSCustomObject]@{ 'Section Name' = 'Alabama'; 'DXCC Entity Code' = @(291) }
			'AK'	=	[PSCustomObject]@{ 'Section Name' = 'Alaska'; 'DXCC Entity Code' = @(6) }
			'AB'	=	[PSCustomObject]@{ 'Section Name' = 'Alberta'; 'DXCC Entity Code' = @(1) }
			'AR'	=	[PSCustomObject]@{ 'Section Name' = 'Arkansas'; 'DXCC Entity Code' = @(291) }
			'AZ'	=	[PSCustomObject]@{ 'Section Name' = 'Arizona'; 'DXCC Entity Code' = @(291) }
			'BC'	=	[PSCustomObject]@{ 'Section Name' = 'British Columbia'; 'DXCC Entity Code' = @(1) }
			'CO'	=	[PSCustomObject]@{ 'Section Name' = 'Colorado'; 'DXCC Entity Code' = @(291) }
			'CT'	=	[PSCustomObject]@{ 'Section Name' = 'Connecticut'; 'DXCC Entity Code' = @(291) }
			'DE'	=	[PSCustomObject]@{ 'Section Name' = 'Delaware'; 'DXCC Entity Code' = @(291) }
			'EB'	=	[PSCustomObject]@{ 'Section Name' = 'East Bay'; 'DXCC Entity Code' = @(291) }
			'EMA'	=	[PSCustomObject]@{ 'Section Name' = 'Eastern Massachusetts'; 'DXCC Entity Code' = @(291) }
			'ENY'	=	[PSCustomObject]@{ 'Section Name' = 'Eastern New York'; 'DXCC Entity Code' = @(291) }
			'EPA'	=	[PSCustomObject]@{ 'Section Name' = 'Eastern Pennsylvania'; 'DXCC Entity Code' = @(291) }
			'EWA'	=	[PSCustomObject]@{ 'Section Name' = 'Eastern Washington'; 'DXCC Entity Code' = @(291) }
			'GA'	=	[PSCustomObject]@{ 'Section Name' = 'Georgia'; 'DXCC Entity Code' = @(291) }
			'GH'	=	[PSCustomObject]@{ 'Section Name' = 'Golden Horseshoe'; 'DXCC Entity Code' = @(1) }
			'GTA'	=	[PSCustomObject]@{ 'Section Name' = 'Greater Toronto Area'; 'DXCC Entity Code' = @(1) }
			'ID'	=	[PSCustomObject]@{ 'Section Name' = 'Idaho'; 'DXCC Entity Code' = @(291) }
			'IL'	=	[PSCustomObject]@{ 'Section Name' = 'Illinois'; 'DXCC Entity Code' = @(291) }
			'IN'	=	[PSCustomObject]@{ 'Section Name' = 'Indiana'; 'DXCC Entity Code' = @(291) }
			'IA'	=	[PSCustomObject]@{ 'Section Name' = 'Iowa'; 'DXCC Entity Code' = @(291) }
			'KS'	=	[PSCustomObject]@{ 'Section Name' = 'Kansas'; 'DXCC Entity Code' = @(291) }
			'KY'	=	[PSCustomObject]@{ 'Section Name' = 'Kentucky'; 'DXCC Entity Code' = @(291) }
			'LAX'	=	[PSCustomObject]@{ 'Section Name' = 'Los Angeles'; 'DXCC Entity Code' = @(291) }
			'LA'	=	[PSCustomObject]@{ 'Section Name' = 'Louisiana'; 'DXCC Entity Code' = @(291) }
			'ME'	=	[PSCustomObject]@{ 'Section Name' = 'Maine'; 'DXCC Entity Code' = @(291) }
			'MB'	=	[PSCustomObject]@{ 'Section Name' = 'Manitoba'; 'DXCC Entity Code' = @(1) }
			'MAR'	=	[PSCustomObject]@{ 'Section Name' = 'Maritime'; 'DXCC Entity Code' = @(1) }
			'MDC'	=	[PSCustomObject]@{ 'Section Name' = 'Maryland-DC'; 'DXCC Entity Code' = @(291) }
			'MI'	=	[PSCustomObject]@{ 'Section Name' = 'Michigan'; 'DXCC Entity Code' = @(291) }
			'MN'	=	[PSCustomObject]@{ 'Section Name' = 'Minnesota'; 'DXCC Entity Code' = @(291) }
			'MS'	=	[PSCustomObject]@{ 'Section Name' = 'Mississippi'; 'DXCC Entity Code' = @(291) }
			'MO'	=	[PSCustomObject]@{ 'Section Name' = 'Missouri'; 'DXCC Entity Code' = @(291) }
			'MT'	=	[PSCustomObject]@{ 'Section Name' = 'Montana'; 'DXCC Entity Code' = @(291) }
			'NB'	=	[PSCustomObject]@{ 'Section Name' = 'New Brunswick'; 'DXCC Entity Code' = @(1) }
			'NE'	=	[PSCustomObject]@{ 'Section Name' = 'Nebraska'; 'DXCC Entity Code' = @(291) }
			'NS'	=	[PSCustomObject]@{ 'Section Name' = 'Nova Scotia'; 'DXCC Entity Code' = @(1) }
			'NV'	=	[PSCustomObject]@{ 'Section Name' = 'Nevada'; 'DXCC Entity Code' = @(291) }
			'NH'	=	[PSCustomObject]@{ 'Section Name' = 'New Hampshire'; 'DXCC Entity Code' = @(291) }
			'NM'	=	[PSCustomObject]@{ 'Section Name' = 'New Mexico'; 'DXCC Entity Code' = @(291) }
			'NLI'	=	[PSCustomObject]@{ 'Section Name' = 'New York City-Long Island'; 'DXCC Entity Code' = @(291) }
			'NL'	=	[PSCustomObject]@{ 'Section Name' = 'Newfoundland/Labrador'; 'DXCC Entity Code' = @(1) }
			'NC'	=	[PSCustomObject]@{ 'Section Name' = 'North Carolina'; 'DXCC Entity Code' = @(291) }
			'ND'	=	[PSCustomObject]@{ 'Section Name' = 'North Dakota'; 'DXCC Entity Code' = @(291) }
			'NTX'	=	[PSCustomObject]@{ 'Section Name' = 'North Texas'; 'DXCC Entity Code' = @(291) }
			'NFL'	=	[PSCustomObject]@{ 'Section Name' = 'Northern Florida'; 'DXCC Entity Code' = @(291) }
			'NNJ'	=	[PSCustomObject]@{ 'Section Name' = 'Northern New Jersey'; 'DXCC Entity Code' = @(291) }
			'NNY'	=	[PSCustomObject]@{ 'Section Name' = 'Northern New York'; 'DXCC Entity Code' = @(291) }
			'NT'	=	[PSCustomObject]@{ 'Section Name' = 'Northwest Territories/Yukon/Nunavut'; 'DXCC Entity Code' = @(1) }
			'NWT'	=	[PSCustomObject]@{ 'Section Name' = 'Northwest Territories/Yukon/Nunavut'; 'DXCC Entity Code' = @(1) }
			'OH'	=	[PSCustomObject]@{ 'Section Name' = 'Ohio'; 'DXCC Entity Code' = @(291) }
			'OK'	=	[PSCustomObject]@{ 'Section Name' = 'Oklahoma'; 'DXCC Entity Code' = @(291) }
			'ON'	=	[PSCustomObject]@{ 'Section Name' = 'Ontario'; 'DXCC Entity Code' = @(1) }
			'ONE'	=	[PSCustomObject]@{ 'Section Name' = 'Ontario East'; 'DXCC Entity Code' = @(1) }
			'ONN'	=	[PSCustomObject]@{ 'Section Name' = 'Ontario North'; 'DXCC Entity Code' = @(1) }
			'ONS'	=	[PSCustomObject]@{ 'Section Name' = 'Ontario South'; 'DXCC Entity Code' = @(1) }
			'ORG'	=	[PSCustomObject]@{ 'Section Name' = 'Orange'; 'DXCC Entity Code' = @(291) }
			'OR'	=	[PSCustomObject]@{ 'Section Name' = 'Oregon'; 'DXCC Entity Code' = @(291) }
			'PAC'	=	[PSCustomObject]@{ 'Section Name' = 'Pacific'; 'DXCC Entity Code' = @(9, 20, 103, 110, 123, 138, 166, 174, 197, 297, 515) }
			'PE'	=	[PSCustomObject]@{ 'Section Name' = 'Prince Edward Island'; 'DXCC Entity Code' = @(1) }
			'PR'	=	[PSCustomObject]@{ 'Section Name' = 'Puerto Rico'; 'DXCC Entity Code' = @(43, 202) }
			'QC'	=	[PSCustomObject]@{ 'Section Name' = 'Quebec'; 'DXCC Entity Code' = @(1) }
			'RI'	=	[PSCustomObject]@{ 'Section Name' = 'Rhode Island'; 'DXCC Entity Code' = @(291) }
			'SV'	=	[PSCustomObject]@{ 'Section Name' = 'Sacramento Valley'; 'DXCC Entity Code' = @(291) }
			'SDG'	=	[PSCustomObject]@{ 'Section Name' = 'San Diego'; 'DXCC Entity Code' = @(291) }
			'SF'	=	[PSCustomObject]@{ 'Section Name' = 'San Francisco'; 'DXCC Entity Code' = @(291) }
			'SJV'	=	[PSCustomObject]@{ 'Section Name' = 'San Joaquin Valley'; 'DXCC Entity Code' = @(291) }
			'SB'	=	[PSCustomObject]@{ 'Section Name' = 'Santa Barbara'; 'DXCC Entity Code' = @(291) }
			'SCV'	=	[PSCustomObject]@{ 'Section Name' = 'Santa Clara Valley'; 'DXCC Entity Code' = @(291) }
			'SK'	=	[PSCustomObject]@{ 'Section Name' = 'Saskatchewan'; 'DXCC Entity Code' = @(1) }
			'SC'	=	[PSCustomObject]@{ 'Section Name' = 'South Carolina'; 'DXCC Entity Code' = @(291) }
			'SD'	=	[PSCustomObject]@{ 'Section Name' = 'South Dakota'; 'DXCC Entity Code' = @(291) }
			'STX'	=	[PSCustomObject]@{ 'Section Name' = 'South Texas'; 'DXCC Entity Code' = @(291) }
			'SFL'	=	[PSCustomObject]@{ 'Section Name' = 'Southern Florida'; 'DXCC Entity Code' = @(291) }
			'SNJ'	=	[PSCustomObject]@{ 'Section Name' = 'Southern New Jersey'; 'DXCC Entity Code' = @(291) }
			'TER'	=	[PSCustomObject]@{ 'Section Name' = 'Territories'; 'DXCC Entity Code' = @(1) }
			'TN'	=	[PSCustomObject]@{ 'Section Name' = 'Tennessee'; 'DXCC Entity Code' = @(291) }
			'VI'	=	[PSCustomObject]@{ 'Section Name' = 'US Virgin Islands'; 'DXCC Entity Code' = @(105, 182, 285) }
			'UT'	=	[PSCustomObject]@{ 'Section Name' = 'Utah'; 'DXCC Entity Code' = @(291) }
			'VT'	=	[PSCustomObject]@{ 'Section Name' = 'Vermont'; 'DXCC Entity Code' = @(291) }
			'VA'	=	[PSCustomObject]@{ 'Section Name' = 'Virginia'; 'DXCC Entity Code' = @(291) }
			'WCF'	=	[PSCustomObject]@{ 'Section Name' = 'West Central Florida'; 'DXCC Entity Code' = @(291) }
			'WTX'	=	[PSCustomObject]@{ 'Section Name' = 'West Texas'; 'DXCC Entity Code' = @(291) }
			'WV'	=	[PSCustomObject]@{ 'Section Name' = 'West Virginia'; 'DXCC Entity Code' = @(291) }
			'WMA'	=	[PSCustomObject]@{ 'Section Name' = 'Western Massachusetts'; 'DXCC Entity Code' = @(291) }
			'WNY'	=	[PSCustomObject]@{ 'Section Name' = 'Western New York'; 'DXCC Entity Code' = @(291) }
			'WPA'	=	[PSCustomObject]@{ 'Section Name' = 'Western Pennsylvania'; 'DXCC Entity Code' = @(291) }
			'WWA'	=	[PSCustomObject]@{ 'Section Name' = 'Western Washington'; 'DXCC Entity Code' = @(291) }
			'WI'	=	[PSCustomObject]@{ 'Section Name' = 'Wisconsin'; 'DXCC Entity Code' = @(291) }
			'WY'	=	[PSCustomObject]@{ 'Section Name' = 'Wyoming'; 'DXCC Entity Code' = @(291) }
		}
	}

	static [Array] Award() {
		return @(
			"AJA"
			"CQDX"
			"CQDXFIELD"
			"CQWAZ_MIXED"
			"CQWAZ_CW"
			"CQWAZ_PHONE"
			"CQWAZ_RTTY"
			"CQWAZ_160m"
			"CQWPX"
			"DARC_DOK"
			"DXCC"
			"DXCC_MIXED"
			"DXCC_CW"
			"DXCC_PHONE"
			"DXCC_RTTY"
			"IOTA"
			"JCC"
			"JCG"
			"MARATHON"
			"RDA"
			"WAB"
			"WAC"
			"WAE"
			"WAIP"
			"WAJA"
			"WAS"
			"WAZ"
			"USACA"
			"VUCC"
		)
	}

	static [PSCustomObject] Band() {
		return [PSCustomObject]@{
			'2190m'		=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 0.1357; 'Upper Freq (MHz)' = 0.1378 }
			'630m'		=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 0.472; 'Upper Freq (MHz)' = 0.479 }
			'560m'		=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 0.501; 'Upper Freq (MHz)' = 0.504 }
			'160m'		=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 1.8; 'Upper Freq (MHz)' = 2 }
			'80m'			=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 3.5; 'Upper Freq (MHz)' = 4 }
			'60m'			=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 5.06; 'Upper Freq (MHz)' = 5.45 }
			'40m'			=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 7; 'Upper Freq (MHz)' = 7.3 }
			'30m'			=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 10.1; 'Upper Freq (MHz)' = 10.15 }
			'20m'			=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 14; 'Upper Freq (MHz)' = 14.35 }
			'17m'			=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 18.068; 'Upper Freq (MHz)' = 18.168 }
			'15m'			=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 21; 'Upper Freq (MHz)' = 21.45 }
			'12m'			=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 24.89; 'Upper Freq (MHz)' = 24.99 }
			'10m'			=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 28; 'Upper Freq (MHz)' = 29.7 }
			'8m'			=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 40; 'Upper Freq (MHz)' = 45 }
			'6m'			=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 50; 'Upper Freq (MHz)' = 54 }
			'5m'			=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 54.000001; 'Upper Freq (MHz)' = 69.9 }
			'4m'			=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 70; 'Upper Freq (MHz)' = 71 }
			'2m'			=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 144; 'Upper Freq (MHz)' = 148 }
			'1.25m'		=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 222; 'Upper Freq (MHz)' = 225 }
			'70cm'		=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 420; 'Upper Freq (MHz)' = 450 }
			'33cm'		=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 902; 'Upper Freq (MHz)' = 928 }
			'23cm'		=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 1240; 'Upper Freq (MHz)' = 1300 }
			'13cm'		=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 2300; 'Upper Freq (MHz)' = 2450 }
			'9cm'			=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 3300; 'Upper Freq (MHz)' = 3500 }
			'6cm'			=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 5650; 'Upper Freq (MHz)' = 5925 }
			'3cm'			=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 10000; 'Upper Freq (MHz)' = 10500 }
			'1.25cm'	=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 24000; 'Upper Freq (MHz)' = 24250 }
			'6mm'			=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 47000; 'Upper Freq (MHz)' = 47200 }
			'4mm'			=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 75500; 'Upper Freq (MHz)' = 81000 }
			'2.5mm'		=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 119980; 'Upper Freq (MHz)' = 123000 }
			'2mm'			=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 134000; 'Upper Freq (MHz)' = 149000 }
			'1mm'			=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 241000; 'Upper Freq (MHz)' = 250000 }
			'submm'		=	[PSCustomObject]@{ 'Lower Freq (MHz)' = 300000; 'Upper Freq (MHz)' = 7500000 }
		}
	}

	static [PSCustomObject] ContestID() {
		return [PSCustomObject]@{
			'070-160M-SPRINT'       = 'PODXS Great Pumpkin Sprint'
			'070-3-DAY'             = 'PODXS Three Day Weekend'
			'070-31-FLAVORS'        = 'PODXS 31 Flavors'
			'070-40M-SPRINT'        = 'PODXS 40m Firecracker Sprint'
			'070-80M-SPRINT'        = 'PODXS 80m Jay Hudak Memorial Sprint'
			'070-PSKFEST'           = 'PODXS PSKFest'
			'070-ST-PATS-DAY'       = 'PODXS St. Patricks Day'
			'070-VALENTINE-SPRINT'  = 'PODXS Valentine Sprint'
			'10-RTTY'               = 'Ten-Meter RTTY Contest (2011 onwards)'
			'1010-OPEN-SEASON'      = 'Open Season Ten Meter QSO Party'
			'7QP'                   = '7th-Area QSO Party'
			'AL-QSO-PARTY'          = 'Alabama QSO Party'
			'ALL-ASIAN-DX-CW'       = 'JARL All Asian DX Contest (CW)'
			'ALL-ASIAN-DX-PHONE'    = 'JARL All Asian DX Contest (PHONE)'
			'ANARTS-RTTY'           = 'ANARTS WW RTTY'
			'ANATOLIAN-RTTY'        = 'Anatolian WW RTTY'
			'AP-SPRINT'             = 'Asia - Pacific Sprint'
			'AR-QSO-PARTY'          = 'Arkansas QSO Party'
			'ARI-DX'                = 'ARI DX Contest'
			'ARI-EME'               = 'ARI EME Contest'
			'ARRL-10'               = 'ARRL 10 Meter Contest'
			'ARRL-10-GHZ'           = 'ARRL 10 GHz and Up Contest'
			'ARRL-160'              = 'ARRL 160 Meter Contest'
			'ARRL-222'              = 'ARRL 222 MHz and Up Distance Contest'
			'ARRL-DIGI'             = 'ARRL International Digital Contest'
			'ARRL-DX-CW'            = 'ARRL International DX Contest (CW)'
			'ARRL-DX-SSB'           = 'ARRL International DX Contest (Phone)'
			'ARRL-EME'              = 'ARRL EME contest'
			'ARRL-FIELD-DAY'        = 'ARRL Field Day'
			'ARRL-RR-CW'            = 'ARRL Rookie Roundup (CW)'
			'ARRL-RR-RTTY'          = 'ARRL Rookie Roundup (RTTY)'
			'ARRL-RR-SSB'           = 'ARRL Rookie Roundup (Phone)'
			'ARRL-RTTY'             = 'ARRL RTTY Round-Up'
			'ARRL-SCR'              = 'ARRL School Club Roundup'
			'ARRL-SS-CW'            = 'ARRL November Sweepstakes (CW)'
			'ARRL-SS-SSB'           = 'ARRL November Sweepstakes (Phone)'
			'ARRL-UHF-AUG'          = 'ARRL August UHF Contest'
			'ARRL-VHF-JAN'          = 'ARRL January VHF Sweepstakes'
			'ARRL-VHF-JUN'          = 'ARRL June VHF QSO Party'
			'ARRL-VHF-SEP'          = 'ARRL September VHF QSO Party'
			'AZ-QSO-PARTY'          = 'Arizona QSO Party'
			'BANGGAI-DX'            = 'Banggai DX Contest'
			'BARTG-RTTY'            = 'BARTG Spring RTTY Contest'
			'BARTG-SPRINT'          = 'BARTG Sprint Contest'
			'BC-QSO-PARTY'          = 'British Columbia QSO Party'
			'BEKASI-MERDEKA-CONTEST' = 'Bekasi Merdeka Contest'
			'CA-QSO-PARTY'          = 'California QSO Party'
			'CIS-DX'                = 'CIS DX Contest'
			'CO-QSO-PARTY'          = 'Colorado QSO Party'
			'CQ-160-CW'             = 'CQ WW 160 Meter DX Contest (CW)'
			'CQ-160-SSB'            = 'CQ WW 160 Meter DX Contest (SSB)'
			'CQ-M'                  = 'CQ-M International DX Contest'
			'CQ-VHF'                = 'CQ World-Wide VHF Contest'
			'CQ-WPX-CW'             = 'CQ WW WPX Contest (CW)'
			'CQ-WPX-RTTY'           = 'CQ/RJ WW RTTY WPX Contest'
			'CQ-WPX-SSB'            = 'CQ WW WPX Contest (SSB)'
			'CQ-WW-CW'              = 'CQ WW DX Contest (CW)'
			'CQ-WW-RTTY'            = 'CQ/RJ WW RTTY DX Contest'
			'CQ-WW-SSB'             = 'CQ WW DX Contest (SSB)'
			'CT-QSO-PARTY'          = 'Connecticut QSO Party'
			'CVA-DX-CW'             = 'Concurso Verde e Amarelo DX CW Contest'
			'CVA-DX-SSB'            = 'Concurso Verde e Amarelo DX CW Contest'
			'CWOPS-CW-OPEN'         = 'CWops CW Open Competition'
			'CWOPS-CWT'             = 'CWops Mini-CWT Test'
			'DARC-10'               = 'DARC 10-Meter Digital Contest'
			'DARC-CWA'              = 'DARC CW-Aktivitaet'
			'DARC-FT4'              = 'DARC FT4 Contest'
			'DARC-HELL'             = 'DARC Hellschreiber-Aktivitaet'
			'DARC-MICROWAVE'        = 'DARC Mikrowellenwettbewerb'
			'DARC-TRAINEE'          = 'DARC Trainee Contest'
			'DARC-UKW-FIELD-DAY'    = 'DARC UKW-Fieldday'
			'DARC-UKW-SPRING'       = 'DARC UKW-Fruehjahrscontest'
			'DARC-VHF-UHF-MICROWAVE' = 'DARC VHF, UHF, Microwave Contest'
			'DARC-WAEDC-CW'         = 'WAE DX Contest (CW)'
			'DARC-WAEDC-RTTY'       = 'WAE DX Contest (RTTY)'
			'DARC-WAEDC-SSB'        = 'WAE DX Contest (SSB)'
			'DARC-WAG'              = 'DARC Worked All Germany'
			'DE-QSO-PARTY'          = 'Delaware QSO Party'
			'DL-DX-RTTY'            = 'DL-DX RTTY Contest'
			'DMC-RTTY'              = 'DMC RTTY Contest'
			'EASTER'                = 'Easter Contest'
			'EA-CNCW'               = 'Concurso Nacional de Telegrafía'
			'EA-DME'                = 'Municipios Españoles'
			'EA-MAJESTAD-CW'        = 'His Majesty The King of Spain CW Contest (2022 and later)'
			'EA-MAJESTAD-SSB'       = 'His Majesty The King of Spain SSB Contest (2022 and later)'
			'EA-PSK63'              = 'EA PSK63'
			'EA-RTTY'               = 'Unión de Radioaficionados Españoles RTTY Contest'
			'EA-SMRE-CW'            = 'Su Majestad El Rey de España - CW (2021 and earlier)'
			'EA-SMRE-SSB'           = 'Su Majestad El Rey de España - SSB (2021 and earlier)'
			'EA-VHF-ATLANTIC'       = 'Atlántico V-UHF'
			'EA-VHF-COM'            = 'Combinado de V-UHF'
			'EA-VHF-COSTA-SOL'      = 'Costa del Sol V-UHF'
			'EA-VHF-EA'             = 'Nacional VHF'
			'EA-VHF-EA1RCS'         = 'Segovia EA1RCS V-UHF'
			'EA-VHF-QSL'            = 'QSL V-UHF & 50MHz'
			'EA-VHF-SADURNI'        = 'Sant Sadurni V-UHF'
			'EA-WW-RTTY'            = 'Unión de Radioaficionados Españoles RTTY Contest'
			'EPC-PSK63'             = 'PSK63 QSO Party'
			'EU Sprint'             = 'EU Sprint'
			'EU-HF'                 = 'EU HF Championship'
			'EU-PSK-DX'             = 'EU PSK DX Contest'
			'EUCW160M'              = 'European CW Association 160m CW Party'
			'FALL SPRINT'           = 'FISTS Fall Sprint'
			'FL-QSO-PARTY'          = 'Florida QSO Party'
			'GA-QSO-PARTY'          = 'Georgia QSO Party'
			'HA-DX'                 = 'Hungarian DX Contest'
			'HELVETIA'              = 'Helvetia Contest'
			'HI-QSO-PARTY'          = 'Hawaiian QSO Party'
			'HOLYLAND'              = 'IARC Holyland Contest'
			'IA-QSO-PARTY'          = 'Iowa QSO Party'
			'IARU-FIELD-DAY'        = 'DARC IARU Region 1 Field Day'
			'IARU-HF'               = 'IARU HF World Championship'
			'ICWC-MST'              = 'ICWC Medium Speed Test'
			'ID-QSO-PARTY'          = 'Idaho QSO Party'
			'IL QSO Party'          = 'Illinois QSO Party'
			'IN-QSO-PARTY'          = 'Indiana QSO Party'
			'JARTS-WW-RTTY'         = 'JARTS WW RTTY'
			'JIDX-CW'               = 'Japan International DX Contest (CW)'
			'JIDX-SSB'              = 'Japan International DX Contest (SSB)'
			'JT-DX-RTTY'            = 'Mongolian RTTY DX Contest'
			'K1USN-SSO'             = 'K1USN Slow Speed Organized'
			'K1USN-SST'             = 'K1USN Slow Speed Test'
			'KS-QSO-PARTY'          = 'Kansas QSO Party'
			'KY-QSO-PARTY'          = 'Kentucky QSO Party'
			'LA-QSO-PARTY'          = 'Louisiana QSO Party'
			'LDC-RTTY'              = 'DRCG Long Distance Contest (RTTY)'
			'LZ DX'                 = 'LZ DX Contest'
			'MAR-QSO-PARTY'         = 'Maritimes QSO Party'
			'MD-QSO-PARTY'          = 'Maryland QSO Party'
			'ME-QSO-PARTY'          = 'Maine QSO Party'
			'MI-QSO-PARTY'          = 'Michigan QSO Party'
			'MIDATLANTIC-QSO-PARTY' = 'Mid-Atlantic QSO Party'
			'MN-QSO-PARTY'          = 'Minnesota QSO Party'
			'MO-QSO-PARTY'          = 'Missouri QSO Party'
			'MS-QSO-PARTY'          = 'Mississippi QSO Party'
			'MT-QSO-PARTY'          = 'Montana QSO Party'
			'NA-SPRINT-CW'          = 'North America Sprint (CW)'
			'NA-SPRINT-RTTY'        = 'North America Sprint (RTTY)'
			'NA-SPRINT-SSB'         = 'North America Sprint (Phone)'
			'NAQP-CW'               = 'North America QSO Party (CW)'
			'NAQP-RTTY'             = 'North America QSO Party (RTTY)'
			'NAQP-SSB'              = 'North America QSO Party (Phone)'
			'NAVAL'                 = 'Naval Contest'
			'NC-QSO-PARTY'          = 'North Carolina QSO Party'
			'ND-QSO-PARTY'          = 'North Dakota QSO Party'
			'NE-QSO-PARTY'          = 'Nebraska QSO Party'
			'NEQP'                  = 'New England QSO Party'
			'NH-QSO-PARTY'          = 'New Hampshire QSO Party'
			'NJ-QSO-PARTY'          = 'New Jersey QSO Party'
			'NM-QSO-PARTY'          = 'New Mexico QSO Party'
			'NRAU-BALTIC-CW'        = 'NRAU-Baltic Contest (CW)'
			'NRAU-BALTIC-SSB'       = 'NRAU-Baltic Contest (SSB)'
			'NV-QSO-PARTY'          = 'Nevada QSO Party'
			'NY-QSO-PARTY'          = 'New York QSO Party'
			'OCEANIA-DX-CW'         = 'Oceania DX Contest (CW)'
			'OCEANIA-DX-SSB'        = 'Oceania DX Contest (SSB)'
			'OH-QSO-PARTY'          = 'Ohio QSO Party'
			'OK-DX-RTTY'            = 'Czech Radio Club OK DX Contest'
			'OK-OM-DX'              = 'Czech Radio Club OK-OM DX Contest'
			'OK-QSO-PARTY'          = 'Oklahoma QSO Party'
			'OMISS-QSO-PARTY'       = 'Old Man International Sideband Society QSO Party'
			'ON-QSO-PARTY'          = 'Ontario QSO Party'
			'OR-QSO-PARTY'          = 'Oregon QSO Party'
			'ORARI-DX'              = 'ORARI DX Contest'
			'PA-QSO-PARTY'          = 'Pennsylvania QSO Party'
			'PACC'                  = 'Dutch PACC Contest'
			'PCC'                   = 'PODXS Pancake Contest'
			'PSK-DEATHMATCH'        = 'MDXA PSK DeathMatch (2005-2010)'
			'QC-QSO-PARTY'          = 'Quebec QSO Party'
			'RAC'                   = 'Canadian Amateur Radio Society Contest'
			'RAC-CANADA-DAY'        = 'RAC Canada Day Contest'
			'RAC-CANADA-WINTER'     = 'RAC Canada Winter Contest'
			'RDAC'                  = 'Russian District Award Contest'
			'RDXC'                  = 'Russian DX Contest'
			'REF-160M'              = 'Reseau des Emetteurs Francais 160m Contest'
			'REF-CW'                = 'Reseau des Emetteurs Francais Contest (CW)'
			'REF-SSB'               = 'Reseau des Emetteurs Francais Contest (SSB)'
			'REP-PORTUGAL-DAY-HF'   = 'Rede dos Emissores Portugueses Portugal Day HF Contest'
			'RI-QSO-PARTY'          = 'Rhode Island QSO Party'
			'RSGB-160'              = '1.8MHz Contest'
			'RSGB-21/28-CW'         = '21/28 MHz Contest (CW)'
			'RSGB-21/28-SSB'        = '21/28 MHz Contest (SSB)'
			'RSGB-80M-CC'           = '80m Club Championships'
			'RSGB-AFS-CW'           = 'Affiliated Societies Team Contest (CW)'
			'RSGB-AFS-SSB'          = 'Affiliated Societies Team Contest (SSB)'
			'RSGB-CLUB-CALLS'       = 'Club Calls'
			'RSGB-COMMONWEALTH'     = 'Commonwealth Contest'
			'RSGB-IOTA'             = 'IOTA Contest'
			'RSGB-LOW-POWER'        = 'Low Power Field Day'
			'RSGB-NFD'              = 'National Field Day'
			'RSGB-ROPOCO'           = 'RoPoCo'
			'RSGB-SSB-FD'           = 'SSB Field Day'
			'RUSSIAN-RTTY'          = 'Russian Radio RTTY Worldwide Contest'
			'SAC-CW'                = 'Scandinavian Activity Contest (CW)'
			'SAC-SSB'               = 'Scandinavian Activity Contest (SSB)'
			'SARTG-RTTY'            = 'SARTG WW RTTY'
			'SC-QSO-PARTY'          = 'South Carolina QSO Party'
			'SCC-RTTY'              = 'SCC RTTY Championship'
			'SD-QSO-PARTY'          = 'South Dakota QSO Party'
			'ShortRY'               = 'ShortRY Contest'
			'SMP-AUG'               = 'SSA Portabeltest'
			'SMP-MAY'               = 'SSA Portabeltest'
			'SP-DX-RTTY'            = 'PRC SPDX Contest (RTTY)'
			'SPAR-WINTER-FD'        = 'SPAR Winter Field Day(2016 and earlier)'
			'SPDXContest'           = 'SP DX Contest'
			'SPRING SPRINT'         = 'FISTS Spring Sprint'
			'SR-MARATHON'           = 'Scottish-Russian Marathon'
			'STEW-PERRY'            = 'Stew Perry Topband Distance Challenge'
			'SUMMER SPRINT'         = 'FISTS Summer Sprint'
			'TARA-GRID-DIP'         = 'TARA Grid Dip PSK-RTTY Shindig'
			'TARA-RTTY'             = 'TARA RTTY Mêlée'
			'TARA-RUMBLE'           = 'TARA Rumble PSK Contest'
			'TARA-SKIRMISH'         = 'TARA Skirmish Digital Prefix Contest'
			'TEN-RTTY'              = 'Ten-Meter RTTY Contest (before 2011)'
			'TMC-RTTY'              = 'The Makrothen Contest'
			'TN-QSO-PARTY'          = 'Tennessee QSO Party'
			'TX-QSO-PARTY'          = 'Texas QSO Party'
			'UBA-DX-CW'             = 'UBA Contest (CW)'
			'UBA-DX-SSB'            = 'UBA Contest (SSB)'
			'UK-DX-BPSK63'          = 'European PSK Club BPSK63 Contest'
			'UK-DX-RTTY'            = 'UK DX RTTY Contest'
			'UKR-CHAMP-RTTY'        = 'Open Ukraine RTTY Championship'
			'UKRAINIAN DX'          = 'Ukrainian DX'
			'UKSMG-6M-MARATHON'     = 'UKSMG 6m Marathon'
			'UKSMG-SUMMER-ES'       = 'UKSMG Summer Es Contest'
			'URE-DX'               = 'Ukrainian DX Contest'
			'US-COUNTIES-QSO'       = 'Mobile Amateur Awards Club'
			'UT-QSO-PARTY'          = 'Utah QSO Party'
			'VA-QSO-PARTY'          = 'Virginia QSO Party'
			'VENEZ-IND-DAY'         = 'RCV Venezuelan Independence Day Contest'
			'VIRGINIA QSO PARTY'    = 'Virginia QSO Party'
			'VOLTA-RTTY'            = 'Alessandro Volta RTTY DX Contest'
			'VT-QSO-PARTY'          = 'Vermont QSO Party'
			'WA-QSO-PARTY'          = 'Washington QSO Party'
			'WFD'                   = 'Winter Field Day (2017 and later)'
			'WI-QSO-PARTY'          = 'Wisconsin QSO Party'
			'WIA-HARRY ANGEL'       = 'WIA Harry Angel Memorial 80m Sprint'
			'WIA-JMMFD'             = 'WIA John Moyle Memorial Field Day'
			'WIA-OCDX'              = 'WIA Oceania DX (OCDX) Contest'
			'WIA-REMEMBRANCE'       = 'WIA Remembrance Day'
			'WIA-ROSS HULL'         = 'WIA Ross Hull Memorial VHF/UHF Contest'
			'WIA-TRANS TASMAN'      = 'WIA Trans Tasman Low Bands Challenge'
			'WIA-VHF/UHF FD'        = 'WIA VHF UHF Field Days'
			'WIA-VK SHIRES'         = 'WIA VK Shires'
			'WINTER SPRINT'         = 'FISTS Winter Sprint'
			'WV-QSO-PARTY'          = 'West Virginia QSO Party'
			'WW-DIGI'               = 'World Wide Digi DX Contest'
			'WY-QSO-PARTY'          = 'Wyoming QSO Party'
			'XE-INTL-RTTY'          = 'Mexico International Contest (RTTY)'
			'YOHFDX'                = 'YODX HF contest'
			'YUDXC'                 = 'YU DX Contest'
		}
	}

	static [PSCustomObject] Continent() {
		return [PSCustomObject]@{
			'NA' = 'North America'
			'SA' = 'South America'
			'EU' = 'Europe'
			'AF' = 'Africa'
			'OC' = 'Oceania'
			'AS' = 'Asia'
			'AN' = 'Antarctica'
		}
	}

	static [PSCustomObject] Credit() {
		return [PSCustomObject]@{
			'CQDX'                = [PSCustomObject]@{ 'Sponsor' = 'CQ Magazine'; 'Award' = 'DX'; 'Facet' = 'Mixed'}
			'CQDX_BAND'           = [PSCustomObject]@{ 'Sponsor' = 'CQ Magazine'; 'Award' = 'DX'; 'Facet' = 'Band'}
			'CQDX_MODE'           = [PSCustomObject]@{ 'Sponsor' = 'CQ Magazine'; 'Award' = 'DX'; 'Facet' = 'Mode'}
			'CQDX_MOBILE'         = [PSCustomObject]@{ 'Sponsor' = 'CQ Magazine'; 'Award' = 'DX'; 'Facet' = 'Mobile'}
			'CQDX_QRP'            = [PSCustomObject]@{ 'Sponsor' = 'CQ Magazine'; 'Award' = 'DX'; 'Facet' = 'QRP'}
			'CQDX_SATELLITE'      = [PSCustomObject]@{ 'Sponsor' = 'CQ Magazine'; 'Award' = 'DX'; 'Facet' = 'Satellite'}
			'CQDXFIELD'           = [PSCustomObject]@{ 'Sponsor' = 'CQ Magazine'; 'Award' = 'DX Field'; 'Facet' = 'Mixed'}
			'CQDXFIELD_BAND'      = [PSCustomObject]@{ 'Sponsor' = 'CQ Magazine'; 'Award' = 'DX Field'; 'Facet' = 'Band'}
			'CQDXFIELD_MODE'      = [PSCustomObject]@{ 'Sponsor' = 'CQ Magazine'; 'Award' = 'DX Field'; 'Facet' = 'Mode'}
			'CQDXFIELD_MOBILE'    = [PSCustomObject]@{ 'Sponsor' = 'CQ Magazine'; 'Award' = 'DX Field'; 'Facet' = 'Mobile'}
			'CQDXFIELD_QRP'       = [PSCustomObject]@{ 'Sponsor' = 'CQ Magazine'; 'Award' = 'DX Field'; 'Facet' = 'QRP'}
			'CQDXFIELD_SATELLITE' = [PSCustomObject]@{ 'Sponsor' = 'CQ Magazine'; 'Award' = 'DX Field'; 'Facet' = 'Satellite'}
			'CQWAZ_MIXED'         = [PSCustomObject]@{ 'Sponsor' = 'CQ Magazine'; 'Award' = 'Worked All Zones (WAZ)'; 'Facet' = 'Mixed'}
			'CQWAZ_BAND'          = [PSCustomObject]@{ 'Sponsor' = 'CQ Magazine'; 'Award' = 'Worked All Zones (WAZ)'; 'Facet' = 'Band'}
			'CQWAZ_MODE'          = [PSCustomObject]@{ 'Sponsor' = 'CQ Magazine'; 'Award' = 'Worked All Zones (WAZ)'; 'Facet' = 'Mode'}
			'CQWAZ_SATELLITE'     = [PSCustomObject]@{ 'Sponsor' = 'CQ Magazine'; 'Award' = 'Worked All Zones (WAZ)'; 'Facet' = 'Satellite'}
			'CQWAZ_EME'           = [PSCustomObject]@{ 'Sponsor' = 'CQ Magazine'; 'Award' = 'Worked All Zones (WAZ)'; 'Facet' = 'EME'}
			'CQWAZ_MOBILE'        = [PSCustomObject]@{ 'Sponsor' = 'CQ Magazine'; 'Award' = 'Worked All Zones (WAZ)'; 'Facet' = 'Mobile'}
			'CQWAZ_QRP'           = [PSCustomObject]@{ 'Sponsor' = 'CQ Magazine'; 'Award' = 'Worked All Zones (WAZ)'; 'Facet' = 'QRP'}
			'CQWPX'               = [PSCustomObject]@{ 'Sponsor' = 'CQ Magazine'; 'Award' = 'WPX'; 'Facet' = 'Mixed'}
			'CQWPX_BAND'          = [PSCustomObject]@{ 'Sponsor' = 'CQ Magazine'; 'Award' = 'WPX'; 'Facet' = 'Band'}
			'CQWPX_MODE'          = [PSCustomObject]@{ 'Sponsor' = 'CQ Magazine'; 'Award' = 'WPX'; 'Facet' = 'Mode'}
			'DXCC'                = [PSCustomObject]@{ 'Sponsor' = 'ARRL'; 'Award' = 'DX Century Club (DXCC)'; 'Facet' = 'Mixed'}
			'DXCC_BAND'           = [PSCustomObject]@{ 'Sponsor' = 'ARRL'; 'Award' = 'DX Century Club (DXCC)'; 'Facet' = 'Band'}
			'DXCC_MODE'           = [PSCustomObject]@{ 'Sponsor' = 'ARRL'; 'Award' = 'DX Century Club (DXCC)'; 'Facet' = 'Mode'}
			'DXCC_SATELLITE'      = [PSCustomObject]@{ 'Sponsor' = 'ARRL'; 'Award' = 'DX Century Club (DXCC)'; 'Facet' = 'Satellite'}
			'EAUSTRALIA'          = [PSCustomObject]@{ 'Sponsor' = 'eQSL'; 'Award' = 'eAustralia'; 'Facet' = 'Mixed'}
			'ECANADA'             = [PSCustomObject]@{ 'Sponsor' = 'eQSL'; 'Award' = 'eCanada'; 'Facet' = 'Mixed'}
			'ECOUNTY_STATE'       = [PSCustomObject]@{ 'Sponsor' = 'eQSL'; 'Award' = 'eCounty'; 'Facet' = 'State'}
			'EDX'                 = [PSCustomObject]@{ 'Sponsor' = 'eQSL'; 'Award' = 'eDX'; 'Facet' = 'Mixed'}
			'EDX100'              = [PSCustomObject]@{ 'Sponsor' = 'eQSL'; 'Award' = 'eDX100'; 'Facet' = 'Mixed'}
			'EDX100_BAND'         = [PSCustomObject]@{ 'Sponsor' = 'eQSL'; 'Award' = 'eDX100'; 'Facet' = 'Band'}
			'EDX100_MODE'         = [PSCustomObject]@{ 'Sponsor' = 'eQSL'; 'Award' = 'eDX100'; 'Facet' = 'Mode'}
			'EECHOLINK50'         = [PSCustomObject]@{ 'Sponsor' = 'eQSL'; 'Award' = 'eEcholink50'; 'Facet' = 'Echolink'}
			'EGRID_BAND'          = [PSCustomObject]@{ 'Sponsor' = 'eQSL'; 'Award' = 'eGrid'; 'Facet' = 'Band'}
			'EGRID_SATELLITE'     = [PSCustomObject]@{ 'Sponsor' = 'eQSL'; 'Award' = 'eGrid'; 'Facet' = 'Satellite'}
			'EPFX300'             = [PSCustomObject]@{ 'Sponsor' = 'eQSL'; 'Award' = 'ePfx300'; 'Facet' = 'Mixed'}
			'EPFX300_MODE'        = [PSCustomObject]@{ 'Sponsor' = 'eQSL'; 'Award' = 'ePfx300'; 'Facet' = 'Mode'}
			'EWAS'                = [PSCustomObject]@{ 'Sponsor' = 'eQSL'; 'Award' = 'eWAS'; 'Facet' = 'Mixed'}
			'EWAS_BAND'           = [PSCustomObject]@{ 'Sponsor' = 'eQSL'; 'Award' = 'eWAS'; 'Facet' = 'Band'}
			'EWAS_MODE'           = [PSCustomObject]@{ 'Sponsor' = 'eQSL'; 'Award' = 'eWAS'; 'Facet' = 'Mode'}
			'EWAS_SATELLITE'      = [PSCustomObject]@{ 'Sponsor' = 'eQSL'; 'Award' = 'eWAS'; 'Facet' = 'Satellite'}
			'EZ40'                = [PSCustomObject]@{ 'Sponsor' = 'eQSL'; 'Award' = 'eZ40'; 'Facet' = 'Mixed'}
			'EZ40_MODE'           = [PSCustomObject]@{ 'Sponsor' = 'eQSL'; 'Award' = 'eZ40'; 'Facet' = 'Mode'}
			'FFMA'                = [PSCustomObject]@{ 'Sponsor' = 'ARRL'; 'Award' = 'Fred Fish Memorial Award (FFMA)'; 'Facet' = 'Mixed'}
			'IOTA'                = [PSCustomObject]@{ 'Sponsor' = 'RSGB'; 'Award' = 'Islands on the Air (IOTA)'; 'Facet' = 'Mixed'}
			'IOTA_BASIC'          = [PSCustomObject]@{ 'Sponsor' = 'RSGB'; 'Award' = 'Islands on the Air (IOTA)'; 'Facet' = 'Mixed'}
			'IOTA_CONT'           = [PSCustomObject]@{ 'Sponsor' = 'RSGB'; 'Award' = 'Islands on the Air (IOTA)'; 'Facet' = 'Continent'}
			'IOTA_GROUP'          = [PSCustomObject]@{ 'Sponsor' = 'RSGB'; 'Award' = 'Islands on the Air (IOTA)'; 'Facet' = 'Group'}
			'RDA'                 = [PSCustomObject]@{ 'Sponsor' = 'TAG'; 'Award' = 'Russian Districts Award (RDA)'; 'Facet' = 'Mixed'}
			'USACA'               = [PSCustomObject]@{ 'Sponsor' = 'CQ Magazine'; 'Award' = 'United States of America Counties (USA-CA)'; 'Facet' = 'Mixed'}
			'VUCC_BAND'           = [PSCustomObject]@{ 'Sponsor' = 'ARRL'; 'Award' = 'VHF/UHF Century Club Program (VUCC)'; 'Facet' = 'Band'}
			'VUCC_SATELLITE'      = [PSCustomObject]@{ 'Sponsor' = 'ARRL'; 'Award' = 'VHF/UHF Century Club Program (VUCC)'; 'Facet' = 'Satellite'}
			'WAB'                 = [PSCustomObject]@{ 'Sponsor' = 'WAB AG'; 'Award' = 'Worked All Britain (WAB)'; 'Facet' = 'Mixed'}
			'WAC'                 = [PSCustomObject]@{ 'Sponsor' = 'IARU'; 'Award' = 'Worked All Continents (WAC)'; 'Facet' = 'Mixed'}
			'WAC_BAND'            = [PSCustomObject]@{ 'Sponsor' = 'IARU'; 'Award' = 'Worked All Continents (WAC)'; 'Facet' = 'Band'}
			'WAE'                 = [PSCustomObject]@{ 'Sponsor' = 'DARC'; 'Award' = 'Worked All Europe (WAE)'; 'Facet' = 'Mixed'}
			'WAE_BAND'            = [PSCustomObject]@{ 'Sponsor' = 'DARC'; 'Award' = 'Worked All Europe (WAE)'; 'Facet' = 'Band'}
			'WAE_MODE'            = [PSCustomObject]@{ 'Sponsor' = 'DARC'; 'Award' = 'Worked All Europe (WAE)'; 'Facet' = 'Mode'}
			'WAIP'                = [PSCustomObject]@{ 'Sponsor' = 'ARI'; 'Award' = 'Worked All Italian Provinces (WAIP)'; 'Facet' = 'Mixed'}
			'WAIP_BAND'           = [PSCustomObject]@{ 'Sponsor' = 'ARI'; 'Award' = 'Worked All Italian Provinces (WAIP)'; 'Facet' = 'Band'}
			'WAIP_MODE'           = [PSCustomObject]@{ 'Sponsor' = 'ARI'; 'Award' = 'Worked All Italian Provinces (WAIP)'; 'Facet' = 'Mode'}
			'WAS'                 = [PSCustomObject]@{ 'Sponsor' = 'ARRL'; 'Award' = 'Worked All States (WAS)'; 'Facet' = 'Mixed'}
			'WAS_BAND'            = [PSCustomObject]@{ 'Sponsor' = 'ARRL'; 'Award' = 'Worked All States (WAS)'; 'Facet' = 'Band'}
			'WAS_EME'             = [PSCustomObject]@{ 'Sponsor' = 'ARRL'; 'Award' = 'Worked All States (WAS)'; 'Facet' = 'EME'}
			'WAS_MODE'            = [PSCustomObject]@{ 'Sponsor' = 'ARRL'; 'Award' = 'Worked All States (WAS)'; 'Facet' = 'Mode'}
			'WAS_NOVICE'          = [PSCustomObject]@{ 'Sponsor' = 'ARRL'; 'Award' = 'Worked All States (WAS)'; 'Facet' = 'Novice'}
			'WAS_QRP'             = [PSCustomObject]@{ 'Sponsor' = 'ARRL'; 'Award' = 'Worked All States (WAS)'; 'Facet' = 'QRP'}
			'WAS_SATELLITE'       = [PSCustomObject]@{ 'Sponsor' = 'ARRL'; 'Award' = 'Worked All States (WAS)'; 'Facet' = 'Satellite'}
			'WITUZ'               = [PSCustomObject]@{ 'Sponsor' = 'RSGB'; 'Award' = 'Worked ITU Zones (WITUZ)'; 'Facet' = 'Mixed'}
			'WITUZ_BAND'          = [PSCustomObject]@{ 'Sponsor' = 'RSGB'; 'Award' = 'Worked ITU Zones (WITUZ)'; 'Facet' = 'Band'}
		}
	}

	static [PSCustomObject] DXCCEntityCode() {
		return [PSCustomObject]@{
			0   = "None (the contacted station is known to not be within a DXCC entity)"
			1   = "CANADA"
			2   = "ABU AIL IS."
			3   = "AFGHANISTAN"
			4   = "AGALEGA & ST. BRANDON IS."
			5   = "ALAND IS."
			6   = "ALASKA"
			7   = "ALBANIA"
			8   = "ALDABRA"
			9   = "AMERICAN SAMOA"
			10  = "AMSTERDAM & ST. PAUL IS."
			11  = "ANDAMAN & NICOBAR IS."
			12  = "ANGUILLA"
			13  = "ANTARCTICA"
			14  = "ARMENIA"
			15  = "ASIATIC RUSSIA"
			16  = "NEW ZEALAND SUBANTARCTIC ISLANDS"
			17  = "AVES I."
			18  = "AZERBAIJAN"
			19  = "BAJO NUEVO"
			20  = "BAKER & HOWLAND IS."
			21  = "BALEARIC IS."
			22  = "PALAU"
			23  = "BLENHEIM REEF"
			24  = "BOUVET"
			25  = "BRITISH NORTH BORNEO"
			26  = "BRITISH SOMALILAND"
			27  = "BELARUS"
			28  = "CANAL ZONE"
			29  = "CANARY IS."
			30  = "CELEBE & MOLUCCA IS."
			31  = "C. KIRIBATI (BRITISH PHOENIX IS.)"
			32  = "CEUTA & MELILLA"
			33  = "CHAGOS IS."
			34  = "CHATHAM IS."
			35  = "CHRISTMAS I."
			36  = "CLIPPERTON I."
			37  = "COCOS I."
			38  = "COCOS (KEELING) IS."
			39  = "COMOROS"
			40  = "CRETE"
			41  = "CROZET I."
			42  = "DAMAO, DIU"
			43  = "DESECHEO I."
			44  = "DESROCHES"
			45  = "DODECANESE"
			46  = "EAST MALAYSIA"
			47  = "EASTER I."
			48  = "E. KIRIBATI (LINE IS.)"
			49  = "EQUATORIAL GUINEA"
			50  = "MEXICO"
			51  = "ERITREA"
			52  = "ESTONIA"
			53  = "ETHIOPIA"
			54  = "EUROPEAN RUSSIA"
			55  = "FARQUHAR"
			56  = "FERNANDO DE NORONHA"
			57  = "FRENCH EQUATORIAL AFRICA"
			58  = "FRENCH INDO-CHINA"
			59  = "FRENCH WEST AFRICA"
			60  = "BAHAMAS"
			61  = "FRANZ JOSEF LAND"
			62  = "BARBADOS"
			63  = "FRENCH GUIANA"
			64  = "BERMUDA"
			65  = "BRITISH VIRGIN IS."
			66  = "BELIZE"
			67  = "FRENCH INDIA"
			68  = "KUWAIT/SAUDI ARABIA NEUTRAL ZONE"
			69  = "CAYMAN IS."
			70  = "CUBA"
			71  = "GALAPAGOS IS."
			72  = "DOMINICAN REPUBLIC"
			74  = "EL SALVADOR"
			75  = "GEORGIA"
			76  = "GUATEMALA"
			77  = "GRENADA"
			78  = "HAITI"
			79  = "GUADELOUPE"
			80  = "HONDURAS"
			81  = "GERMANY"
			82  = "JAMAICA"
			84  = "MARTINIQUE"
			85  = "BONAIRE, CURACAO"
			86  = "NICARAGUA"
			88  = "PANAMA"
			89  = "TURKS & CAICOS IS."
			90  = "TRINIDAD & TOBAGO"
			91  = "ARUBA"
			93  = "GEYSER REEF"
			94  = "ANTIGUA & BARBUDA"
			95  = "DOMINICA"
			96  = "MONTSERRAT"
			97  = "ST. LUCIA"
			98  = "ST. VINCENT"
			99  = "GLORIOSO IS."
			100 = "ARGENTINA"
			101 = "GOA"
			102 = "GOLD COAST, TOGOLAND"
			103 = "GUAM"
			104 = "BOLIVIA"
			105 = "GUANTANAMO BAY"
			106 = "GUERNSEY"
			107 = "GUINEA"
			108 = "BRAZIL"
			109 = "GUINEA-BISSAU"
			110 = "HAWAII"
			111 = "HEARD I."
			112 = "CHILE"
			113 = "IFNI"
			114 = "ISLE OF MAN"
			115 = "ITALIAN SOMALILAND"
			116 = "COLOMBIA"
			117 = "ITU HQ"
			118 = "JAN MAYEN"
			119 = "JAVA"
			120 = "ECUADOR"
			122 = "JERSEY"
			123 = "JOHNSTON I."
			124 = "JUAN DE NOVA, EUROPA"
			125 = "JUAN FERNANDEZ IS."
			126 = "KALININGRAD"
			127 = "KAMARAN IS."
			128 = "KARELO-FINNISH REPUBLIC"
			129 = "GUYANA"
			130 = "KAZAKHSTAN"
			131 = "KERGUELEN IS."
			132 = "PARAGUAY"
			133 = "KERMADEC IS."
			134 = "KINGMAN REEF"
			135 = "KYRGYZSTAN"
			136 = "PERU"
			137 = "REPUBLIC OF KOREA"
			138 = "KURE I."
			139 = "KURIA MURIA I."
			140 = "SURINAME"
			141 = "FALKLAND IS."
			142 = "LAKSHADWEEP IS."
			143 = "LAOS"
			144 = "URUGUAY"
			145 = "LATVIA"
			146 = "LITHUANIA"
			147 = "LORD HOWE I."
			148 = "VENEZUELA"
			149 = "AZORES"
			150 = "AUSTRALIA"
			151 = "MALYJ VYSOTSKIJ I."
			152 = "MACAO"
			153 = "MACQUARIE I."
			154 = "YEMEN ARAB REPUBLIC"
			155 = "MALAYA"
			157 = "NAURU"
			158 = "VANUATU"
			159 = "MALDIVES"
			160 = "TONGA"
			161 = "MALPELO I."
			162 = "NEW CALEDONIA"
			163 = "PAPUA NEW GUINEA"
			164 = "MANCHURIA"
			165 = "MAURITIUS"
			166 = "MARIANA IS."
			167 = "MARKET REEF"
			168 = "MARSHALL IS."
			169 = "MAYOTTE"
			170 = "NEW ZEALAND"
			171 = "MELLISH REEF"
			172 = "PITCAIRN I."
			173 = "MICRONESIA"
			174 = "MIDWAY I."
			175 = "FRENCH POLYNESIA"
			176 = "FIJI"
			177 = "MINAMI TORISHIMA"
			178 = "MINERVA REEF"
			179 = "MOLDOVA"
			180 = "MOUNT ATHOS"
			181 = "MOZAMBIQUE"
			182 = "NAVASSA I."
			183 = "NETHERLANDS BORNEO"
			184 = "NETHERLANDS NEW GUINEA"
			185 = "SOLOMON IS."
			186 = "NEWFOUNDLAND, LABRADOR"
			187 = "NIGER"
			188 = "NIUE"
			189 = "NORFOLK I."
			190 = "SAMOA"
			191 = "NORTH COOK IS."
			192 = "OGASAWARA"
			193 = "OKINAWA (RYUKYU IS.)"
			194 = "OKINO TORI-SHIMA"
			195 = "ANNOBON I."
			196 = "PALESTINE"
			197 = "PALMYRA & JARVIS IS."
			198 = "PAPUA TERRITORY"
			199 = "PETER 1 I."
			200 = "PORTUGUESE TIMOR"
			201 = "PRINCE EDWARD & MARION IS."
			202 = "PUERTO RICO"
			203 = "ANDORRA"
			204 = "REVILLAGIGEDO"
			205 = "ASCENSION I."
			206 = "AUSTRIA"
			207 = "RODRIGUEZ I."
			208 = "RUANDA-URUNDI"
			209 = "BELGIUM"
			210 = "SAAR"
			211 = "SABLE I."
			212 = "BULGARIA"
			213 = "SAINT MARTIN"
			214 = "CORSICA"
			215 = "CYPRUS"
			216 = "SAN ANDRES & PROVIDENCIA"
			217 = "SAN FELIX & SAN AMBROSIO"
			218 = "CZECHOSLOVAKIA"
			219 = "SAO TOME & PRINCIPE"
			220 = "SARAWAK"
			221 = "DENMARK"
			222 = "FAROE IS."
			223 = "ENGLAND"
			224 = "FINLAND"
			225 = "SARDINIA"
			226 = "SAUDI ARABIA/IRAQ NEUTRAL ZONE"
			227 = "FRANCE"
			228 = "SERRANA BANK & RONCADOR CAY"
			229 = "GERMAN DEMOCRATIC REPUBLIC"
			230 = "FEDERAL REPUBLIC OF GERMANY"
			231 = "SIKKIM"
			232 = "SOMALIA"
			233 = "GIBRALTAR"
			234 = "SOUTH COOK IS."
			235 = "SOUTH GEORGIA I."
			236 = "GREECE"
			237 = "GREENLAND"
			238 = "SOUTH ORKNEY IS."
			239 = "HUNGARY"
			240 = "SOUTH SANDWICH IS."
			241 = "SOUTH SHETLAND IS."
			242 = "ICELAND"
			243 = "PEOPLE'S DEMOCRATIC REP. OF YEMEN"
			244 = "SOUTHERN SUDAN"
			245 = "IRELAND"
			246 = "SOVEREIGN MILITARY ORDER OF MALTA"
			247 = "SPRATLY IS."
			248 = "ITALY"
			249 = "ST. KITTS & NEVIS"
			250 = "ST. HELENA"
			251 = "LIECHTENSTEIN"
			252 = "ST. PAUL I."
			253 = "ST. PETER & ST. PAUL ROCKS"
			254 = "LUXEMBOURG"
			255 = "ST. MAARTEN, SABA, ST. EUSTATIUS"
			256 = "MADEIRA IS."
			257 = "MALTA"
			258 = "SUMATRA"
			259 = "SVALBARD"
			260 = "MONACO"
			261 = "SWAN IS."
			262 = "TAJIKISTAN"
			263 = "NETHERLANDS"
			264 = "TANGIER"
			265 = "NORTHERN IRELAND"
			266 = "NORWAY"
			267 = "TERRITORY OF NEW GUINEA"
			268 = "TIBET"
			269 = "POLAND"
			270 = "TOKELAU IS."
			271 = "TRIESTE"
			272 = "PORTUGAL"
			273 = "TRINDADE & MARTIM VAZ IS."
			274 = "TRISTAN DA CUNHA & GOUGH I."
			275 = "ROMANIA"
			276 = "TROMELIN I."
			277 = "ST. PIERRE & MIQUELON"
			278 = "SAN MARINO"
			279 = "SCOTLAND"
			280 = "TURKMENISTAN"
			281 = "SPAIN"
			282 = "TUVALU"
			283 = "UK SOVEREIGN BASE AREAS ON CYPRUS"
			284 = "SWEDEN"
			285 = "VIRGIN IS."
			286 = "UGANDA"
			287 = "SWITZERLAND"
			288 = "UKRAINE"
			289 = "UNITED NATIONS HQ"
			291 = "UNITED STATES OF AMERICA"
			292 = "UZBEKISTAN"
			293 = "VIET NAM"
			294 = "WALES"
			295 = "VATICAN"
			296 = "SERBIA"
			297 = "WAKE I."
			298 = "WALLIS & FUTUNA IS."
			299 = "WEST MALAYSIA"
			301 = "W. KIRIBATI (GILBERT IS. )"
			302 = "WESTERN SAHARA"
			303 = "WILLIS I."
			304 = "BAHRAIN"
			305 = "BANGLADESH"
			306 = "BHUTAN"
			307 = "ZANZIBAR"
			308 = "COSTA RICA"
			309 = "MYANMAR"
			312 = "CAMBODIA"
			315 = "SRI LANKA"
			318 = "CHINA"
			321 = "HONG KONG"
			324 = "INDIA"
			327 = "INDONESIA"
			330 = "IRAN"
			333 = "IRAQ"
			336 = "ISRAEL"
			339 = "JAPAN"
			342 = "JORDAN"
			344 = "DEMOCRATIC PEOPLE'S REP. OF KOREA"
			345 = "BRUNEI DARUSSALAM"
			348 = "KUWAIT"
			354 = "LEBANON"
			363 = "MONGOLIA"
			369 = "NEPAL"
			370 = "OMAN"
			372 = "PAKISTAN"
			375 = "PHILIPPINES"
			376 = "QATAR"
			378 = "SAUDI ARABIA"
			379 = "SEYCHELLES"
			381 = "SINGAPORE"
			382 = "DJIBOUTI"
			384 = "SYRIA"
			386 = "TAIWAN"
			387 = "THAILAND"
			390 = "TURKEY"
			391 = "UNITED ARAB EMIRATES"
			400 = "ALGERIA"
			401 = "ANGOLA"
			402 = "BOTSWANA"
			404 = "BURUNDI"
			406 = "CAMEROON"
			408 = "CENTRAL AFRICA"
			409 = "CAPE VERDE"
			410 = "CHAD"
			411 = "COMOROS"
			412 = "REPUBLIC OF THE CONGO"
			414 = "DEMOCRATIC REPUBLIC OF THE CONGO"
			416 = "BENIN"
			420 = "GABON"
			422 = "THE GAMBIA"
			424 = "GHANA"
			428 = "COTE D'IVOIRE"
			430 = "KENYA"
			432 = "LESOTHO"
			434 = "LIBERIA"
			436 = "LIBYA"
			438 = "MADAGASCAR"
			440 = "MALAWI"
			442 = "MALI"
			444 = "MAURITANIA"
			446 = "MOROCCO"
			450 = "NIGERIA"
			452 = "ZIMBABWE"
			453 = "REUNION I."
			454 = "RWANDA"
			456 = "SENEGAL"
			458 = "SIERRA LEONE"
			460 = "ROTUMA I."
			462 = "REPUBLIC OF SOUTH AFRICA"
			464 = "NAMIBIA"
			466 = "SUDAN"
			468 = "KINGDOM OF ESWATINI"
			470 = "TANZANIA"
			474 = "TUNISIA"
			478 = "EGYPT"
			480 = "BURKINA FASO"
			482 = "ZAMBIA"
			483 = "TOGO"
			488 = "WALVIS BAY"
			489 = "CONWAY REEF"
			490 = "BANABA I. (OCEAN I.)"
			492 = "YEMEN"
			493 = "PENGUIN IS."
			497 = "CROATIA"
			499 = "SLOVENIA"
			501 = "BOSNIA-HERZEGOVINA"
			502 = "NORTH MACEDONIA (REPUBLIC OF)"
			503 = "CZECH REPUBLIC"
			504 = "SLOVAK REPUBLIC"
			505 = "PRATAS I."
			506 = "SCARBOROUGH REEF"
			507 = "TEMOTU PROVINCE"
			508 = "AUSTRAL I."
			509 = "MARQUESAS IS."
			510 = "PALESTINE"
			511 = "TIMOR-LESTE"
			512 = "CHESTERFIELD IS."
			513 = "DUCIE I."
			514 = "MONTENEGRO"
			515 = "SWAINS I."
			516 = "SAINT BARTHELEMY"
			517 = "CURACAO"
			518 = "SINT MAARTEN"
			519 = "SABA & ST. EUSTATIUS"
			520 = "BONAIRE"
			521 = "SOUTH SUDAN (REPUBLIC OF)"
			522 = "REPUBLIC OF KOSOVO"
		}
	}

	static [PSCustomObject] Mode() {
		return [PSCustomObject]@{
			'AM'           = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'ARDOP'        = [PSCustomObject]@{'Submodes' = @(''); 'Description' = 'Amateur Radio Digital Open Protocol'}
			'ATV'          = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'CHIP'         = [PSCustomObject]@{'Submodes' = @('CHIP64', 'CHIP128'); 'Description' = ''}
			'CLO'          = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'CONTESTI'     = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'CW'           = [PSCustomObject]@{'Submodes' = @('PCW'); 'Description' = ''}
			'DIGITALVOICE' = [PSCustomObject]@{'Submodes' = @('C4FM', 'DMR', 'DSTAR', 'FREEDV', 'M17'); 'Description' = ''}
			'DOMINO'       = [PSCustomObject]@{'Submodes' = @('DOM-M', 'DOM4', 'DOM5', 'DOM8', 'DOM11', 'DOM16', 'DOM22', 'DOM44', 'DOM88', 'DOMINOEX', 'DOMINOF'); 'Description' = ''}
			'DYNAMIC'      = [PSCustomObject]@{'Submodes' = @('VARA HF', 'VARA SATELLITE', 'VARA FM 1200', 'VARA FM 9600'); 'Description' = ''}
			'FAX'          = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'FM'           = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'FSK'          = [PSCustomObject]@{'Submodes' = @('SCAMP_FAST', 'SCAMP_SLOW', 'SCAMP_VSLOW'); 'Description' = 'Frequency shift keying'}
			'FSK441'       = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'FT8'          = [PSCustomObject]@{'Submodes' = @(''); 'Description' = 'Franke-Taylor design, 8-FSK modulation'}
			'HELL'         = [PSCustomObject]@{'Submodes' = @('FMHELL', 'FSKH105', 'FSKH245', 'FSKHELL', 'HELL80', 'HELLX5', 'HELLX9', 'HFSK', 'PSKHELL', 'SLOWHELL'); 'Description' = ''}
			'ISCAT'        = [PSCustomObject]@{'Submodes' = @('ISCAT-A', 'ISCAT-B'); 'Description' = ''}
			'JT4'          = [PSCustomObject]@{'Submodes' = @('JT4A', 'JT4B', 'JT4C', 'JT4D', 'JT4E', 'JT4F', 'JT4G'); 'Description' = ''}
			'JT6M'         = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'JT9'          = [PSCustomObject]@{'Submodes' = @('JT9-1', 'JT9-2', 'JT9-5', 'JT9-10', 'JT9-30', 'JT9A', 'JT9B', 'JT9C', 'JT9D', 'JT9E', 'JT9E FAST', 'JT9F', 'JT9F FAST', 'JT9G', 'JT9G FAST', 'JT9H', 'JT9H FAST'); 'Description' = ''}
			'JT44'         = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'JT65'         = [PSCustomObject]@{'Submodes' = @('JT65A', 'JT65B', 'JT65B2', 'JT65C', 'JT65C2'); 'Description' = ''}
			'MFSK'         = [PSCustomObject]@{'Submodes' = @('FSQCALL', 'FST4', 'FST4W', 'FT4', 'JS8', 'JTMS', 'MFSK4', 'MFSK8', 'MFSK11', 'MFSK16', 'MFSK22', 'MFSK31', 'MFSK32', 'MFSK64', 'MFSK64L', 'MFSK128', 'MFSK128L', 'Q65'); 'Description' = ''}
			'MSK144'       = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'MT63'         = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'MTONE'        = [PSCustomObject]@{'Submodes' = @('SCAMP_OO', 'SCAMP_OO_SLW'); 'Description' = 'Single modulated tone'}
			'OLIVIA'       = [PSCustomObject]@{'Submodes' = @('OLIVIA 4/125', 'OLIVIA 4/250', 'OLIVIA 8/250', 'OLIVIA 8/500', 'OLIVIA 16/500', 'OLIVIA 16/1000', 'OLIVIA 32/1000'); 'Description' = ''}
			'OPERA'        = [PSCustomObject]@{'Submodes' = @('OPERA-BEACON', 'OPERA-QSO'); 'Description' = ''}
			'PAC'          = [PSCustomObject]@{'Submodes' = @('PAC2', 'PAC3', 'PAC4'); 'Description' = ''}
			'PAX'          = [PSCustomObject]@{'Submodes' = @('PAX2'); 'Description' = ''}
			'PKT'          = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'PSK'          = [PSCustomObject]@{'Submodes' = @('8PSK125', '8PSK125F', '8PSK125FL', '8PSK250', '8PSK250F', '8PSK250FL', '8PSK500', '8PSK500F', '8PSK1000', '8PSK1000F', '8PSK1200F', 'FSK31', 'PSK10', 'PSK31', 'PSK63', 'PSK63F', 'PSK63RC4', 'PSK63RC5', 'PSK63RC10', 'PSK63RC20', 'PSK63RC32', 'PSK125', 'PSK125C12', 'PSK125R', 'PSK125RC10', 'PSK125RC12', 'PSK125RC16', 'PSK125RC4', 'PSK125RC5', 'PSK250', 'PSK250C6', 'PSK250R', 'PSK250RC2', 'PSK250RC3', 'PSK250RC5', 'PSK250RC6', 'PSK250RC7', 'PSK500', 'PSK500C2', 'PSK500C4', 'PSK500R', 'PSK500RC2', 'PSK500RC3', 'PSK500RC4', 'PSK800C2', 'PSK800RC2', 'PSK1000', 'PSK1000C2', 'PSK1000R', 'PSK1000RC2', 'PSKAM10', 'PSKAM31', 'PSKAM50', 'PSKFEC31', 'QPSK31', 'QPSK63', 'QPSK125', 'QPSK250', 'QPSK500', 'SIM31'); 'Description' = ''}
			'PSK2K'        = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'Q15'          = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'QRA64'        = [PSCustomObject]@{'Submodes' = @('QRA64A', 'QRA64B', 'QRA64C', 'QRA64D', 'QRA64E'); 'Description' = ''}
			'ROS'          = [PSCustomObject]@{'Submodes' = @('ROS-EME', 'ROS-HF', 'ROS-MF'); 'Description' = ''}
			'RTTY'         = [PSCustomObject]@{'Submodes' = @('ASCI'); 'Description' = ''}
			'RTTYM'        = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'SSB'          = [PSCustomObject]@{'Submodes' = @('LSB', 'USB'); 'Description' = ''}
			'SSTV'         = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'T10'          = [PSCustomObject]@{'Submodes' = @(''); 'Description' = 'Tonal 10 digital mode with focus on sensitivity, band capacity and resistance to the HF Doppler frequency spread'}
			'THOR'         = [PSCustomObject]@{'Submodes' = @('THOR-M', 'THOR4', 'THOR5', 'THOR8', 'THOR11', 'THOR16', 'THOR22', 'THOR25X4', 'THOR50X1', 'THOR50X2', 'THOR100'); 'Description' = ''}
			'THRB'         = [PSCustomObject]@{'Submodes' = @('THRBX', 'THRBX1', 'THRBX2', 'THRBX4', 'THROB1', 'THROB2', 'THROB4'); 'Description' = ''}
			'TOR'          = [PSCustomObject]@{'Submodes' = @('AMTORFEC', 'GTOR', 'NAVTEX', 'SITORB'); 'Description' = ''}
			'V4'           = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'VOI'          = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'WINMOR'       = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'WSPR'         = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'AMTORFEC'     = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'ASCI'         = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'C4FM'         = [PSCustomObject]@{'Submodes' = @(''); 'Description' = 'C4FM 4-level FSK Technology'}
			'CHIP64'       = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'CHIP128'      = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'DOMINOF'      = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'DSTAR'        = [PSCustomObject]@{'Submodes' = @(''); 'Description' = 'Digital Smart Technologies for Amateur Radio'}
			'FMHELL'       = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'FSK31'        = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'GTOR'         = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'HELL80'       = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'HFSK'         = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'JT4A'         = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'JT4B'         = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'JT4C'         = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'JT4D'         = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'JT4E'         = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'JT4F'         = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'JT4G'         = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'JT65A'        = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'JT65B'        = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'JT65C'        = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'MFSK8'        = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'MFSK16'       = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'PAC2'         = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'PAC3'         = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'PAX2'         = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'PCW'          = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'PSK10'        = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'PSK31'        = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'PSK63'        = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'PSK63F'       = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'PSK125'       = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'PSKAM10'      = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'PSKAM31'      = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'PSKAM50'      = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'PSKFEC31'     = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'PSKHELL'      = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'QPSK31'       = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'QPSK63'       = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'QPSK125'      = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
			'THRBX'        = [PSCustomObject]@{'Submodes' = @(''); 'Description' = ''}
		}
	}

	static [PSCustomObject] Submode() {
		return [PSCustomObject]@{
			'8PSK125'        = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'8PSK125F'       = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'8PSK125FL'      = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'8PSK250'        = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'8PSK250F'       = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'8PSK250FL'      = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'8PSK500'        = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'8PSK500F'       = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'8PSK1000'       = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'8PSK1000F'      = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'8PSK1200F'      = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'AMTORFEC'       = [PSCustomObject]@{'Mode' = 'TOR'; 'Description' = ''}
			'ASCI'           = [PSCustomObject]@{'Mode' = 'RTTY'; 'Description' = ''}
			'C4FM'           = [PSCustomObject]@{'Mode' = 'DIGITALVOICE'; 'Description' = 'C4FM 4-level FSK'}
			'CHIP64'         = [PSCustomObject]@{'Mode' = 'CHIP'; 'Description' = ''}
			'CHIP128'        = [PSCustomObject]@{'Mode' = 'CHIP'; 'Description' = ''}
			'DMR'            = [PSCustomObject]@{'Mode' = 'DIGITALVOICE'; 'Description' = 'Digital Mobile Radio'}
			'DOM-M'          = [PSCustomObject]@{'Mode' = 'DOMINO'; 'Description' = ''}
			'DOM4'           = [PSCustomObject]@{'Mode' = 'DOMINO'; 'Description' = ''}
			'DOM5'           = [PSCustomObject]@{'Mode' = 'DOMINO'; 'Description' = ''}
			'DOM8'           = [PSCustomObject]@{'Mode' = 'DOMINO'; 'Description' = ''}
			'DOM11'          = [PSCustomObject]@{'Mode' = 'DOMINO'; 'Description' = ''}
			'DOM16'          = [PSCustomObject]@{'Mode' = 'DOMINO'; 'Description' = ''}
			'DOM22'          = [PSCustomObject]@{'Mode' = 'DOMINO'; 'Description' = ''}
			'DOM44'          = [PSCustomObject]@{'Mode' = 'DOMINO'; 'Description' = ''}
			'DOM88'          = [PSCustomObject]@{'Mode' = 'DOMINO'; 'Description' = ''}
			'DOMINOEX'       = [PSCustomObject]@{'Mode' = 'DOMINO'; 'Description' = ''}
			'DOMINOF'        = [PSCustomObject]@{'Mode' = 'DOMINO'; 'Description' = ''}
			'DSTAR'          = [PSCustomObject]@{'Mode' = 'DIGITALVOICE'; 'Description' = 'Digital Smart Technologies for Amateur Radio'}
			'FMHELL'         = [PSCustomObject]@{'Mode' = 'HELL'; 'Description' = ''}
			'FREEDV'         = [PSCustomObject]@{'Mode' = 'DIGITALVOICE'; 'Description' = 'Digital voice mode for HF radio implemented with open source'}
			'FSK31'          = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'FSKH105'        = [PSCustomObject]@{'Mode' = 'HELL'; 'Description' = ''}
			'FSKH245'        = [PSCustomObject]@{'Mode' = 'HELL'; 'Description' = ''}
			'FSKHELL'        = [PSCustomObject]@{'Mode' = 'HELL'; 'Description' = ''}
			'FSQCALL'        = [PSCustomObject]@{'Mode' = 'MFSK'; 'Description' = 'FSQCall protocol used with FSQ (Fast Simple QSO) transmission mode'}
			'FST4'           = [PSCustomObject]@{'Mode' = 'MFSK'; 'Description' = 'This is a digital mode supported by the WSJT-X software'}
			'FST4W'          = [PSCustomObject]@{'Mode' = 'MFSK'; 'Description' = 'This is a digital mode supported by the WSJT-X software that is for quasi-beacon transmissions of WSPR-style messages'}
			'FT4'            = [PSCustomObject]@{'Mode' = 'MFSK'; 'Description' = 'FT4 is a digital mode designed specifically for radio contesting'}
			'GTOR'           = [PSCustomObject]@{'Mode' = 'TOR'; 'Description' = ''}
			'HELL80'         = [PSCustomObject]@{'Mode' = 'HELL'; 'Description' = ''}
			'HELLX5'         = [PSCustomObject]@{'Mode' = 'HELL'; 'Description' = ''}
			'HELLX9'         = [PSCustomObject]@{'Mode' = 'HELL'; 'Description' = ''}
			'HFSK'           = [PSCustomObject]@{'Mode' = 'HELL'; 'Description' = ''}
			'ISCAT-A'        = [PSCustomObject]@{'Mode' = 'ISCAT'; 'Description' = ''}
			'ISCAT-B'        = [PSCustomObject]@{'Mode' = 'ISCAT'; 'Description' = ''}
			'JS8'            = [PSCustomObject]@{'Mode' = 'MFSK'; 'Description' = 'Jordan Sherer designed 8-FSK modulation'}
			'JT4A'           = [PSCustomObject]@{'Mode' = 'JT4'; 'Description' = ''}
			'JT4B'           = [PSCustomObject]@{'Mode' = 'JT4'; 'Description' = ''}
			'JT4C'           = [PSCustomObject]@{'Mode' = 'JT4'; 'Description' = ''}
			'JT4D'           = [PSCustomObject]@{'Mode' = 'JT4'; 'Description' = ''}
			'JT4E'           = [PSCustomObject]@{'Mode' = 'JT4'; 'Description' = ''}
			'JT4F'           = [PSCustomObject]@{'Mode' = 'JT4'; 'Description' = ''}
			'JT4G'           = [PSCustomObject]@{'Mode' = 'JT4'; 'Description' = ''}
			'JT9-1'          = [PSCustomObject]@{'Mode' = 'JT9'; 'Description' = ''}
			'JT9-2'          = [PSCustomObject]@{'Mode' = 'JT9'; 'Description' = ''}
			'JT9-5'          = [PSCustomObject]@{'Mode' = 'JT9'; 'Description' = ''}
			'JT9-10'         = [PSCustomObject]@{'Mode' = 'JT9'; 'Description' = ''}
			'JT9-30'         = [PSCustomObject]@{'Mode' = 'JT9'; 'Description' = ''}
			'JT9A'           = [PSCustomObject]@{'Mode' = 'JT9'; 'Description' = ''}
			'JT9B'           = [PSCustomObject]@{'Mode' = 'JT9'; 'Description' = ''}
			'JT9C'           = [PSCustomObject]@{'Mode' = 'JT9'; 'Description' = ''}
			'JT9D'           = [PSCustomObject]@{'Mode' = 'JT9'; 'Description' = ''}
			'JT9E'           = [PSCustomObject]@{'Mode' = 'JT9'; 'Description' = ''}
			'JT9E FAST'      = [PSCustomObject]@{'Mode' = 'JT9'; 'Description' = ''}
			'JT9F'           = [PSCustomObject]@{'Mode' = 'JT9'; 'Description' = ''}
			'JT9F FAST'      = [PSCustomObject]@{'Mode' = 'JT9'; 'Description' = ''}
			'JT9G'           = [PSCustomObject]@{'Mode' = 'JT9'; 'Description' = ''}
			'JT9G FAST'      = [PSCustomObject]@{'Mode' = 'JT9'; 'Description' = ''}
			'JT9H'           = [PSCustomObject]@{'Mode' = 'JT9'; 'Description' = ''}
			'JT9H FAST'      = [PSCustomObject]@{'Mode' = 'JT9'; 'Description' = ''}
			'JT65A'          = [PSCustomObject]@{'Mode' = 'JT65'; 'Description' = ''}
			'JT65B'          = [PSCustomObject]@{'Mode' = 'JT65'; 'Description' = ''}
			'JT65B2'         = [PSCustomObject]@{'Mode' = 'JT65'; 'Description' = ''}
			'JT65C'          = [PSCustomObject]@{'Mode' = 'JT65'; 'Description' = ''}
			'JT65C2'         = [PSCustomObject]@{'Mode' = 'JT65'; 'Description' = ''}
			'JTMS'           = [PSCustomObject]@{'Mode' = 'MFSK'; 'Description' = ''}
			'LSB'            = [PSCustomObject]@{'Mode' = 'SSB'; 'Description' = 'Amplitude modulated voice telephony, lower-sideband, suppressed-carrier'}
			'M17'            = [PSCustomObject]@{'Mode' = 'DIGITALVOICE'; 'Description' = 'Digital radio protocol using the Codec 2 voice encoder'}
			'MFSK4'          = [PSCustomObject]@{'Mode' = 'MFSK'; 'Description' = ''}
			'MFSK8'          = [PSCustomObject]@{'Mode' = 'MFSK'; 'Description' = ''}
			'MFSK11'         = [PSCustomObject]@{'Mode' = 'MFSK'; 'Description' = ''}
			'MFSK16'         = [PSCustomObject]@{'Mode' = 'MFSK'; 'Description' = ''}
			'MFSK22'         = [PSCustomObject]@{'Mode' = 'MFSK'; 'Description' = ''}
			'MFSK31'         = [PSCustomObject]@{'Mode' = 'MFSK'; 'Description' = ''}
			'MFSK32'         = [PSCustomObject]@{'Mode' = 'MFSK'; 'Description' = ''}
			'MFSK64'         = [PSCustomObject]@{'Mode' = 'MFSK'; 'Description' = ''}
			'MFSK64L'        = [PSCustomObject]@{'Mode' = 'MFSK'; 'Description' = ''}
			'MFSK128'        = [PSCustomObject]@{'Mode' = 'MFSK'; 'Description' = ''}
			'MFSK128L'       = [PSCustomObject]@{'Mode' = 'MFSK'; 'Description' = ''}
			'NAVTEX'         = [PSCustomObject]@{'Mode' = 'TOR'; 'Description' = ''}
			'OLIVIA 4/125'   = [PSCustomObject]@{'Mode' = 'OLIVIA'; 'Description' = ''}
			'OLIVIA 4/250'   = [PSCustomObject]@{'Mode' = 'OLIVIA'; 'Description' = ''}
			'OLIVIA 8/250'   = [PSCustomObject]@{'Mode' = 'OLIVIA'; 'Description' = ''}
			'OLIVIA 8/500'   = [PSCustomObject]@{'Mode' = 'OLIVIA'; 'Description' = ''}
			'OLIVIA 16/500'  = [PSCustomObject]@{'Mode' = 'OLIVIA'; 'Description' = ''}
			'OLIVIA 16/1000' = [PSCustomObject]@{'Mode' = 'OLIVIA'; 'Description' = ''}
			'OLIVIA 32/1000' = [PSCustomObject]@{'Mode' = 'OLIVIA'; 'Description' = ''}
			'OPERA-BEACON'   = [PSCustomObject]@{'Mode' = 'OPERA'; 'Description' = ''}
			'OPERA-QSO'      = [PSCustomObject]@{'Mode' = 'OPERA'; 'Description' = ''}
			'PAC2'           = [PSCustomObject]@{'Mode' = 'PAC'; 'Description' = ''}
			'PAC3'           = [PSCustomObject]@{'Mode' = 'PAC'; 'Description' = ''}
			'PAC4'           = [PSCustomObject]@{'Mode' = 'PAC'; 'Description' = ''}
			'PAX2'           = [PSCustomObject]@{'Mode' = 'PAX'; 'Description' = ''}
			'PCW'            = [PSCustomObject]@{'Mode' = 'CW'; 'Description' = 'Coherent CW'}
			'PSK10'          = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK31'          = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK63'          = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK63F'         = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK63RC10'      = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK63RC20'      = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK63RC32'      = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK63RC4'       = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK63RC5'       = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK125'         = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK125C12'      = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK125R'        = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK125RC10'     = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK125RC12'     = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK125RC16'     = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK125RC4'      = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK125RC5'      = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK250'         = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK250C6'       = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK250R'        = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK250RC2'      = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK250RC3'      = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK250RC5'      = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK250RC6'      = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK250RC7'      = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK500'         = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK500C2'       = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK500C4'       = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK500R'        = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK500RC2'      = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK500RC3'      = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK500RC4'      = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK800C2'       = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK800RC2'      = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK1000'        = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK1000C2'      = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK1000R'       = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSK1000RC2'     = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSKAM10'        = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSKAM31'        = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSKAM50'        = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSKFEC31'       = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'PSKHELL'        = [PSCustomObject]@{'Mode' = 'HELL'; 'Description' = ''}
			'QPSK31'         = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'Q65'            = [PSCustomObject]@{'Mode' = 'MFSK'; 'Description' = ''}
			'QPSK63'         = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'QPSK125'        = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'QPSK250'        = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'QPSK500'        = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'QRA64A'         = [PSCustomObject]@{'Mode' = 'QRA64'; 'Description' = ''}
			'QRA64B'         = [PSCustomObject]@{'Mode' = 'QRA64'; 'Description' = ''}
			'QRA64C'         = [PSCustomObject]@{'Mode' = 'QRA64'; 'Description' = ''}
			'QRA64D'         = [PSCustomObject]@{'Mode' = 'QRA64'; 'Description' = ''}
			'QRA64E'         = [PSCustomObject]@{'Mode' = 'QRA64'; 'Description' = ''}
			'ROS-EME'        = [PSCustomObject]@{'Mode' = 'ROS'; 'Description' = ''}
			'ROS-HF'         = [PSCustomObject]@{'Mode' = 'ROS'; 'Description' = ''}
			'ROS-MF'         = [PSCustomObject]@{'Mode' = 'ROS'; 'Description' = ''}
			'SIM31'          = [PSCustomObject]@{'Mode' = 'PSK'; 'Description' = ''}
			'SITORB'         = [PSCustomObject]@{'Mode' = 'TOR'; 'Description' = ''}
			'SCAMP_FAST'     = [PSCustomObject]@{'Mode' = 'FSK'; 'Description' = ''}
			'SCAMP_OO'       = [PSCustomObject]@{'Mode' = 'MTONE'; 'Description' = ''}
			'SCAMP_OO_SLW'   = [PSCustomObject]@{'Mode' = 'MTONE'; 'Description' = ''}
			'SCAMP_SLOW'     = [PSCustomObject]@{'Mode' = 'FSK'; 'Description' = ''}
			'SCAMP_VSLOW'    = [PSCustomObject]@{'Mode' = 'FSK'; 'Description' = ''}
			'SLOWHELL'       = [PSCustomObject]@{'Mode' = 'HELL'; 'Description' = ''}
			'THOR-M'         = [PSCustomObject]@{'Mode' = 'THOR'; 'Description' = ''}
			'THOR4'          = [PSCustomObject]@{'Mode' = 'THOR'; 'Description' = ''}
			'THOR5'          = [PSCustomObject]@{'Mode' = 'THOR'; 'Description' = ''}
			'THOR8'          = [PSCustomObject]@{'Mode' = 'THOR'; 'Description' = ''}
			'THOR11'         = [PSCustomObject]@{'Mode' = 'THOR'; 'Description' = ''}
			'THOR16'         = [PSCustomObject]@{'Mode' = 'THOR'; 'Description' = ''}
			'THOR22'         = [PSCustomObject]@{'Mode' = 'THOR'; 'Description' = ''}
			'THOR25X4'       = [PSCustomObject]@{'Mode' = 'THOR'; 'Description' = ''}
			'THOR50X1'       = [PSCustomObject]@{'Mode' = 'THOR'; 'Description' = ''}
			'THOR50X2'       = [PSCustomObject]@{'Mode' = 'THOR'; 'Description' = ''}
			'THOR100'        = [PSCustomObject]@{'Mode' = 'THOR'; 'Description' = ''}
			'THRBX'          = [PSCustomObject]@{'Mode' = 'THRB'; 'Description' = ''}
			'THRBX1'         = [PSCustomObject]@{'Mode' = 'THRB'; 'Description' = ''}
			'THRBX2'         = [PSCustomObject]@{'Mode' = 'THRB'; 'Description' = ''}
			'THRBX4'         = [PSCustomObject]@{'Mode' = 'THRB'; 'Description' = ''}
			'THROB1'         = [PSCustomObject]@{'Mode' = 'THRB'; 'Description' = ''}
			'THROB2'         = [PSCustomObject]@{'Mode' = 'THRB'; 'Description' = ''}
			'THROB4'         = [PSCustomObject]@{'Mode' = 'THRB'; 'Description' = ''}
			'USB'            = [PSCustomObject]@{'Mode' = 'SSB'; 'Description' = 'Amplitude modulated voice telephony, upper-sideband, suppressed-carrier'}
			'VARA HF'        = [PSCustomObject]@{'Mode' = 'DYNAMIC'; 'Description' = 'Channel adaptive high-speed modem for HF'}
			'VARA SATELLITE' = [PSCustomObject]@{'Mode' = 'DYNAMIC'; 'Description' = 'Channel adaptive high-speed modem for satellite operations'}
			'VARA FM 1200'   = [PSCustomObject]@{'Mode' = 'DYNAMIC'; 'Description' = 'Channel adaptive high-speed modem for FM transceivers'}
			'VARA FM 9600'   = [PSCustomObject]@{'Mode' = 'DYNAMIC'; 'Description' = 'Channel adaptive high-speed modem for FM transceivers'}
		}
	}

	static [PSCustomObject] PropagationMode() {
		return [PSCustomObject]@{
			AS       = "Aircraft Scatter"
			AUE      = "Aurora-E"
			AUR      = "Aurora"
			BS       = "Back scatter"
			ECH      = "EchoLink"
			EME      = "Earth-Moon-Earth"
			ES       = "Sporadic E"
			F2       = "F2 Reflection"
			FAI      = "Field Aligned Irregularities"
			GWAVE    = "Ground Wave"
			INTERNET = "Internet-assisted"
			ION      = "Ionoscatter"
			IRL      = "IRLP"
			LOS      = "Line of Sight (includes transmission through obstacles such as walls)"
			MS       = "Meteor scatter"
			RPT      = "Terrestrial or atmospheric repeater or transponder"
			RS       = "Rain scatter"
			SAT      = "Satellite"
			TEP      = "Trans-equatorial"
			TR       = "Tropospheric ducting"
		}
	}

	# Primary Administrative Subdivision's can SMN. :)

	static [PSCustomObject] EQSL_AG() {
		return [PSCustomObject]@{
			'Y' = 'confirmed and Authenticity Guaranteed by eQSL'
			'N' = 'confirmed but not Authenticity Guaranteed by eQSL'
			'U' = 'unknown'
		}
	}

	static [PSCustomObject] MorseKeyType() {
		return [PSCustomObject]@{
			'SK'  = 'Straight key'
			'SS'  = 'Sideswiper/Cootie key'
			'BUG' = 'Semi-automatic key/Bug'
			'FAB' = 'Fully automatic bug'
			'SP'  = 'Single-lever paddle'
			'DP'  = 'Double-lever paddle'
			'CPU' = 'Keyboard/CPU'
		}
	}

	static [PSCustomObject] QSLMedium() {
		return [PSCustomObject]@{
			CARD = "QSO confirmation via paper QSL card"
			EQSL = "QSO confirmation via eQSL.cc"
			LOTW = "QSO confirmation via ARRL Logbook of the World"
		}
	}

	static [PSCustomObject] QSLRcvd() {
		return [PSCustomObject]@{
			'Y' = [PSCustomObject]@{'Meaning' = 'yes (confirmed)'; 'Description' = 'An incoming QSL card has been received | The QSO has been confirmed by the online service'}
			'N' = [PSCustomObject]@{'Meaning' = 'no'; 'Description' = 'An incoming QSL card has not been received | The QSO has not been confirmed by the online service'}
			'R' = [PSCustomObject]@{'Meaning' = 'requested'; 'Description' = 'The logging station has requested a QSL card | The logging station has requested the QSO be uploaded to the online service'}
			'I' = [PSCustomObject]@{'Meaning' = 'ignore or invalid'; 'Description' = ''}
			'V' = [PSCustomObject]@{'Meaning' = 'verified'; 'Description' = 'DXCC award credit granted for the QSL card'}
		}
	}

	static [PSCustomObject] QSLSent() {
		return [PSCustomObject]@{
			'Y' = [PSCustomObject]@{'Meaning' = 'yes'; 'Description' = 'An outgoing QSL card has been sent | The QSO has been uploaded to, and accepted by, the online service'}
			'N' = [PSCustomObject]@{'Meaning' = 'no'; 'Description' = 'Do not send an outgoing QSL card | Do not upload the QSO to the online service'}
			'R' = [PSCustomObject]@{'Meaning' = 'requested'; 'Description' = 'The contacted station has requested a QSL card | The contacted station has requested the QSO be uploaded to the online service'}
			'Q' = [PSCustomObject]@{'Meaning' = 'queued'; 'Description' = 'An outgoing QSL card has been selected to be sent | A QSO has been selected to be uploaded to the online service'}
			'I' = [PSCustomObject]@{'Meaning' = 'ignore or invalid'; 'Description' = ''}
		}
	}

	static [PSCustomObject] QSLVia() {
		return [PSCustomObject]@{
			'B' = 'bureau'
			'D' = 'direct'
			'E' = 'electronic'
			'M' = 'manager'
		}
	}

	static [PSCustomObject] QSOComplete() {
		return [PSCustomObject]@{
			'Y'   = 'yes'
			'N'   = 'no'
			'NIL' = 'not heard'
			'?'   = 'uncertain'
		}
	}

	static [PSCustomObject] QSOUploadStatus() {
		return [PSCustomObject]@{
			'Y' = "The QSO has been uploaded to, and accepted by, the online service"
			'N' = "Do not upload the QSO to the online service"
			'M' = "The QSO has been modified since being uploaded to the online service"
		}
	}

	static [PSCustomObject] QSODownloadStatus() {
		return [PSCustomObject]@{
			'Y' = 'the QSO has been downloaded from the online service'
			'N' = 'the QSO has not been downloaded from the online service'
			'I' = 'ignore or invalid'
		}
	}

	# Secondary Administrative Subdivision's can SMN. :)

	# County/Region specific enums can SMN. :)

	static [PSCustomObject] SponsoredAward() {
		return [PSCustomObject]@{
			'ADIF_'  = 'ADIF Development Group'
			'ARI_'   = 'ARI - l''Associazione Radioamatori Italiani'
			'ARRL_'  = 'ARRL - American Radio Relay League'
			'CQ_'    = 'CQ Magazine'
			'DARC_'  = 'DARC - Deutscher Amateur-Radio-Club e.V.'
			'EQSL_'  = 'eQSL'
			'IARU_'  = 'IARU - International Amateur Radio Union'
			'JARL_'  = 'JARL - Japan Amateur Radio League'
			'RSGB_'  = 'RSGB - Radio Society of Great Britain'
			'TAG_'   = 'TAG - Tambov award group'
			'WABAG_' = 'WAB - Worked all Britain'
		}
	}

	static [PSCustomObject] HeaderFields() {
		return [PSCustomObject]@{
			'ADIF_VER'          = [PSCustomObject]@{ 'DataType' = 'String'; 'Enumeration' = ''; 'Description' = 'identifies the version of ADIF used in this file in the format X.Y.Z where:`n- X is an integer designating the ADIF epoch`n- Y is an integer between 0 and 9 designating the major version`n- Z is an integer between 0 and 9 designating the minor version' }
			'CREATED_TIMESTAMP' = [PSCustomObject]@{ 'DataType' = 'String'; 'Enumeration' = ''; 'Description' = 'identifies the UTC date and time that the file was created in the format of 15 characters YYYYMMDD HHMMSS where:`n- YYYYMMDD is a Date data type`n- HHMMSS is a 6 character Time data type' }
			'PROGRAMID'         = [PSCustomObject]@{ 'DataType' = 'String'; 'Enumeration' = ''; 'Description' = 'identifies the name of the logger, converter, or utility that created or processed this ADIF file' }
			'PROGRAMVERSION'    = [PSCustomObject]@{ 'DataType' = 'String'; 'Enumeration' = ''; 'Description' = 'identifies the version of the logger, converter, or utility that created or processed this ADIF file' }
			'USERDEFn'          = [PSCustomObject]@{ 'DataType' = 'String'; 'Enumeration' = ''; 'Description' = 'specifies the name and optional enumeration or range of the nth user-defined field, where n is a positive integer.`n`nThe name of a user-defined field may not be an ADIF Field name`nThe name of a user-defined field may not contain:`n- a comma`n-a colon`n- an open-angle-bracket or close-angle-bracket character`n- an open-curly-bracket or close-curly-bracket character`nThe name of a user-defined field may not begin or end with a space character.' }
		}
	}

	static [PSCustomObject] QSOFields() {
		return [PSCustomObject]@{
			'ADDRESS'                    = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'MultilineString'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's complete mailing address: full name, street address, city, postal code, and country" }
			'ADDRESS_INTL'               = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'IntlMultilineString'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's complete mailing address: full name, street address, city, postal code, and country" }
			'AGE'                        = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Number'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's operator's age in years in the range 0 to 120 (inclusive)" }
			'ALTITUDE'                   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Number'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the height of the contacted station in meters relative to Mean Sea Level (MSL)." }
			'ANT_AZ'                     = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Number'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "The logging station's antenna azimuth, in degrees with a value between 0 to 360 (inclusive).� Values outside this range are import-only and must be normalized for export (e.g. 370 is exported as 10). True north is 0 degrees with values increasing in a clockwise direction." }
			'ANT_EL'                     = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Number'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "The logging station's antenna elevation, in degrees with a value between -90 to 90 (inclusive).� Values outside this range are import-only and must be normalized for export (e.g. 100 is exported as 80). The horizon is 0 degrees with values increasing as the angle moves in an upward direction." }
			'ANT_PATH'                   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'AntPath'; 'secondary' = ''}; 'Description' = "the signal path" }
			'ARRL_SECT'                  = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'ARRLSection '; 'secondary' = ''}; 'Description' = "the contacted station's ARRL section" }
			'AWARD_SUBMITTED'            = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'SponsoredAwardList'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'SponsoredAward'; 'secondary' = ''}; 'Description' = "the list of awards submitted to a sponsor. Note that this field might not be used in a QSO record.� It might be used to convey information about a user's 'Award Account' between an award sponsor and the user.�" }
			'AWARD_GRANTED'              = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'SponsoredAwardList'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'SponsoredAward'; 'secondary' = ''}; 'Description' = "the list of awards granted by a sponsor. Note that this field might not be used in a QSO record.� It might be used to convey information about a user's 'Award Account' between an award sponsor and the user.�" }
			'A_INDEX'                    = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Number'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the geomagnetic A index at the time of the QSO in the range 0 to 400 (inclusive)" }
			'BAND'                       = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'Band'; 'secondary' = ''}; 'Description' = "QSO Band" }
			'BAND_RX'                    = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'Band'; 'secondary' = ''}; 'Description' = "in a split frequency QSO, the logging station's receiving band" }
			'CALL'                       = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's callsign" }
			'CHECK'                      = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "contest check (e.g. for ARRL Sweepstakes)" }
			'CLASS'                      = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "contest class (e.g. for ARRL Field Day)" }
			'CLUBLOG_QSO_UPLOAD_DATE'    = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Date'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the date the QSO was last uploaded to the Club Log online service" }
			'CLUBLOG_QSO_UPLOAD_STATUS'  = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'QSOUploadStatus'; 'secondary' = ''}; 'Description' = "the upload status of the QSO on the Club Log online service" }
			'CNTY'                       = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's Secondary Administrative Subdivision (e.g. US county, JA Gun), in the specified format " }
			'CNTY_ALT'                   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'SecondarySubdivisionListAlt'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's Secondary Administrative Subdivision alternate list" }
			'COMMENT'                    = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "comment field for QSO" }
			'COMMENT_INTL'               = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'IntlString'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "comment field for QSO" }
			'CONT'                       = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'Continent'; 'secondary' = ''}; 'Description' = "the contacted station's Continent" }
			'CONTACTED_OP'               = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the callsign of the individual operating the contacted station" }
			'CONTEST_ID'                 = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'ContestID'; 'secondary' = ''}; 'Description' = "QSO Contest Identifier" }
			'COUNTRY'                    = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's DXCC entity name" }
			'COUNTRY_INTL'               = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'IntlString'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's DXCC entity name" }
			'CQZ'                        = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'PositiveInteger'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's CQ Zone in the range 1 to 40 (inclusive)" }
			'CREDIT_SUBMITTED'           = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'CreditList'; 'secondary' = 'AwardList' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'Credit'; 'secondary' = 'Award'}; 'Description' = "the list of credits sought for this QSO" }
			'CREDIT_GRANTED'             = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'CreditList'; 'secondary' = 'AwardList' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'Credit'; 'secondary' = 'Award'}; 'Description' = "the list of credits granted to this QSO" }
			'DARC_DOK'                   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's DARC DOK (District Location Code)" }
			'DCL_QSLRDATE'               = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Date'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "date QSL received from DCL" }
			'DCL_QSLSDATE'               = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Date'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "date QSL sent to DCL" }
			'DCL_QSL_RCVD'               = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'QSLRcvd'; 'secondary' = ''}; 'Description' = "DCL QSL received status" }
			'DCL_QSL_SENT'               = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'QSLSent'; 'secondary' = ''}; 'Description' = "DCL QSL sent status" }
			'DISTANCE'                   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Number'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the distance between the logging station and the contacted station in kilometers via the specified signal path with a value greater than or equal to 0" }
			'DXCC'                       = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'DXCCEntityCode'; 'secondary' = ''}; 'Description' = "the contacted station's DXCC Entity Code" }
			'EMAIL'                      = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's email address" }
			'EQ_CALL'                    = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's owner's callsign" }
			'EQSL_AG'                    = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'EQSL_AG'; 'secondary' = ''}; 'Description' = "the contacted station's eQSL Authenticity Guaranteed status" }
			'EQSL_QSLRDATE'              = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Date'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "date QSL received from eQSL.cc" }
			'EQSL_QSLSDATE'              = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Date'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "date QSL sent to eQSL.cc" }
			'EQSL_QSL_RCVD'              = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'QSLRcvd'; 'secondary' = ''}; 'Description' = "eQSL.cc QSL received status" }
			'EQSL_QSL_SENT'              = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'QSLSent'; 'secondary' = ''}; 'Description' = "eQSL.cc QSL sent status" }
			'FISTS'                      = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'PositiveInteger'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's FISTS CW Club member number with a value greater than 0." }
			'FISTS_CC'                   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'PositiveInteger'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's FISTS CW Club Century Certificate (CC) number with a value greater than 0." }
			'FORCE_INIT'                 = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Boolean'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "new EME 'initial'" }
			'FREQ'                       = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Number'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "QSO frequency in Megahertz" }
			'FREQ_RX'                    = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Number'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "in a split frequency QSO, the logging station's receiving frequency in Megahertz" }
			'GRIDSQUARE'                 = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'GridSquare'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's 2-character, 4-character, 6-character, or 8-character Maidenhead Grid Square" }
			'GRIDSQUARE_EXT'             = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'GridSquareExt'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "for a contacted station's 10-character Maidenhead locator, supplements the GRIDSQUARE field by containing characters 9 and 10.� For a contacted station's 12-character Maidenhead locator, supplements the GRIDSQUARE field by containing characters 9, 10, 11 and 12." }
			'GUEST_OP'                   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "import-only: use OPERATOR instead" }
			'HAMLOGEU_QSO_UPLOAD_DATE'   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Date'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the date the QSO was last uploaded to the HAMLOG.EU online service" }
			'HAMLOGEU_QSO_UPLOAD_STATUS' = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'QSOUploadStatus'; 'secondary' = ''}; 'Description' = "the upload status of the QSO on the HAMLOG.EU online service" }
			'HAMQTH_QSO_UPLOAD_DATE'     = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Date'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the date the QSO was last uploaded to the HamQTH.com online service" }
			'HAMQTH_QSO_UPLOAD_STATUS'   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'QSOUploadStatus'; 'secondary' = ''}; 'Description' = "the upload status of the QSO on the HamQTH.com online service" }
			'HRDLOG_QSO_UPLOAD_DATE'     = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Date'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the date the QSO was last uploaded to the HRDLog.net online service" }
			'HRDLOG_QSO_UPLOAD_STATUS'   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'QSOUploadStatus'; 'secondary' = ''}; 'Description' = "the upload status of the QSO on the HRDLog.net online service" }
			'IOTA'                       = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'IOTARefNo'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's IOTA designator, in format CC-XXX, where" }
			'IOTA_ISLAND_ID'             = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'PositiveInteger'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's IOTA Island Identifier, an 8-digit integer in the range 1 to 99999999 [leading zeroes optional]" }
			'ITUZ'                       = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'PositiveInteger'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's ITU zone in the range 1 to 90 (inclusive)" }
			'K_INDEX'                    = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Integer'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the geomagnetic K index at the time of the QSO in the range 0 to 9 (inclusive)" }
			'LAT'                        = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Location'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's latitude" }
			'LON'                        = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Location'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's longitude" }
			'LOTW_QSLRDATE'              = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Date'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "date QSL received from ARRL Logbook of the World" }
			'LOTW_QSLSDATE'              = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Date'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "date QSL sent to ARRL Logbook of the World" }
			'LOTW_QSL_RCVD'              = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'QSLRcvd'; 'secondary' = ''}; 'Description' = "ARRL Logbook of the World QSL received status" }
			'LOTW_QSL_SENT'              = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'QSLSent'; 'secondary' = ''}; 'Description' = "ARRL Logbook of the World QSL sent status" }
			'MAX_BURSTS'                 = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Number'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "maximum length of meteor scatter bursts heard by the logging station, in seconds with a value greater than or equal to 0" }
			'MODE'                       = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'Mode'; 'secondary' = ''}; 'Description' = "QSO Mode" }
			'MORSE_KEY_INFO'             = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "a description of the logging station's Morse key" }
			'MORSE_KEY_TYPE'             = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'MorseKeyType'; 'secondary' = ''}; 'Description' = "the type of Morse key used by the logging station" }
			'MS_SHOWER'                  = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "For Meteor Scatter QSOs, the name of the meteor shower in progress" }
			'MY_ALTITUDE'                = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Number'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the height of the logging station in meters relative to Mean Sea Level (MSL)." }
			'MY_ANTENNA'                 = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the logging station's antenna" }
			'MY_ANTENNA_INTL'            = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'IntlString'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the logging station's antenna" }
			'MY_ARRL_SECT'               = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'ARRLSection'; 'secondary' = ''}; 'Description' = "the logging station's ARRL section" }
			'MY_CITY'                    = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the logging station's city" }
			'MY_CITY_INTL'               = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'IntlString'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the logging station's city" }
			'MY_CNTY'                    = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the logging station's Secondary Administrative Subdivision (e.g. US county, JA Gun), in the specified format" }
			'MY_CNTY_ALT'                = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'SecondarySubdivisionListAlt'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the logging station's Secondary Administrative Subdivision alternate list" }
			'MY_COUNTRY'                 = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'Country'; 'secondary' = ''}; 'Description' = "the logging station's DXCC entity name" }
			'MY_COUNTRY_INTL'            = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'IntlString'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'Country'; 'secondary' = ''}; 'Description' = "the logging station's DXCC entity name" }
			'MY_CQ_ZONE'                 = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'PositiveInteger'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the logging station's CQ Zone in the range 1 to 40 (inclusive)" }
			'MY_DARC_DOK'                = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the logging station's DARC DOK (District Location Code)" }
			'MY_DXCC'                    = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'DXCCEntityCode'; 'secondary' = ''}; 'Description' = "the logging station's DXCC Entity Code" }
			'MY_FISTS'                   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'PositiveInteger'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the logging station's FISTS CW Club member number with a value greater than 0." }
			'MY_GRIDSQUARE'              = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'GridSquare'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the logging station's 2-character, 4-character, 6-character, or 8-character Maidenhead Grid Square" }
			'MY_GRIDSQUARE_EXT'          = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'GridSquareExt'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "for a logging station's 10-character Maidenhead locator, supplements the MY_GRIDSQUARE field by containing characters 9 and 10.� For a logging station's 12-character Maidenhead locator, supplements the MY_GRIDSQUARE field by containing characters 9, 10, 11 and 12." }
			'MY_IOTA'                    = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'IOTARefNo'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the logging station's IOTA designator, in format CC-XXX, where" }
			'MY_IOTA_ISLAND_ID'          = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'PositiveInteger'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the logging station's IOTA Island Identifier, an 8-digit integer in the range 1 to 99999999 [leading zeroes optional]" }
			'MY_ITU_ZONE'                = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'PositiveInteger'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the logging station's ITU zone in the range 1 to 90 (inclusive)" }
			'MY_LAT'                     = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Location'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the logging station's latitude" }
			'MY_LON'                     = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Location'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the logging station's longitude" }
			'MY_MORSE_KEY_INFO'          = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "a description of the logging station's Morse key" }
			'MY_MORSE_KEY_TYPE'          = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'MorseKeyType'; 'secondary' = ''}; 'Description' = "the type of Morse key used by the logging station" }
			'MY_NAME'                    = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the logging operator's name" }
			'MY_NAME_INTL'               = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'IntlString'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the logging operator's name" }
			'MY_POSTAL_CODE'             = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the logging station's postal code" }
			'MY_POSTAL_CODE_INTL'        = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'IntlString'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the logging station's postal code" }
			'MY_POTA_REF'                = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'POTARefList'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "a comma-delimited list of one or more of the logging station's POTA (Parks on the Air) reference(s)." }
			'MY_RIG'                     = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "description of the logging station's equipment" }
			'MY_RIG_INTL'                = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'IntlString'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "description of the logging station's equipment" }
			'MY_SIG'                     = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "special interest activity or event" }
			'MY_SIG_INTL'                = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'IntlString'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "special interest activity or event" }
			'MY_SIG_INFO'                = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "special interest activity or event information" }
			'MY_SIG_INFO_INTL'           = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'IntlString'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "special interest activity or event information" }
			'MY_SOTA_REF'                = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'SOTARef'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the logging station's International SOTA Reference." }
			'MY_STATE'                   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the code for the logging station's Primary Administrative Subdivision (e.g. US State, JA Island, VE Province)" }
			'MY_STREET'                  = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the logging station's street" }
			'MY_STREET_INTL'             = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'IntlString'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the logging station's street" }
			'MY_USACA_COUNTIES'          = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'SecondarySubdivisionList'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "two US counties in the case where the logging station is located on a border between two counties, representing counties that the contacted station may claim for the CQ Magazine USA-CA award program.� E.g." }
			'MY_VUCC_GRIDS'              = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'GridSquareList'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "two or four adjacent Maidenhead grid locators, each four characters long, representing the logging station's grid squares that the contacted station may claim for the ARRL VUCC award program.� E.g." }
			'MY_WWFF_REF'                = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'WWFFRef'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the logging station's WWFF (World Wildlife Flora & Fauna) reference" }
			'NAME'                       = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's operator's name" }
			'NAME_INTL'                  = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'IntlString'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's operator's name" }
			'NOTES'                      = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'MultilineString'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "QSO notes" }
			'NOTES_INTL'                 = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'IntlMultilineString'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "QSO notes" }
			'NR_BURSTS'                  = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Integer'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the number of meteor scatter bursts heard by the logging station with a value greater than or equal to 0" }
			'NR_PINGS'                   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Integer'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the number of meteor scatter pings heard by the logging station with a value greater than or equal to 0" }
			'OPERATOR'                   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the logging operator's callsign" }
			'OWNER_CALLSIGN'             = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the callsign of the owner of the station used to log the contact (the" }
			'PFX'                        = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's WPX prefix" }
			'POTA_REF'                   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'POTARefList'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "a comma-delimited list of one or more of the contacted station's POTA (Parks on the Air) reference(s)." }
			'PRECEDENCE'                 = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "contest precedence (e.g. for ARRL Sweepstakes)" }
			'PROP_MODE'                  = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'PropagationMode'; 'secondary' = ''}; 'Description' = "QSO propagation mode" }
			'PUBLIC_KEY'                 = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "public encryption key" }
			'QRZCOM_QSO_DOWNLOAD_DATE'   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Date'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the date the QSO was last downloaded from the QRZ.COM online service" }
			'QRZCOM_QSO_DOWNLOAD_STATUS' = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'QSODownloadStatus'; 'secondary' = ''}; 'Description' = "the download status of the QSO from the QRZ.COM online service" }
			'QRZCOM_QSO_UPLOAD_DATE'     = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Date'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the date the QSO was last uploaded to the QRZ.COM online service" }
			'QRZCOM_QSO_UPLOAD_STATUS'   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'QSOUploadStatus'; 'secondary' = ''}; 'Description' = "the upload status of the QSO on the QRZ.COM online service" }
			'QSLMSG'                     = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'MultilineString'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "QSL card message" }
			'QSLMSG_INTL'                = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'IntlMultilineString'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "QSL card message" }
			'QSLMSG_RCVD'                = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'MultilineString'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "QSL card message received" }
			'QSLRDATE'                   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Date'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "QSL received date" }
			'QSLSDATE'                   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Date'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "QSL sent date" }
			'QSL_RCVD'                   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'QSLRcvd'; 'secondary' = ''}; 'Description' = "QSL received status" }
			'QSL_RCVD_VIA'               = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'QSLVia'; 'secondary' = ''}; 'Description' = "if QSL_RCVD is set to 'Y' or 'V', the means by which the QSL was received by the logging station; otherwise, the means by which the logging station requested or intends to request that the QSL be conveyed.� (Note: 'V' is import-only)" }
			'QSL_SENT'                   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'QSLSent'; 'secondary' = ''}; 'Description' = "QSL sent status" }
			'QSL_SENT_VIA'               = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'QSLVia'; 'secondary' = ''}; 'Description' = "if QSL_SENT is set to 'Y', the means by which the QSL was sent by the logging station; otherwise, the means by which the logging station intends to convey the QSL" }
			'QSL_VIA'                    = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's QSL route" }
			'QSO_COMPLETE'               = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'QSOComplete'; 'secondary' = ''}; 'Description' = "indicates whether the QSO was complete from the perspective of the logging station" }
			'QSO_DATE'                   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Date'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "date on which the QSO started" }
			'QSO_DATE_OFF'               = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Date'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "date on which the QSO ended" }
			'QSO_RANDOM'                 = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Boolean'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "indicates whether the QSO was random or scheduled" }
			'QTH'                        = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's city" }
			'QTH_INTL'                   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'IntlString'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's city" }
			'REGION'                     = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's WAE or CQ entity contained within a DXCC entity." }
			'RIG'                        = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'MultilineString'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "description of the contacted station's equipment" }
			'RIG_INTL'                   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'IntlMultilineString'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "description of the contacted station's equipment" }
			'RST_RCVD'                   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "signal report from the contacted station" }
			'RST_SENT'                   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "signal report sent to the contacted station" }
			'RX_PWR'                     = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Number'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's transmitter power in Watts with a value greater than or equal to 0" }
			'SAT_MODE'                   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "satellite mode - a code representing the satellite's uplink band and downlink band" }
			'SAT_NAME'                   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "name of satellite" }
			'SFI'                        = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Integer'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the solar flux at the time of the QSO in the range 0 to 300 (inclusive)." }
			'SIG'                        = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the name of the contacted station's special activity or interest group" }
			'SIG_INTL'                   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'IntlString'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the name of the contacted station's special activity or interest group" }
			'SIG_INFO'                   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "information associated with the contacted station's activity or interest group" }
			'SIG_INFO_INTL'              = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'IntlString'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "information associated with the contacted station's activity or interest group" }
			'SILENT_KEY'                 = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Boolean'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "'Y' indicates that the contacted station's operator is now a Silent Key." }
			'SKCC'                       = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's Straight Key Century Club (SKCC) member information" }
			'SOTA_REF'                   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'SOTARef'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's International SOTA Reference." }
			'SRX'                        = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Integer'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "contest QSO received serial number with a value greater than or equal to 0" }
			'SRX_STRING'                 = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "contest QSO received information" }
			'STATE'                      = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Enumeration'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the code for the contacted station's Primary Administrative Subdivision (e.g. US State, JA Island, VE Province)" }
			'STATION_CALLSIGN'           = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the logging station's callsign (the callsign used over the air)" }
			'STX'                        = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Integer'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "contest QSO transmitted serial number with a value greater than or equal to 0" }
			'STX_STRING'                 = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "contest QSO transmitted information" }
			'SUBMODE'                    = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = 'Submode'; 'secondary' = ''}; 'Description' = "QSO Submode" }
			'SWL'                        = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Boolean'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "indicates that the QSO information pertains to an SWL report" }
			'TEN_TEN'                    = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'PositiveInteger'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "Ten-Ten number with a value greater than 0" }
			'TIME_OFF'                   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Time'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "HHMM or HHMMSS in UTC" }
			'TIME_ON'                    = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Time'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "HHMM or HHMMSS in UTC" }
			'TX_PWR'                     = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'Number'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the logging station's power in Watts with a value greater than or equal to 0" }
			'UKSMG'                      = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'PositiveInteger'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's UKSMG member number with a value greater than 0" }
			'USACA_COUNTIES'             = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'SecondarySubdivisionList'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "two US counties in the case where the contacted station is located on a border between two counties, representing counties credited to the QSO for the CQ Magazine USA-CA award program.� E.g." }
			'VE_PROV'                    = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "import-only: use STATE instead" }
			'VUCC_GRIDS'                 = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'GridSquareList'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "two or four adjacent Maidenhead grid locators, each four characters long, representing the contacted station's grid squares credited to the QSO for the ARRL VUCC award program.� E.g." }
			'WEB'                        = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'String'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's URL" }
			'WWFF_REF'                   = [PSCustomObject]@{ 'DataType' = [PSCustomObject]@{ 'primary' = 'WWFFRef'; 'secondary' = '' }; 'Enumeration' = [PSCustomObject]@{'primary' = ''; 'secondary' = ''}; 'Description' = "the contacted station's WWFF (World Wildlife Flora & Fauna) reference" }
		}
	}

	static [String] PowerADIFVersion() {
		return '1.0.0'
	}

	ADIFEnumerations() {}
}

class  ADIFTokenObject {
	[string]$Field
	[string]$DataType
	[string]$Value
	[string]$Comment
	[void] Init([String]$Field, [String]$DataType, [String]$Value, [String]$Comment) {
		$this.Field = $Field
		$this.DataType = $DataType
		$this.Value = $Value
		$this.Comment = $Comment
	}
	ADIFTokenObject() {
		$this.Init("","","","")
	}
	ADIFTokenObject([String]$Field, [String]$DataType, [String]$Value, [String]$Comment) {
		$this.Init($Field, $DataType, $Value, $Comment)
	}
}

class ADIFTokenInstance : ADIFTokenObject {
	hidden [string]$LengthString
	hidden [int]$ValueLength
	hidden [int]$ReadLength
	hidden [bool]$Complete
	[void] Init([String]$Field, [String]$DataType, [String]$Value, [String]$Comment, [String]$LengthString, [Int]$ValueLength, [Int]$ReadLength, [Bool]$Complete) {
		$this.Init($Field, $DataType, $Value, $Comment)
		$this.LengthString = $LengthString
		$this.ValueLength = $ValueLength
		$this.ReadLength = $ReadLength
		$this.Complete = $Complete
	}
	ADIFTokenInstance() {
		$this.Init("", "", "", "", "", "", 0, $false)
	}
	ADIFTokenInstance([String]$Field, [String]$DataType, [String]$Value, [String]$Comment) {
		$this.Init($Field, $DataType, $Value, $Comment, [String]$Value.Length, $Value.Length, $Value.Length, $true)
	}
}

class ADIFTokenizer {
	# Class Props
	hidden [TokenizerState]$State
	[ADIFTokenInstance[]]$Tokens
	hidden [string]$ADIF
	hidden [int]$Index
	hidden [bool]$DebugTokenizer

	[void] Transition([TokenizerState]$NewState) {
		$this.State = $NewState
	}

	[ADIFTokenInstance] StateMethod_None([ADIFTokenInstance]$CurrentToken, [Char]$Character) {
		switch($Character) {
			('<') {
				$this.Transition([TokenizerState]::FieldName)
			}
		}
		return $CurrentToken
	}

	[ADIFTokenInstance] StateMethod_FieldName([ADIFTokenInstance]$CurrentToken, [Char]$Character) {
		switch($Character) {
			':' {
				#$CurrentToken.Field = $CurrentToken.Field.ToUpper()
				$this.Transition([TokenizerState]::FieldLength)
			}
			'>' {
				#$CurrentToken.Field = $CurrentToken.Field.ToUpper()
				$CurrentToken.Complete = $true
				$this.Transition([TokenizerState]::None)
			}
			default {
				$CurrentToken.Field += $Character
			}
		}
		return $CurrentToken
	}

	[ADIFTokenInstance] StateMethod_FieldLength([ADIFTokenInstance]$CurrentToken, [Char]$Character) {
		switch($Character) {
			('>') {
				$CurrentToken.ValueLength = [int]($CurrentToken.LengthString)
				$this.Transition([TokenizerState]::Value)
			}
			(':') {
				$CurrentToken.ValueLength = [int]($CurrentToken.LengthString)
				$this.Transition([TokenizerState]::FieldDataType)
			}
			default {
				$CurrentToken.LengthString += $Character
			}
		}
		return $CurrentToken
	}

	[ADIFTokenInstance] StateMethod_FieldDataType([ADIFTokenInstance]$CurrentToken, [Char]$Character) {
		switch($Character) {
			('>') {
				$this.Transition([TokenizerState]::Value)
			}
			default {
				$CurrentToken.DataType += $Character
			}
		}
		return $CurrentToken
	}

	[ADIFTokenInstance] StateMethod_Value([ADIFTokenInstance]$CurrentToken, [Char]$Character) {
		$CurrentToken.Value += $Character
		$CurrentToken.ReadLength += 1
		if(([int]($CurrentToken.ReadLength) -eq [int]($CurrentToken.ValueLength)) -or ([int]($CurrentToken.ValueLength) -eq 0)) {
			$this.Transition([TokenizerState]::Comment)
		}
		return $CurrentToken
	}

	[ADIFTokenInstance] StateMethod_Comment([ADIFTokenInstance]$CurrentToken, [Char]$Character) {
		switch($Character) {
			('<') {
				$CurrentToken.Complete = $true
				$this.Transition([TokenizerState]::FieldName)
			}
			default {
				$CurrentToken.Comment += $Character
			}
		}
		return $CurrentToken
	}

	[ADIFTokenInstance] ProcessNext([ADIFTokenInstance]$CurrentToken, [char]$Character) {
		if($this.DebugTokenizer) {
			[Char]$CurrentChar = $Character

			[String]$Hex = [System.String]::Format("0x{0:X}", [int]$CurrentChar).PadRight(4, ' ')

			if (($CurrentChar -lt 32 ) -or ($CurrentChar -gt 126)) {
				$CurrentChar = ' '
			}

			[String]$CurrentState = "$($this.State)".PadRight(15, ' ')

			[String]$LengthString = "LengthString: $($CurrentToken.LengthString)".PadRight(20, ' ')

			[String]$LengthInt    = "Length: $($CurrentToken.ValueLength)".PadRight(15, ' ')

			[String]$ReadLength		= "ReadLength: $($CurrentToken.ReadLength)".PadRight(20, ' ')

			Write-Host "$CurrentState ($CurrentChar | $Hex)      $LengthString $LengthInt $ReadLength"
		}
		$CurrentToken = $this."StateMethod_$($this.State)"($CurrentToken, $Character)
		$this.Index++
		return $CurrentToken
	}

	[void] ProcessAll() {
		if ($this.DebugTokenizer) {
			$this.ProcessAllDebug()
		} else {
			$this.ProcessAllFast()
		}
	}

	hidden [void] ProcessAllDebug() {
		$TokenList = [System.Collections.Generic.List[ADIFTokenInstance]]::new()
		$Token = [ADIFTokenInstance]::new()
		while ($this.Index -lt $this.ADIF.Length) {
			$Token = $this.ProcessNext($Token, $this.ADIF[$this.Index])
			if ($Token.Complete) {
				$TokenList.Add($Token)
				$Token = [ADIFTokenInstance]::new()
			}
		}
		$this.Tokens = $TokenList.ToArray()
	}

	hidden [void] ProcessAllFast() {
		# Inlined state machine — same logic as the StateMethod_* methods,
		# but avoids per-character dynamic method dispatch overhead.
		# Hot class properties are copied to locals to avoid repeated
		# property resolution on every loop iteration.
		$TokenList = [System.Collections.Generic.List[ADIFTokenInstance]]::new()
		$Token     = [ADIFTokenInstance]::new()
		$src       = $this.ADIF
		$src = $src
		$srcLen    = $src.Length
		$ix        = $this.Index
		$st        = $this.State

		while ($ix -lt $srcLen) {
			$c = $src[$ix]

			switch ($st) {
				([TokenizerState]::None) {
					if ($c -eq '<') { $st = [TokenizerState]::FieldName }
				}
				([TokenizerState]::FieldName) {
					switch ($c) {
						':'     { $st = [TokenizerState]::FieldLength }
						'>'     {
							$Token.Complete = $true
							$st = [TokenizerState]::None
						}
						default { $Token.Field += $c }
					}
				}
				([TokenizerState]::FieldLength) {
					switch ($c) {
						'>'     {
							$Token.ValueLength = [int]$Token.LengthString
							# Bulk-read the entire value with Substring instead of per-char loop
							if ($Token.ValueLength -gt 0) {
								$Token.Value = $src.Substring($ix + 1, $Token.ValueLength)
								$Token.ReadLength = $Token.ValueLength
								$ix += $Token.ValueLength
							}
							$st = [TokenizerState]::Comment
						}
						':'     { $Token.ValueLength = [int]$Token.LengthString; $st = [TokenizerState]::FieldDataType }
						default { $Token.LengthString += $c }
					}
				}
				([TokenizerState]::FieldDataType) {
					if ($c -eq '>') {
						# Bulk-read the entire value with Substring instead of per-char loop
						if ($Token.ValueLength -gt 0) {
							$Token.Value = $src.Substring($ix + 1, $Token.ValueLength)
							$Token.ReadLength = $Token.ValueLength
							$ix += $Token.ValueLength
						}
						$st = [TokenizerState]::Comment
					}
					else { $Token.DataType += $c }
				}
				([TokenizerState]::Comment) {
					if ($c -eq '<') {
						$Token.Complete = $true
						$st = [TokenizerState]::FieldName
					} else {
						$Token.Comment += $c
					}
				}
			}

			if ($Token.Complete) {
				$TokenList.Add($Token)
				$Token = [ADIFTokenInstance]::new()
			}

			$ix++
		}

		$this.Index  = $ix
		$this.State  = $st
		$this.Tokens = $TokenList.ToArray()
	}

	[void] Init([String]$Data, [bool]$RunNow, [bool]$DebugTokenizer) {
		$this.State = [TokenizerState]::None
		$this.ADIF = $Data
		$this.Index = 0
		$this.DebugTokenizer = $DebugTokenizer
		if($RunNow) {
			$this.ProcessAll()
		}
	}

	[void] SetTokens([ADIFTokenInstance[]]$Tokens) {
		$this.Tokens = $Tokens
	}

	[String] GetADIF() {
		$sb = [System.Text.StringBuilder]::new("ADIF Export from PowerADIF $([ADIFEnumerations]::PowerADIFVersion())`n")
		foreach($Token in $this.Tokens) {
			[void]$sb.Append('<')
			[void]$sb.Append($Token.Field)
			if($Token.ValueLength) {
				[void]$sb.Append(':')
				[void]$sb.Append($Token.ValueLength)
			}
			if($Token.DataType) {
				[void]$sb.Append(':')
				[void]$sb.Append($Token.DataType)
			}
			[void]$sb.Append('>')
			[void]$sb.Append($Token.Value)
			[void]$sb.Append($Token.Comment)
		}
		$this.ADIF = $sb.ToString()
		return $this.ADIF
	}

	ADIFTokenizer([string]$Data, [bool]$RunNow, [bool]$DebugTokenizer) {
		$this.Init($Data, $RunNow, $DebugTokenizer)
	}

	ADIFTokenizer([string]$Data, [bool]$RunNow) {
		$this.Init($Data, $RunNow, $false)
	}

	ADIFTokenizer([string]$Data) {
		$this.Init($Data, $true, $false)
	}

	ADIFTokenizer() {
		$this.Init("", $false, $false)
	}
}

class ADIFRecord {
	hidden [System.Collections.Hashtable]$DataTypes
	hidden [System.Collections.Hashtable]$Comments

	[void] AddField([string]$Field, [string]$Value, [string]$FieldDataType, [string]$Comment) {
		$this.PSObject.Properties.Add([PSNoteProperty]::new($Field, $Value))
		if($FieldDataType) {
			$this.DataTypes[$Field] = $FieldDataType
		}
		if($Comment) {
			$this.Comments[$Field] = $Comment
		}
	}

	[void] AddField([string]$Field, [string]$Value) {
		$this.AddField($Field,$Value,"","")
	}

	ADIFRecord() {
		$this.DataTypes = @{}
		$this.Comments = @{}
	}
}

class ADIFStructure {
 	[ADIFRecord]$Header
 	[ADIFRecord[]]$Records
 	hidden [bool]$HeaderParsed
	hidden [ADIFTokenObject[]]$Tokens

	ADIFStructure([ADIFTokenInstance[]]$Tokens) {
		$this.Header = [ADIFRecord]::new()
		$this.HeaderParsed = $false
		$this.Tokens = $Tokens
	}

	[ADIFTokenInstance[]] Tokenize() {
		$TokenList = [System.Collections.Generic.List[ADIFTokenInstance]]::new()

		$ParseHeader = ($this.Header | Get-Member -MemberType NoteProperty)
		foreach($Field in $ParseHeader) {
			$TokenList.Add([ADIFTokenInstance]::New($Field.Name, $this.Header.DataTypes[$Field.Name], $this.Header."$($Field.Name)", $this.Header.Comments[$Field.Name]))
		}
		$TokenList.Add([ADIFTokenInstance]::New("EOH","","","`n"))

		foreach($Record in $this.Records) {
			$ParseRecord = ($Record | Get-Member -MemberType NoteProperty)
			foreach ($Field in $ParseRecord) {
				$TokenList.Add([ADIFTokenInstance]::New($Field.Name, $Record.DataTypes[$Field.Name], $Record."$($Field.Name)", $Record.Comments[$Field.Name]))
			}
			$TokenList.Add([ADIFTokenInstance]::New("EOR","","","`n"))
		}

		return $TokenList.ToArray()
	}
}

<#
	.SYNOPSIS
			Converts ADIF data into tokenized objects.

	.DESCRIPTION
			This function tokenizes ADIF (Amateur Data Interchange Format) data into structured objects.

	.PARAMETER ADIF_DATA
			The raw ADIF data as a string.

	.PARAMETER DebugTokenizer
			Enables debugging output for the tokenizer.

	.EXAMPLE
			'...ADIF data...' | ConvertTo-ADIFTokens

	.OUTPUTS
			ADIFTokenObject[]
#>
function ConvertTo-ADIFTokens {
	param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[String]$ADIF_DATA,
		[Switch]$DebugTokenizer
	)
	process {
		[ADIFTokenizer]$ADIFTokenizer = [ADIFTokenizer]::new($ADIF_DATA, $true, $DebugTokenizer)
		return [ADIFTokenObject[]]$ADIFTokenizer.Tokens
	}
}

<#
	.SYNOPSIS
			Converts tokenized ADIF objects back into ADIF format.

	.DESCRIPTION
			This function reconstructs ADIF data from tokenized ADIF objects.

	.PARAMETER Tokens
			An array of ADIFTokenObject instances.

	.EXAMPLE
			$Tokens | ConvertFrom-ADIFTokens

	.OUTPUTS
			String (ADIF formatted data)
#>
function ConvertFrom-ADIFTokens {
	param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[ADIFTokenObject[]]$Tokens
	)
	process {
		[ADIFTokenizer]$ADIFTokenizer = [ADIFTokenizer]::new()
		$ADIFTokenizer.SetTokens($Tokens)
		return $ADIFTokenizer.GetADIF()
	}
}

<#
	.SYNOPSIS
			Parses raw ADIF data into a structured object.

	.DESCRIPTION
			Converts ADIF data into an ADIFStructure object containing headers and records.

	.PARAMETER ADIF_DATA
			The raw ADIF data as a string.

	.EXAMPLE
			'...ADIF data...' | ConvertFrom-ADIF

	.OUTPUTS
			ADIFStructure
#>
function ConvertFrom-ADIF {
	param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[String]$ADIF_DATA
	)
	process {
		[ADIFTokenInstance[]]$Tokens = ConvertTo-ADIFTokens -ADIF_DATA $ADIF_DATA

		[ADIFStructure]$ADIF = [ADIFStructure]::new($Tokens)

		$RecordList = [System.Collections.Generic.List[ADIFRecord]]::new()
		[ADIFRecord]$Record = [ADIFRecord]::new()

		foreach ($Token in $Tokens) {
			if($ADIF.HeaderParsed) {
				if($Token.Field -eq "EOR") {
					$RecordList.Add($Record)
					$Record = [ADIFRecord]::new()
				} else {
					$Record.AddField($Token.Field, $Token.Value, $Token.DataType, $Token.Comment)
				}
			} else {
				if($Token.Field -eq "EOH") {
					$ADIF.HeaderParsed = $true
				} else {
					$ADIF.Header.AddField($Token.Field, $Token.Value, $Token.DataType, $Token.Comment)
				}
			}
		}
		$ADIF.Records = $RecordList.ToArray()

		return [ADIFStructure]$ADIF
	}
}

<#
	.SYNOPSIS
			Converts an ADIFStructure object to raw ADIF format.

	.DESCRIPTION
			Tokenizes and converts an ADIFStructure object into a string representation of ADIF.

	.PARAMETER ADIF
			An ADIFStructure object containing header and record information.

	.EXAMPLE
			$ADIF | ConvertTo-ADIF

	.OUTPUTS
			String (ADIF formatted data)
#>
function ConvertTo-ADIF {
	param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[ADIFStructure]$ADIF
	)
	process {
		$Tokenizer = [ADIFTokenizer]::New()
		$Tokens = $ADIF.Tokenize()
		$Tokenizer.SetTokens($Tokens)
		return $Tokenizer.GetADIF()
	}
}

<#
	.SYNOPSIS
			Imports an ADIF file and converts it to an ADIFStructure object.

	.DESCRIPTION
			Reads an ADIF file from disk and converts its contents into a structured ADIF representation.

	.PARAMETER Path
			The file path of the ADIF file to be imported.

	.EXAMPLE
			Import-ADIF -Path "C:\Users\User\log.adif"

	.OUTPUTS
			ADIFStructure
#>
function Import-ADIF {
	param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[String]$Path
	)
	process {
		$RawADIF = Get-Content $Path -Raw
		return $RawADIF | ConvertFrom-ADIF
	}
}

<#
	.SYNOPSIS
			Exports an ADIFStructure object to a file.

	.DESCRIPTION
			Converts an ADIFStructure object into ADIF format and saves it to a specified file path.

	.PARAMETER ADIF
			The ADIFStructure object to be exported.

	.PARAMETER Path
			The file path where the ADIF data will be saved.

	.EXAMPLE
			Export-ADIF -ADIF $MyADIF -Path "C:\Users\User\exported.adif"

	.OUTPUTS
			None
#>
function Export-ADIF {
	param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[ADIFStructure]$ADIF,
		[Parameter(Mandatory)]
		[String]$Path
	)
	process {
		$RawADIF = $ADIF | ConvertTo-ADIF
		$RawADIF | Set-Content -Path $Path
	}
}

<#
	.SYNOPSIS
			Retrieves ADIF enumerations.

	.DESCRIPTION
			Returns a list of ADIF enumerations available in the ADIF specification.

	.EXAMPLE
			Get-ADIFEnumerations

	.OUTPUTS
			ADIFEnumerations
#>
function Get-ADIFEnumerations {
	return [ADIFEnumerations]
}

Export-ModuleMember -Function Import-ADIF
Export-ModuleMember -Function Export-ADIF
Export-ModuleMember -Function ConvertTo-ADIF
Export-ModuleMember -Function ConvertFrom-ADIF
Export-ModuleMember -Function ConvertTo-ADIFTokens
Export-ModuleMember -Function ConvertFrom-ADIFTokens
Export-ModuleMember -Function Get-ADIFEnumerations