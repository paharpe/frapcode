VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} frmExport 
   Caption         =   "Export Outlook Items"
   ClientHeight    =   4290
   ClientLeft      =   45
   ClientTop       =   375
   ClientWidth     =   9585
   OleObjectBlob   =   "OUTLOOK_frmExport.frx":0000
   StartUpPosition =   1  'CenterOwner
End
Attribute VB_Name = "frmExport"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
Dim myFolder As Outlook.MAPIFolder



Private Sub cmdProcessFolder_Click()
Open "C:\Users\pharpe\Documents\temp\Mails.txt" For Output As #1
Call ProcessFolder(myFolder)
Close #1
End Sub

Private Sub cmdSelectFolder_Click()
Call Choose_Folder
End Sub



'This Code is Downloaded from OfficeTricks.com
'Visit this site for more such Free Code
Sub Download_Outlook_Mail_To_Excel()

Open "C:\Users\pharpe\documents\outmail.csv" For Output As #1

    'Add Tools->References->"Microsoft Outlook nn.n Object Library"
    'nn.n varies as per our Outlook Installation
    Dim Folder As Outlook.MAPIFolder
    Dim sFolders As Outlook.MAPIFolder
    Dim iRow As Integer, oRow As Integer
    Dim MailBoxName As String, Pst_Folder_Name  As String
    
    'Mailbox or PST Main Folder Name (As how it is displayed in your Outlook Session)
    MailBoxName = "servicedesk.overheid@kpn.com"
 
    'Mailbox Folder or PST Folder Name (As how it is displayed in your Outlook Session)
    Pst_Folder_Name = "03. Nagios meldingen"
 
    'To directly a Folder at a high level
    'Set Folder = Outlook.Session.Folders(MailBoxName).Folders(Pst_Folder_Name)
    
    'To access a main folder or a subfolder (level-1)
    For Each Folder In Outlook.Session.Folders(MailBoxName).Folders
        If VBA.UCase(Folder.Name) = VBA.UCase(Pst_Folder_Name) Then GoTo Label_Folder_Found
        For Each sFolders In Folder.Folders
            If VBA.UCase(sFolders.Name) = VBA.UCase(Pst_Folder_Name) Then
                Set Folder = sFolders
                GoTo Label_Folder_Found
            End If
        Next sFolders
    Next Folder
 
Label_Folder_Found:
     If Folder.Name = "" Then
        MsgBox "Invalid Data in Input"
        GoTo End_Lbl1:
    End If
 
    Folder.Items.Sort "Received"
        
        
    'Export eMail Data from PST Folder
    oRow = 1
    For iRow = 1 To Folder.Items.Count
        'If condition to import mails received in last 60 days
        'To import all emails, comment or remove this IF condition
        ' If VBA.DateValue(VBA.Now) - VBA.DateValue(Folder.Items.Item(iRow).ReceivedTime) <= 60 Then
          oRow = oRow + 1
          
          Print #1, Folder.Items.Item(iRow).Subject & " # " & Folder.Items.Item(iRow).ReceivedTime
          'ThisWorkbook.Sheets(1).Cells(oRow, 1).Select
          'ThisWorkbook.Sheets(1).Cells(oRow, 1) = Folder.Items.Item(iRow).SenderName
          'ThisWorkbook.Sheets(1).Cells(oRow, 2) = Folder.Items.Item(iRow).Subject
          'ThisWorkbook.Sheets(1).Cells(oRow, 3) = Folder.Items.Item(iRow).ReceivedTime
          'ThisWorkbook.Sheets(1).Cells(oRow, 4) = Folder.Items.Item(iRow).Size
          'ThisWorkbook.Sheets(1).Cells(oRow, 5) = Folder.Items.Item(iRow).SenderEmailAddress
          'ThisWorkbook.Sheets(1).Cells(oRow, 6) = Folder.Items.Item(iRow).Body
        'End If
    Next iRow
    MsgBox "Outlook Mails Extracted to Excel"
    Set Folder = Nothing
    Set sFolders = Nothing
    Close #1
    
End_Lbl1:
End Sub
 
