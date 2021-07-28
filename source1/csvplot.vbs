dim validArguments
validArguments = true
If WScript.Arguments.Count < 4 Then
  validArguments = false 'missing input, output, width or height
End If
If WScript.Arguments.Count < 6 Then
  validArguments = false 'missing at least a serie
End If
If WScript.Arguments.Count mod 2 <> 0 Then
  validArguments = false 'a serie is missing a column index
End If
If validArguments = false Then
  Wscript.Echo "CSVPLOT v1.0"
  Wscript.Echo "Usage: csvplot.vbs inputCsvFilePath outputImageFilePath width height serie1 serie2 serie3 ..."
  Wscript.Echo "       where a serie is defined by two column index (starting at 1) within the CVS file."
  Wscript.Echo "       ie: csvplot.vbs test.csv test.slx 1 2 1 3"
  Wscript.Echo "Note:  The application assumes that the first row of all columns is the column's title."
  Wscript.Quit
End If

'Extract input and output filenames
dim inputFilePath
dim outputFilePath
dim imageWidth
dim imageHeight
inputFilePath   = WScript.Arguments.Item(0)
outputFilePath  = WScript.Arguments.Item(1)
imageWidth      = CInt(WScript.Arguments.Item(2))
imageHeight     = CInt(WScript.Arguments.Item(3))

'
'Excel constants definition:
'
'XlDirection enumeration: https://msdn.microsoft.com/en-us/library/office/microsoft.office.interop.excel.xldirection.aspx
const xlDown    = -4121
const xlToLeft  = -4159
const xlToRight = -4161
const xlUp      = -4162

'XlChartType enumeration: https://msdn.microsoft.com/en-us/library/office/microsoft.office.interop.excel.xlcharttype.aspx
const xlXYScatterLines = 77
const xlXYScatterLinesNoMarkers = 75
const xlLineMarkers = 65

'XlChartLocation enumeration: https://msdn.microsoft.com/en-us/library/office/microsoft.office.interop.excel.xlchartlocation.aspx
const xlLocationAsNewSheet = 1
const xlLocationAsObject = 2

const xlCategory = 1
const xlPrimary = 1
const xlValue = 2
const vbFormatStandard = 1
const vbFormatText     = 2
const vbFormatDate     = 4
const xlDelimited      = 1
const xlDoubleQuote    = 1

'Excel SaveAs file formats
const EXCEL_FILEFORMAT_XLS  = 51
const EXCEL_FILEFORMAT_XLSX = -4143

Dim xlApp, xlBook

Set xlApp = CreateObject("Excel.Application")
Wscript.Echo "Loading input file " & inputFilePath & "..."

'http://stackoverflow.com/questions/12961835/vbscript-to-import-csv-into-excel
'change according to number/type of the fields in your CSV
dataTypes = Array( Array(1, vbFormatText) _
  , Array(2, vbFormatStandard) _
  , Array(3, vbFormatText) _
  , Array(4, vbFormatDate) _
)

'set xlBook = xlApp.WorkBooks.Open(inputFilePath)
xlApp.Workbooks.OpenText inputFilePath, , , xlDelimited, xlDoubleQuote, False, False, True, , , , dataTypes
set xlBook = xlApp.ActiveWorkbook

Wscript.Echo "File load successful."
Wscript.Echo "File has " & xlApp.ActiveSheet.UsedRange.Columns.Count & " columns."

'Prevent showing popups to the user
xlApp.DisplayAlerts = False

'Plot a graph for ....
CreateNewEmptyChart xlApp 

'loop through all series
dim i
For i = 4 to WScript.Arguments.Count - 1 Step 2
  dim xColumnIndex
  dim yColumnIndex
  xColumnIndex = CInt(WScript.Arguments.Item(i))
  yColumnIndex = CInt(WScript.Arguments.Item(i+1))
  Wscript.Echo "Plotting series of columns " & xColumnIndex & " and " & yColumnIndex & "..."
  
  CreateChartSerie xlApp, xColumnIndex, yColumnIndex
Next

'Optimise chart axes
OptimizeChartUnitAxes(xlApp)

'Save active chart as an image
Dim success 'As Boolean
success = SaveActiveChartAsPng(xlApp, outputFilePath, imageWidth, imageHeight)

'DEBUG: Save the generated chart to an XLS file for debugging purpose.
'xlBook.SaveAs outputFilePath&".xls", EXCEL_FILEFORMAT_XLS

xlBook.Close false 'SaveChanges=False
xlApp.Quit

