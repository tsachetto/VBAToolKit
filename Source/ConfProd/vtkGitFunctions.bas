Attribute VB_Name = "vtkGitFunctions"
'---------------------------------------------------------------------------------------
' Module    : vtkGitHubFunctions
' Author    : Abdelfattah Lahbib
' Date      : 08/06/2013
' Purpose   : Interact with Git
'---------------------------------------------------------------------------------------

Option Explicit

'---------------------------------------------------------------------------------------
' Procedure : vtkInitializeGit
' Author    : Abdelfattah Lahbib
' Date      : 27/04/2013
' Purpose   : - Initialize Git in a directory using the "git init" command.
'               The directory path has to be absolute, and on the C: drive
'             - Optionally, writes the output of the "git init" command in a textfile
'               whose path has to be passed as parameter.
'               If the path is absolute, a drive other than C: will raise an error
'               If the path is relative, it will be considered as relatie to the folder path.
' Notes     : Returns
'               - VTK_OK
'               - VTK_WRONG_FOLDER_PATH
'               - VTK_FORBIDDEN_PARAMETER
'               - VTK_GIT_NOT_INSTALLED
'               - VTK_GIT_ALREADY_INITIALIZED_IN_FOLDER
'               - VTK_UNEXPECTED_ERR
'---------------------------------------------------------------------------------------
'
Public Function vtkInitializeGit(folderPath As String, Optional logFile As String = "")
    Dim FileInitPath As String
    Dim retShell As String
    Dim logFileDefaultName As String
    logFileDefaultName = "initialize.log"
    Dim logFileFullPath As String
 
    On Error GoTo vtkInitializeGit_Err
    
    If InStr(UCase(Environ("PATH")), UCase("Git\cmd")) = False Then
        err.Raise VTK_GIT_NOT_INSTALLED, "", "Git not installed."
    End If
    
    If vtkGitConvertWinPath(folderPath) = VTK_FORBIDDEN_PARAMETER Then
        err.Raise VTK_FORBIDDEN_PARAMETER, "", "Parameter is invalid."
    End If
    
    If vtkDoesFolderExist(folderPath) = False Then
        err.Raise VTK_WRONG_FOLDER_PATH, "", "Folder path not found."
    End If
    
    If vtkDoesFolderExist(folderPath & "\.git") = True Then
        err.Raise VTK_GIT_ALREADY_INITIALIZED_IN_FOLDER, "", "Git has already been initialized in the folder " & folderPath
    End If
    
    ' If a logfile has been passed as a parameter
    If logFile <> "" Then
        ' If the path is relative, make it absolute
        Dim splittedLogFilePath() As String
        splittedLogFilePath = Split(logFile, ":")
        If splittedLogFilePath(LBound(splittedLogFilePath)) = logFile Then
            logFileFullPath = folderPath & "\" & logFile
        End If
        ' Test the validity of the final path
        logFileFullPath = vtkGitConvertWinPath(logFileFullPath)
        If logFileFullPath = VTK_FORBIDDEN_PARAMETER Then
            err.Raise VTK_FORBIDDEN_PARAMETER, "", "Parameter is invalid."
        End If
    End If
    
    Dim wsh As Object
    Set wsh = VBA.CreateObject("WScript.Shell")
    Dim waitOnReturn As Boolean: waitOnReturn = True
    
    If logFile = "" Then
        ' No text log folder specified, simple git init
        'retShell = Shell("cmd.exe /c git init " & vtkGitConvertWinPath(folderPath))
        retShell = ShellAndWait("cmd.exe /c git init " & vtkGitConvertWinPath(folderPath), 0, vbHide, AbandonWait)
    Else
        ' Git init with redirection of the output : Git will create all the folder tree and the log file if they don't exist
        retShell = Shell("cmd.exe /c git init " & vtkGitConvertWinPath(folderPath) & "  > " _
        & vtkGitConvertWinPath(logFile))
        Application.Wait (Now + TimeValue("0:00:01"))
    End If
    On Error GoTo 0
    vtkInitializeGit = VTK_OK
    Exit Function
    
    
vtkInitializeGit_Err:
    If ((err.Number = VTK_GIT_NOT_INSTALLED) _
        Or (err.Number = VTK_GIT_ALREADY_INITIALIZED_IN_FOLDER) _
        Or (err.Number = VTK_FORBIDDEN_PARAMETER) _
        Or (err.Number = VTK_WRONG_FOLDER_PATH)) Then
        vtkInitializeGit = err.Number
    Else
        Debug.Print "ERR IN INITIALIZE : " & err.Number & err.Description
        vtkInitializeGit = VTK_UNEXPECTED_ERROR
    End If
    Exit Function

End Function

'---------------------------------------------------------------------------------------
' Procedure : vtkGitConvertWinPath
' Author    : Lucas Vitorino
' Purpose   : Converts an *absolute* Windows PATH to a one suitable for use with Git.
' Notes     : - WIP because I don't fully understand the behaviour of Git. I suppose
'               it's a Windows/Unix path format conflict.
'             - For now, I can't specify the drive letter in a path used with Git.
'               This function will strip it and git will assume it's "C" .
'             - Returns
'               - Converted string if OK
'               - VTK_FORBIDDEN_PARAMETER if winPath is not absolute, or absolute but not on the C: drive
'               - VTK_UNEXPECTED_ERR
'---------------------------------------------------------------------------------------
'
Public Function vtkGitConvertWinPath(winPath As String) As String
    
    Dim convertedPath As String
    convertedPath = winPath
    Dim convertedSplittedPath() As String
    
    On Error GoTo vtkGitConvertWinPath_Error
    
    convertedSplittedPath = Split(convertedPath, ":")
    
    ' Only allows absolute paths on the C: drive
    If convertedSplittedPath(LBound(convertedSplittedPath)) <> "C" Then
        err.Raise VTK_FORBIDDEN_PARAMETER, "", "Parameter is invalid."
    End If

    convertedPath = convertedSplittedPath(LBound(convertedSplittedPath) + 1)
    
    'Changing the backslahes in slashes
    ' NB : Optional
    convertedPath = Replace(convertedPath, "\", "/")
        
    On Error GoTo 0
    vtkGitConvertWinPath = Chr(34) & convertedPath & Chr(34)
    Exit Function
    

vtkGitConvertWinPath_Error:
    If (err.Number = VTK_FORBIDDEN_PARAMETER) Then
        vtkGitConvertWinPath = err.Number
    Else
     Debug.Print "ERR IN CONVERT : " & err.Number & err.Description
        vtkGitConvertWinPath = VTK_UNEXPECTED_ERROR
    End If
    Exit Function

End Function