Sub Choose_Folder()
 
Dim olApp As Outlook.Application
Dim objNS As Outlook.NameSpace
'Dim myFolder As Outlook.Folder

On Error Resume Next

Set olApp = Outlook.Application
Set objNS = olApp.GetNamespace("MAPI")
' Set objNS.Folders.GetFolder("03. Nagios meldingen")
Set myFolder = objNS.PickFolder

cmdProcessFolder.Enabled = False
txtFolder.Text = "Folder"

txtFolder.Text = myFolder.Name

If txtFolder.Text <> "Folder" Then
  cmdProcessFolder.Enabled = True
End If
     
'Call ProcessFolder(MyFolder)

Set objNS = Nothing
'Set MyFolder = Nothing
'Set olApp = Nothing
'Set objNS = Nothing
End Sub
 
 
Sub ProcessFolder(StartFolder As MAPIFolder)
Dim objFolder As Outlook.MAPIFolder
Dim objItem As Object
Dim mai As MailItem

Dim intItem_Counter As Integer
intItem_Counter = 0
  ' On Error Resume Next
  ' MsgBox StartFolder.Parent, , "testing"
    
  ' txtStatus.Text = StartFolder.Name
  frmExport.Repaint
    
  ' process all the items in this folder
  For Each objItem In StartFolder.Items
    If objItem.Sender <> "nagios-bld@kpn.com" Then
       Dim strDateTime_in As Variant
       Dim arDate_in As Variant
       
       Dim strDate_in As String
       Dim strDate_out As String
       
       Dim strDate_in_d As String
       Dim strDate_in_m As String
       Dim strDate_in_y As String
       
       Dim strTime_in As String
       
       
       strDateTime_in = Split(objItem.ReceivedTime, " ")
       strDate_in = strDateTime_in(0)
       
       arDate_in = Split(strDate_in, "-")
       
       strDate_in_d = arDate_in(0)
       If Val(strDate_in_d) < 10 Then
         strDate_in_d = "0" & strDate_in_d
       End If
       
       strDate_in_m = arDate_in(1)
       If Val(strDate_in_m) < 10 Then
         strDate_in_m = "0" & strDate_in_m
       End If
       
       
       strDate_in_y = arDate_in(2)
       
       strDate_out = strDate_in_y & "-" & strDate_in_m & "-" & strDate_in_d
       
       If UBound(strDateTime_in) = 0 Then
         strTime_in = "00:00:00"
       Else
         strTime_in = strDateTime_in(1)
     End If
    ' Print #1, objItem.Subject & " # " & strDate_out & " # " & strTime_in
     ' Print #1, objItem.Body & " # " & strDate_out & " # " & strTime_in
     
     Dim arBody() As String
     Dim strBody_Line As String
     Dim intIndex As Integer
     arBody() = Split(objItem.Body, ":")
     For intIndex = 0 To UBound(arBody)
       strBody_Line = Replace(arBody(intIndex), vbCrLf, "")
       strBody_Line = LTrim(strBody_Line)
       If Len(strBody_Line) < 1025 Then
       
         Print #1, LTrim(strBody_Line) & " # " & strDate_out & " # " & strTime_in
       End If
     Next intIndex
     Print #1, "-----------"
     
    intItem_Counter = intItem_Counter + 1
    txtStatus.Text = "Aantal : " & intItem_Counter
    DoEvents
    End If
  Next
        
  MsgBox "Done, all selected items (" + CStr(intItem_Counter) + ") exported."
        
  ' process all the subfolders of this folder
  For Each objFolder In StartFolder.Folders
    Call ProcessFolder(objFolder)
  Next
 
Set mai = Nothing
Set objFolder = Nothing
Set objItem = Nothing
txtStatus.Text = "Aantal : " & intItem_Counter
End Sub

Private Sub TextBox1_Change()

End Sub

Private Sub txtProgress_Change()

End Sub

Private Sub txtStatus_Change()

End Sub

Private Sub UserForm_Click()

End Sub

Private Sub UserForm_Initialize()
cmdProcessFolder.Enabled = False
End Sub