'deallocate
set xlSht  = Nothing
Set xlBook = Nothing
Set xlApp = Nothing

If success Then
  Wscript.Echo "File " & outputFilePath & " saved successfully."
  
Else
  Wscript.Echo "Failed saving file " & outputFilePath & "!"
End If



'
'Creates a new empty Chart on the current active sheet
'
Sub CreateNewEmptyChart(xlApp)
  xlApp.ActiveSheet.Shapes.AddChart.Select 
  xlApp.ActiveChart.ChartType = xlXYScatterLinesNoMarkers
  xlApp.ActiveChart.ChartStyle = 42 
  xlApp.ActiveChart.SeriesCollection.NewSeries
  
  'Delete any series that Excel might have automaticaly created for us
  'msgbox "xlApp.ActiveChart.SeriesCollection.Count=" & xlApp.ActiveChart.SeriesCollection.Count
  While xlApp.ActiveChart.SeriesCollection.Count <> 0
    xlApp.ActiveChart.SeriesCollection(1).Delete
  Wend
  'msgbox "xlApp.ActiveChart.SeriesCollection.Count=" & xlApp.ActiveChart.SeriesCollection.Count
End Sub

'
'Gets the title of a given column on the ActiveSheet
'
Function GetColumnTitle(xlApp, columnIndex)
  GetColumnTitle = xlApp.ActiveSheet.Columns(columnIndex).Rows(1).Value
End Function

'
'Gets the range of a column on the ActiveSheet which contains a title as first row
' ie: "=Sheet1!$A$2:$A$37"
'
Function GetColumnRange(xlApp, columnIndex)
  dim str
  str = "='" & xlApp.ActiveSheet.Name & "'!"
  
  'Find the address of the second row of the given column
  str = str & xlApp.ActiveSheet.Columns(columnIndex).Rows(2).Address 'rows 1 is the column's title
  
  str = str & ":"
  
  'Find the address of the last row of the given column
  str = str & xlApp.ActiveSheet.Columns(columnIndex).End(xlDown).Address 'rows 1 is the column's title
  
  GetColumnRange = str
End Function

'
'Add a new serie in the current ActiveChart in the current ActiveSheet
'Note that function assumes that first row is column's title.
'
Sub CreateChartSerie(xlApp, xColumnIndex, yColumnIndex)
  xlApp.ActiveChart.SeriesCollection.NewSeries
  
  dim serieIndex
  serieIndex = xlApp.ActiveChart.SeriesCollection.Count
  
  dim serieName
  serieName = GetColumnTitle(xlApp, yColumnIndex)
  
  dim serieValues
  serieValues = GetColumnRange(xlApp, yColumnIndex)
  
  dim serieXValues
  serieXValues = GetColumnRange(xlApp, xColumnIndex)
  
  xlApp.ActiveChart.SeriesCollection(serieIndex).Name = serieName
  xlApp.ActiveChart.SeriesCollection(serieIndex).Values = serieValues
  xlApp.ActiveChart.SeriesCollection(serieIndex).XValues = serieXValues
End Sub

