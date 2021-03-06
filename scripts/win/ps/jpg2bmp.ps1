#http://gallery.technet.microsoft.com/scriptcenter/Resize-Image-File-f6dd4a56
Function Set-ImageSize
{
	[CmdletBinding(
    	SupportsShouldProcess=$True,
        ConfirmImpact="Low"
    )]		
	Param
	(
		[parameter(Mandatory=$true,
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true)]
		[Alias("PSImageSize")]	
		[String[]]$FullName,
		[String]$Destination = $(Get-Location),
		[Switch]$Overwrite,
		[Int]$WidthPx,
		[Int]$HeightPx,
		[Int]$DPIWidth,
		[Int]$DPIHeight,
		[Switch]$FixedSize,
		[Switch]$RemoveSource
	)

	Begin
	{
		[void][reflection.assembly]::LoadWithPartialName("System.Windows.Forms")
	}
	
	Process
	{

		Foreach($ImageFile in $FullName)
		{
			If(Test-Path $ImageFile)
			{
				$OldImage = new-object System.Drawing.Bitmap $ImageFile
				$OldWidth = $OldImage.Width
				$OldHeight = $OldImage.Height
				
				if($WidthPx -eq $Null)
				{
					$WidthPx = $OldWidth
				}
				if($HeightPx -eq $Null)
				{
					$HeightPx = $OldHeight
				}
				
				if($FixedSize)
				{
					$NewWidth = $WidthPx
					$NewHeight = $HeightPx
				}
				else
				{
					if($OldWidth -lt $OldHeight)
					{
						$NewWidth = $WidthPx
						[int]$NewHeight = [Math]::Round(($NewWidth*$OldHeight)/$OldWidth)
						
						if($NewHeight -gt $HeightPx)
						{
							$NewHeight = $HeightPx
							[int]$NewWidth = [Math]::Round(($NewHeight*$OldWidth)/$OldHeight)
						}
					}
					else
					{
						$NewHeight = $HeightPx
						[int]$NewWidth = [Math]::Round(($NewHeight*$OldWidth)/$OldHeight)
						
						if($NewWidth -gt $WidthPx)
						{
							$NewWidth = $WidthPx
							[int]$NewHeight = [Math]::Round(($NewWidth*$OldHeight)/$OldWidth)
						}						
					}
				}

				$ImageProperty = Get-ItemProperty $ImageFile				
				$SaveLocation = Join-Path -Path $Destination -ChildPath ($ImageProperty.Name)

				If(!$Overwrite)
				{
					If(Test-Path $SaveLocation)
					{
						$Title = "A file already exists: $SaveLocation"
							
						$ChoiceOverwrite = New-Object System.Management.Automation.Host.ChoiceDescription "&Overwrite"
						$ChoiceCancel = New-Object System.Management.Automation.Host.ChoiceDescription "&Cancel"
						$Options = [System.Management.Automation.Host.ChoiceDescription[]]($ChoiceCancel, $ChoiceOverwrite)		
						If(($host.ui.PromptForChoice($Title, $null, $Options, 1)) -eq 0)
						{
							Write-Verbose "Image '$ImageFile' exist in destination location - skiped"
							Continue
						} #End If ($host.ui.PromptForChoice($Title, $null, $Options, 1)) -eq 0
					} #End If Test-Path $SaveLocation
				} #End If !$Overwrite	
				
				$NewImage = new-object System.Drawing.Bitmap $NewWidth,$NewHeight

				$Graphics = [System.Drawing.Graphics]::FromImage($NewImage)
				$Graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
				$Graphics.DrawImage($OldImage, 0, 0, $NewWidth, $NewHeight) 

				$ImageFormat = $OldImage.RawFormat
				$OldImage.Dispose()
				if($DPIWidth -and $DPIHeight)
				{
					$NewImage.SetResolution($DPIWidth,$DPIHeight)
				} #End If $DPIWidth -and $DPIHeight
				
				$NewImage.Save($SaveLocation,$ImageFormat)
				$NewImage.Dispose()
				Write-Verbose "Image '$ImageFile' was resize from $($OldWidth)x$($OldHeight) to $($NewWidth)x$($NewHeight) and save in '$SaveLocation'"
				
				If($RemoveSource)
				{
					Remove-Item $Image -Force
					Write-Verbose "Image source '$ImageFile' was removed"
				} #End If $RemoveSource
			}
		}

	} #End Process
	
	End{}
}

function jpgtobmp
{
    param(
			[
				parameter(Mandatory=$true,
				ValueFromPipeline=$true,
				ValueFromPipelineByPropertyName=$true)
			]
			[Alias("PSjpg2bmp")]
            [String[]]$imgSource = $(Throw "You have to specify a source path."),
            [String[]]$imgTarget = $(Throw "You have to specify a target path.")       
    )
	[void][reflection.assembly]::LoadWithPartialName("System.Windows.Forms")

	get-childitem $imgSource | foreach {
		$ext      = [System.IO.Path]::GetExtension($_.fullname).ToLower()
		$path     = [System.IO.Path]::GetDirectoryName($_.fullname)
		$baseName = [System.IO.Path]::GetFileNameWithoutExtension($_.fullname)
		if ( $ext.EndsWith("jpg") -or $ext.EndsWith("jpeg") ){
		    $img = new-object system.drawing.bitmap $_.fullname
	    	$img.save("$imgTarget\$baseName.bmp",[System.Drawing.Imaging.ImageFormat]::bmp)
			Get-ChildItem "$imgTarget\$baseName.bmp" | Set-ImageSize -Destination "$imgTarget\" -WidthPx 300 -HeightPx 375 -Verbose -Overwrite
		}
		else{
			Get-ChildItem "$path\$baseName.bmp" | Set-ImageSize -Destination "$imgTarget\" -WidthPx 300 -HeightPx 375 -Verbose -Overwrite
		}
	}
}

jpgtobmp -imgSource  "D:\RHDOCS\RHFOTOS\JPG\" -imgTarget "D:\RHDOCS\RHFOTOS\BMP\"