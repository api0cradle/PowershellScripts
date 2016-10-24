#Author: Oddvar Moe - msitpros.com
#USB Stick production SE-test
#Excel needs to be installed on machine running script
#Creates an Excel Cheat with tracking mecanishm
#Example in script uses New Company Organization

# REMEMBER TO CHANGE $pictureURL and line 81 where to point click url.

# Place to generate content
$RootFolder = "C:\tempfolder"

# Number to Generate
$NumberOfMemsticks = 20

# Filename to be placed on USB Stick
$filename = "New Organization-Draft_1.0-withComments.xlsx"

#Path to USB Stick
$USBstickDrive = "E:\"

# Excel Constants
# MsoTriState
Set-Variable msoFalse 0 -Option Constant -ErrorAction SilentlyContinue
Set-Variable msoTrue 1 -Option Constant -ErrorAction SilentlyContinue

function Pause
{
    #Used to pause the script to change USB stick between copy job
    Read-Host 'Insert next USB stick and then press Enter to continue…' | Out-Null
}


#Loop variable
$i = 1
do
{
    #URL from where you load picture
    $pictureURL = "http://msitpros.com/tracker$i.jpg"
    
    write-host $pictureURL
    $subfolder = "$RootFolder\$i"
    mkdir $subfolder
    cd $subfolder
    
    #Code borrowed from Scripting Guy - Thanx
    # cell width and height in points
    Set-Variable cellWidth 10 -Option Constant -ErrorAction SilentlyContinue
    Set-Variable cellHeight 10 -Option Constant -ErrorAction SilentlyContinue
    
     
    $xl = New-Object -ComObject Excel.Application -Property @{
     Visible = $true
     DisplayAlerts = $false
    }
    
    $wb = $xl.WorkBooks.Add()
    $sh = $wb.Sheets.Item(‘Sheet1’)
    
    # arguments to insert the image through the Shapes.AddPicture Method
    $LinkToFile = $msoTrue
    $SaveWithDocument = $msoTrue
    
    # Place picture at Column GS-ish to hide it
    $Left = $cellWidth * 10000
    $Top = $cellHeight * 1
    $Width = $cellWidth * 10
    $Height = $cellHeight * 10
    
    # add the image to the Sheet
    $img = $sh.Shapes.AddPicture($PictureURL, $LinkToFile, $SaveWithDocument, $Left, $Top, $Width, $Height)
    
    # add trick text
    #Number 1 is vertical
    #Number 2 is horizontal
    $sh.Cells.Item(1,1)="Content moved to Internal Sharepoint site"
    $sh.Cells.Item(1,1).font.size = 18
    $sh.Cells.Item(1,1).font.bold = $true
    
    $range = $xl.Range("A2")
    # Fake link to measure if the user clicks
    $sh.Hyperlinks.Add($range,"http://8.8.8.8/$i/neworg.xls","","http://sharepoint.msitpros.com/organizationchart","LINK")
    $sh.Cells.item(2,1).font.bold = $true
    $sh.Cells.item(2,1).font.size = 22
    
    #Increase size of document
    $range2 = $sh.Range("A3","Z1000")
    $range2.Font.Bold = $true
    
    $file = "$subfolder\$filename"
    $xl.ActiveWorkbook.SaveAs($file)
    
    $wb.Close($false)
    $xl.Quit()
    
    $i++ 
}
until ($i -gt $NumberOfMemsticks)


# Copy to USB stick and remove temporary file
$ii = 1
do
{
    $subfolder = "$RootFolder\$ii"
    $file = "$subfolder\$filename"

    Copy-Item $file $USBstickDrive
    Remove-Item $subfolder -Force -Recurse
    pause
    $ii++
}
until ($ii -gt $NumberOfMemsticks)
