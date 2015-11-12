#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
# Author: Oddvar Håland Moe, MSItPros.com
# Twitter: @oddvarmoe

$Version = "Version 1.4"

# Purpose of script:
# Enumerate all folders with drivers inside the 
# MDT Workbench and display them as driver packages
# in a GUI with checkbox
#
# Be able to select them and export them to file system
# 
# Portion of code is generated with primal forms (thanks)

# Version 1.1
# Established Version Control. :-)
# Multi select support

# Version 1.2
# Fixed some variables with 2x \\ in path
# Change Export finished dialog to display - name - name - name

# Version 1.3
# Add Browse to root Export folder on export button
# Asks for deploymentshare on start of script
# Published on MSItpros.com

# Version 1.4
# Fixed cancel button on first dialog (Select deployment share)
# Code cleanup
# Removed popup of successfull export to the very end of the script as suggested by Maik Koster
# Added Progressbar on export - NOT WORKING YET!

# TODO LIST:
# - Display in Checklist GUI - Change to Name - Name - Name
# - Recreate code to make it smaller (be a better coder)

#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

# Variables
[reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
$AskForMDTRoot = New-Object Windows.Forms.FolderBrowserDialog
$AskForMDTRoot.Description = "Choose the Root of your deployment Share"
$result = $AskForMDTRoot.ShowDialog( )

if($result -eq "OK")
{
    $MDTDSRoot = $AskForMDTRoot.SelectedPath
}
else
{
    exit
}

# Hard Coded Variables
$PSDriveName = "MDT001"
$MDTDriverRoot = "MDT001:\Out-Of-Box Drivers"


# Add MDT Snapin
Add-PSSnapIn Microsoft.BDD.PSSnapIn
New-PSDrive -Name "$PSDriveName" -PSProvider MDTProvider -Root $MDTDSRoot -ErrorAction SilentlyContinue


# FUNCTIONS STARTS HERE

Function Export ($ParentPathOfDrivers, $DestinationPath, $DriverPackage)
# Example something MDT001:\Out-Of-Box Drivers\Windows 7 X64\Dell\Latitude E6530\* , C:\Temp, \Windows 7 X64\Dell\Latitude E6530
{
    $DriverPackagePath = $DestinationPath+$DriverPackage
    $Drivers = get-item $ParentPathOfDrivers

    #check if destintation Path exists and create if missing!
    if (!(Test-Path -path $DestinationPath$DriverPackage)) 
    {
        New-Item $DestinationPath$DriverPackage -Type Directory
    }

    $Drivers | foreach{
        
        $DriverPhysicalPath = $_.GetPhysicalSourcePath()
        $DriverFolder = (Get-Item $DriverPhysicalPath).PSParentPath
 
        # 19 = Out-of-box Drivers
        $FilterStart = ($DriverPhysicalPath.IndexOf("Out-of-box Drivers"))+19
        $DriverParent = $DriverPhysicalPath.substring($FilterStart)
        $DriverParent = $DriverParent.Substring(0,($DriverParent.LastIndexOf("\")))
        $DriverExportPath = $DriverPackagePath+"\"+$DriverParent
  
        if (!(Test-Path -path $DriverExportPath))
        {
            Copy-item $DriverFolder $DriverExportPath -recurse -ErrorAction SilentlyContinue
        }
        # else{[System.Windows.Forms.MessageBox]::Show($DriverExportPath + "Exists, skipping")}
    }
}

# Generated Form Function
function GenerateForm 
{

    # Import the Assemblies
    [reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
    [reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null


    # Generated Form Objects
    $form1 = New-Object System.Windows.Forms.Form
    $Exportbutton = New-Object System.Windows.Forms.Button
    $Cancelbutton = New-Object System.Windows.Forms.Button
    $checkedListBox1 = New-Object System.Windows.Forms.CheckedListBox
    $InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState
    $progressbar = New-Object System.Windows.Forms.ProgressBar


    # Event Script Blocks
    $Cancelbutton_OnClick= 
    {
        remove-psdrive $PSDriveName
        $Form1.Close()
    }

    $Exportbutton_OnClick= 
    {
        # Check if anything is selected
        if ($checkedListBox1.CheckedItems.Count -eq 0) 
        {
            [System.Windows.Forms.MessageBox]::Show("Nothing Selected.Click cancel to close application or mark a driverpackage for export")
        }
        else
        {
            # Create and show browse for folder
            $ExportRootFolder = New-Object Windows.Forms.FolderBrowserDialog
            $ExportRootFolder.Description = "Choose your Root folder for export. Subfolders will be created as needed"
            $ExportRootFolder.ShowDialog( )
   
            if ($ExportRootFolder.SelectedPath -eq "") 
            {
                # Cancel was clicked
            }
            else
            {
                ###[System.Windows.Forms.MessageBox]::Show($checkedListBox1.CheckedItems.Count)
                $progressbar.Maximum = $checkedListBox1.CheckedItems.Count
                $progressbar.Step = 1
                $progressbar.Value = 0
                
                $checkedListBox1.CheckedItems | foreach{
                    ##$progressbar.PerformStep()
                    ##$form1.Refresh()
                    $Driverpackage = $MDTDriverRoot+$_+"\*"
                    # [System.Windows.Forms.MessageBox]::Show($DriverPackage+","+$ExportRootFolder+","+$_)
                    Export $DriverPackage $ExportRootFolder.SelectedPath $_
                    $progressbar.PerformStep()
                    $form1.Refresh()
                }
            # Export is done
            [System.Windows.Forms.MessageBox]::Show('Export of selected driverpackages is done!')
            remove-psdrive $PSDriveName
            $Form1.Close()
            }
        }
    }


    $OnLoadForm_StateCorrection=
    {
        # Correct the initial state of the form to prevent the .Net maximized form issue
	    $form1.WindowState = $InitialFormWindowState
    }

    #----------------------------------------------
    # Generated Form Code
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 561
    $System_Drawing_Size.Width = 584
    $form1.ClientSize = $System_Drawing_Size
    $form1.DataBindings.DefaultDataSourceUpdateMode = 0
    $form1.Name = "form1"
    $form1.Text = "MDT Driver Exporter - MSitPros.com Edition - "+$Version

    # Export Button
    $Exportbutton.DataBindings.DefaultDataSourceUpdateMode = 0

    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 442
    $System_Drawing_Point.Y = 511
    $Exportbutton.Location = $System_Drawing_Point
    $Exportbutton.Name = "Exportbutton"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 23
    $System_Drawing_Size.Width = 75
    $Exportbutton.Size = $System_Drawing_Size
    $Exportbutton.TabIndex = 2
    $Exportbutton.Text = "Export"
    $Exportbutton.UseVisualStyleBackColor = $True
    $Exportbutton.add_Click($Exportbutton_OnClick)


    $form1.Controls.Add($Exportbutton)

    # Cancel button
    $Cancelbutton.DataBindings.DefaultDataSourceUpdateMode = 0

    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 59
    $System_Drawing_Point.Y = 511
    $Cancelbutton.Location = $System_Drawing_Point
    $Cancelbutton.Name = "Cancelbutton"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 23
    $System_Drawing_Size.Width = 75
    $Cancelbutton.Size = $System_Drawing_Size
    $Cancelbutton.TabIndex = 1
    $Cancelbutton.Text = "Cancel"
    $Cancelbutton.UseVisualStyleBackColor = $True
    $Cancelbutton.add_Click($Cancelbutton_OnClick)

    $form1.Controls.Add($Cancelbutton)

    # Progress bar
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 159
    $System_Drawing_Point.Y = 511
    $progressbar.Location = $System_Drawing_Point
    $progressbar.Name = "Progressbar"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 23
    $System_Drawing_Size.Width = 250
    $progressbar.Size = $System_Drawing_Size

    $form1.Controls.Add($progressbar)

    # Get MDT Driver folders
    $items = get-childitem $MDTDriverRoot -Recurse

    # Create an empty Array to work with
    $CheckBoxArray = @()

    # Add "Checkboxes" to array

    foreach ($item in $items){ 
        if($item.nodetype -eq 'Driver') 
        {
            $SplitVariable = ($item.PSParentPath).SubString(62)
            $CheckBoxArray += $SplitVariable
        }
    }

    $checkedListBox1.DataBindings.DefaultDataSourceUpdateMode = 0
    $checkedListBox1.FormattingEnabled = $True

    # Only select unique packages in array
    $CheckBoxArray = $CheckBoxArray | sort -Unique
    
    # Add checkboxes to CheckedListBox object
    foreach($Checkbox in $CheckBoxArray){
        $checkedListBox1.Items.Add($Checkbox)|Out-Null
    }

    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 12
    $System_Drawing_Point.Y = 1
    $checkedListBox1.Location = $System_Drawing_Point
    $checkedListBox1.Name = "checkedListBox1"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 484
    $System_Drawing_Size.Width = 560
    $checkedListBox1.Size = $System_Drawing_Size
    $checkedListBox1.TabIndex = 0

    $form1.Controls.Add($checkedListBox1)

    # Save the initial state of the form
    $InitialFormWindowState = $form1.WindowState

    # Init the OnLoad event to correct the initial state of the form
    $form1.add_Load($OnLoadForm_StateCorrection)

    # Show the Form
    $form1.ShowDialog()| Out-Null

} #End Function

#Call the Function
GenerateForm