'
'Modifies the current ActiveChart in the current ActiveSheet
'to get the minimum size axes.
'
Sub OptimizeChartUnitAxes(xlApp)
  'Find best X axis
  dim minX
  dim serieMinX
  dim maxX
  dim serieMaxX
  minX =  9999999999999999
  maxX = -9999999999999999
  for i = 1 to xlApp.ActiveChart.SeriesCollection.Count
    serieMinX = xlApp.WorksheetFunction.Min( xlApp.ActiveChart.SeriesCollection(i).XValues )
    serieMaxX = xlApp.WorksheetFunction.Max( xlApp.ActiveChart.SeriesCollection(i).XValues )
    if serieMinX < minX then
      minX = serieMinX
    end if
    if serieMaxX > maxX then
      maxX = serieMaxX
    end if
  next
  
  'msgbox minX
  'msgbox maxX
  
  'Find best Y axis
  dim minY
  dim serieMinY
  dim maxY
  dim serieMaxY
  minY =  9999999999999999
  maxY = -9999999999999999
  for i = 1 to xlApp.ActiveChart.SeriesCollection.Count
    serieMinY = xlApp.WorksheetFunction.Min( xlApp.ActiveChart.SeriesCollection(i).Values )
    serieMaxY = xlApp.WorksheetFunction.Max( xlApp.ActiveChart.SeriesCollection(i).Values )
    if serieMinY < minY then
      minY = serieMinY
    end if
    if serieMaxY > maxY then
      maxY = serieMaxY
    end if
  next
  
  'msgbox minY
  'msgbox maxY
  
  'Apply scale minimum and maximum
  xlApp.ActiveChart.Axes(xlCategory).MinimumScale = minX 
  xlApp.ActiveChart.Axes(xlCategory).MaximumScale = maxX
  xlApp.ActiveChart.Axes(xlValue).MinimumScale = minY 
  xlApp.ActiveChart.Axes(xlValue).MaximumScale = maxY 
  
  'Ask Excel to compute MajorUnit for X and Y axes
  xlApp.ActiveChart.Axes(xlValue).MajorUnitIsAuto = True
  xlApp.ActiveChart.Axes(xlCategory).MajorUnitIsAuto = True
  
  'Compute better axes limits
  minX = Floor(minX, xlApp.ActiveChart.Axes(xlCategory).MajorUnit)
  maxX = Ceiling(maxX, xlApp.ActiveChart.Axes(xlCategory).MajorUnit)
  minY = Floor(minY, xlApp.ActiveChart.Axes(xlValue).MajorUnit)
  maxY = Ceiling(maxY, xlApp.ActiveChart.Axes(xlValue).MajorUnit)
  
  'Apply scale minimum and maximum (again)
  xlApp.ActiveChart.Axes(xlCategory).MinimumScale = minX
  xlApp.ActiveChart.Axes(xlCategory).MaximumScale = maxX
  xlApp.ActiveChart.Axes(xlValue).MinimumScale = minY-1
  xlApp.ActiveChart.Axes(xlValue).MaximumScale = maxY+1
  
  xlApp.ActiveChart.Axes(xlCategory).HasTitle=True
  xlApp.ActiveChart.Axes(xlCategory).AxisTitle.Characters.Text = "Time"
  xlApp.ActiveChart.Axes(xlValue).HasTitle=True
  xlApp.ActiveChart.Axes(xlValue).AxisTitle.Characters.Text = "%"
  xlApp.ActiveChart.HasTitle = True
  xlApp.ActiveChart.ChartTitle.Text="Remaining Battery Charge Variation"
  xlApp.ActiveChart.Axes(xlCategory).HasMajorGridlines = True
  xlApp.ActiveChart.Axes(xlCategory).HasMinorGridlines = True
  xlApp.ActiveChart.Axes(xlValue).HasMajorGridlines = True
  xlApp.ActiveChart.Axes(xlValue).HasMinorGridlines = True
  
End Sub

'
'Saves the current ActiveChart to a PNG image
' imageWidth:   Width of the image
' imageHeight:  Hwight of the image
'
Function SaveActiveChartAsPng(xlApp, outputFilePath, imageWidth, imageHeight) 'As Boolean
  'Save current dimension of the ActiveChart
  Dim currentWidth
  Dim currentHeight
  currentWidth = xlApp.ActiveChart.Parent.Width
  currentHeight = xlApp.ActiveChart.Parent.Height
  
  'Resize chart to desired resolution
  xlApp.ActiveChart.Parent.Width = Pixels2Points(imageWidth)
  xlApp.ActiveChart.Parent.Height = Pixels2Points(imageHeight)
  
  'Delete existing file
  On Error Resume Next
  Kill outputFilePath
  On Error GoTo 0
  
  SaveActiveChartAsPng = xlApp.ActiveChart.Export(outputFilePath, "PNG", False)
  
  'Restore chart's dimension
  xlApp.ActiveChart.Parent.Width = currentWidth
  xlApp.ActiveChart.Parent.Height = currentHeight
End Function

Function Points2Pixels(points)
  Dim pixels: pixels = 1.3333 * points + 0.6667
  Points2Pixels = pixels
End Function

Function Pixels2Points(pixels)
  Dim points: points = 0.75 * pixels - 0.5
  Pixels2Points = points
End Function

'http://stackoverflow.com/questions/1776001/ceiling-function-in-access
'Public Function Ceiling(ByVal X As Double, Optional ByVal Factor As Double = 1) As Double
Public Function Ceiling(X, Factor)
  ' X is the value you want to round
  ' Factor is the optional multiple to which you want to round, defaulting to 1
  Ceiling = (Int(X / Factor) - (X / Factor - Int(X / Factor) > 0)) * Factor
End Function

'Public Function Floor(ByVal X As Double, Optional ByVal Factor As Double = 1) As Double
Public Function Floor(X, Factor)
  ' X is the value you want to round
  ' is the multiple to which you want to round
  Floor = Int(X / Factor) * Factor
End Function

Set oShell = CreateObject ("Wscript.Shell") 
