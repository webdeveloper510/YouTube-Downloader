#include <APIErrorsConstants.au3>
#include <StructureConstants.au3>
#include <GUIConstantsEX.au3>
#include <EditConstants.au3>
#include <InetConstants.au3>
#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Add_Constants=n
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#pragma compile(Compression, 1)
#include <array.au3>
#include <String.au3>
#include <WinAPIFiles.au3>
#include <IE.au3>
_singleton(@ScriptName)
Global Const $form_main = GUICreate("Vidripper - Hit {esc} to force exit!", 543, 350, -1, -1, -2133917696, 0);BitOR($GUI_SS_DEFAULT_GUI,$WS_MAXIMIZEBOX,$WS_SIZEBOX,$WS_THICKFRAME,$WS_TABSTOP)
Global Const $input_url = GUICtrlCreateInput("", 8, 42, 391, 21)
GUICtrlSetTip(-1, "YouTube Channel ID", "Info", 1, 1)
GUICtrlSendMsg($input_url, $EM_SETCUEBANNER, False, "YouTube Channel ID")
Global Const $project_name = GUICtrlCreateInput("", 8, 10, 391, 21)
GUICtrlSetTip(-1, "Enter Project Name", "Info", 1, 1)
GUICtrlSendMsg($project_name, $EM_SETCUEBANNER, False, "Project Name here")
Global Const $input_dest = GUICtrlCreateInput(@DesktopDir, 8, 72, 391, 21)
GUICtrlSetTip(-1, "Download destination", "Info", 1, 1)
Global Const $button_select = GUICtrlCreateButton("Change", 411, 70, 123, 25)
GUICtrlSetTip(-1, "Change download destination", "Info", 1, 1)
GUICtrlSetOnEvent(-1, "button_select_clicked")
Global Const $button_video = GUICtrlCreateButton("Download video", 8, 318, 123, 25)
GUICtrlSetTip(-1, "Start Video Download", "Info", 1, 1)
GUICtrlSetOnEvent(-1, "button_video_or_mp3_or_info_or_update_clicked")

Global Const $edit_out = GUICtrlCreateEdit("", 8, 102, 525, 209, 70256832);BitOR($ES_AUTOVSCROLL,$ES_AUTOHSCROLL,$ES_READONLY,$WS_HSCROLL,$WS_VSCROLL,$WS_CLIPSIBLINGS)
GUISetState(@SW_SHOW)
HotKeySet("{esc}", "close_clicked")
Opt('GUIOnEventMode', 1)
GUISetOnEvent(-3, "close_clicked", $form_main)
Global Const $aAccelKeys[1][2] = [["{enter}", $button_video]]
GUISetAccelerators($aAccelKeys)
Global $iPID = -1
Global $mButtons[2][8] = [[$button_video, $button_select,$project_name,$input_url, $input_dest], _
	[GUICtrlRead($button_video), GUICtrlRead($button_select), _
	GUICtrlRead($project_name), GUICtrlRead($input_url), GUICtrlRead($input_dest)]]
	local $htmlSTRING = ""

Global $sImgDir
Global $path
Global $newpath
Func button_video_or_mp3_or_info_or_update_clicked()
	Local Const $sFilePath = GUICtrlRead($input_dest) & "\"&GUICtrlRead($project_name)
    If FileExists($sFilePath) Then
        MsgBox($MB_SYSTEMMODAL, "", "An error occursred. The directory already exists.")
        Return False
    EndIf
    DirCreate($sFilePath)
	$sImgDir = GUICtrlRead($input_dest)
	$sImgDir = $sImgDir & '\' & GUICtrlRead($project_name) & '\thumbnails'
	DirCreate($sImgDir) ; Crearting folder for save thumbnails
	$path = GUICtrlRead($input_dest)
	$path = $path & '\' & GUICtrlRead($project_name) & '\videos'
	DirCreate($path) ; Creating folder for save videos
	$oHTTP = ObjCreate("winhttp.winhttprequest.5.1")
	$channel_id= GUICtrlRead($input_url)
	; if link has channel ID
	$oHTTP.Open("GET", "https://www.googleapis.com/youtube/v3/search?channelId="&$channel_id&"&part=snippet&type=video&maxResults=2&key="&DeveloperKey&"",False)
	$oHTTP.Send()
	$oReceived = $oHTTP.ResponseText
	$oStatusCode = $oHTTP.Status
	ConsoleWrite($oStatusCode)
	If $oStatusCode == 200 then
		ChannelApi($channel_id,$sImgDir,$path)
	Else
	; if link has Username ID
	$oHTTP = ObjCreate("winhttp.winhttprequest.5.1")
	$channel_id= GUICtrlRead($input_url)
	$oHTTP.Open("GET", "https://www.googleapis.com/youtube/v3/channels?part=contentDetails&forUsername="&$channel_id&"&key="&DeveloperKey&"", False)
	$oHTTP.Send()
	$oReceived = $oHTTP.ResponseText
	; Getting images from videos
	$newchannel_id = _StringBetween($oReceived,'"uploads": "','"')
	UserApi($newchannel_id[0],$sImgDir,$path)
	EndIf

EndFunc
Global $flag = false
; Fucntion for get data with Channel ID
Func ChannelApi($channelId,$sImgDir,$path,$nextPageTokennnn='')
	$oHTTPnew = ObjCreate("winhttp.winhttprequest.5.1")
	if $flag Then
		$oHTTPnew.Open("GET", "https://www.googleapis.com/youtube/v3/search?channelId="&$channelId&"&order=date&part=snippet&type=video&maxResults=5&pageToken="&$nextPageTokennnn&"&key="&DeveloperKey&"", False)
	Else
		$oHTTPnew.Open("GET", "https://www.googleapis.com/youtube/v3/search?channelId="&$channelId&"&order=date&part=snippet&type=video&maxResults=5&key="&DeveloperKey&"", False)
	Endif
	$oHTTPnew.Send()
	$oReceivednew = $oHTTPnew.ResponseText
	$nextPageToken = _StringBetween($oReceivednew,'"nextPageToken": "','"')
	if(IsArray($nextPageToken)) Then ; If next page available
		$flag = true
		donalodallvideos($channelId,$sImgDir,$path,$oReceivednew)
		ChannelApi($channelId,$sImgDir,$path,$nextPageToken[0])
	Else
		donalodallvideos($channelId,$sImgDir,$path,$oReceivednew)
		$flag= false
	Endif

EndFunc
; Fucntion for get data with username
Func UserApi($channelId,$sImgDir,$path,$nextPageTokennnn='')
	$oHTTPnew = ObjCreate("winhttp.winhttprequest.5.1")
	if $flag Then
		$oHTTPnew.Open("GET", "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&maxResults=2&pageToken="&$nextPageTokennnn&"&playlistId="&$channelId&"&key="&DeveloperKey&"", False)
	Else
		$oHTTPnew.Open("GET", "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&maxResults=2&playlistId="&$channelId&"&key="&DeveloperKey&"", False)
	Endif
	$oHTTPnew.Send()
	$oReceivednew = $oHTTPnew.ResponseText
	$nextPageToken = _StringBetween($oReceivednew,'"nextPageToken": "','"')
	if(IsArray($nextPageToken)) Then
		$flag = true
		donalodallvideos($channelId,$sImgDir,$path,$oReceivednew)
		UserApi($channelId,$sImgDir,$path,$nextPageToken[0])
	Else
		donalodallvideos($channelId,$sImgDir,$path,$oReceivednew)
		$flag= false
	Endif

EndFunc
Func donalodallvideos($channel_id,$sImgDir,$path,$oReceived)

	$subHTTP = ObjCreate("winhttp.winhttprequest.5.1")
	$subHTTP.Open("GET", "https://www.googleapis.com/youtube/v3/channels?part=statistics&id="&$channel_id&"&key="&DeveloperKey&"", False)
	$subHTTP.Send()
	$subReceived = $subHTTP.ResponseText
	ConsoleWrite($subReceived)
	$channelviewCount = _StringBetween($subReceived,'"viewCount": "','"')
	$htmlSTRING &= "Channel View Count:"&$channelviewCount[0]&@CRLF
	$channelcommentCount = _StringBetween($subReceived,'"commentCount": "','"')
	$htmlSTRING &= "Channel Comment Count:"&$channelcommentCount[0]&@CRLF
	$subscriberCount = _StringBetween($subReceived,'"subscriberCount": "','"')
	$htmlSTRING &= "Channel Subscribers Count:"&$subscriberCount[0]&@CRLF
	$videoCount = _StringBetween($subReceived,'"videoCount": "','"')
	$htmlSTRING &= "Total Video Count:"&$videoCount[0]&@CRLF
	$sImgDir = _WinAPI_GetTempFileName($sImgDir)
	$arr = _StringBetween($oReceived,'"videoId": "','"')
	$subscribres = _StringBetween($oReceived,'"videoId": "','"')
	$titlearray = _StringBetween($oReceived,'"title": "','default.jpg"')
	;$htmlSTRING &= "Videos:-"&@CRLF
	For $i = 0 to (UBound($arr) - 1)
		$newHTTP = ObjCreate("winhttp.winhttprequest.5.1")
		$channel_id= GUICtrlRead($input_url)
		$newHTTP.Open("GET", "https://www.googleapis.com/youtube/v3/videos?part=statistics&id="&$arr[$i]&"&key="&DeveloperKey&"",False)
		$newHTTP.Send()

		$newReceived = $newHTTP.ResponseText
		$htmlSTRING &= "Title :-"&$titlearray[$i]&@CRLF
		$likeCount = _StringBetween($newReceived,'"likeCount": "','"')
		$htmlSTRING &= @TAB&"Like Count:"&$likeCount[0]&@CRLF
		$dislikeCount = _StringBetween($newReceived,'"dislikeCount": "','"')
		$htmlSTRING &= @TAB&"Dislike Count:"&$dislikeCount[0]&@CRLF
		$viewCount = _StringBetween($newReceived,'"viewCount": "','"')
		$htmlSTRING &= @TAB&"View Count:"&$viewCount[0]&@CRLF
		$commentCount = _StringBetween($newReceived,'"commentCount": "','"')
		$htmlSTRING &= @TAB&"Comment Count:"&$commentCount[0]&@CRLF
		$favoriteCount = _StringBetween($newReceived,'"favoriteCount": "','"')
		$htmlSTRING &= @TAB&"Favorite Count:"&$favoriteCount[0]&@CRLF
		$htmlSTRING &= ""&@CRLF
		$youtubeurl = "https://www.youtube.com/watch?v="&$arr[$i]
		$sImgUrl = 'https://i.ytimg.com/vi/'&$arr[$i]&'/hqdefault.jpg'
		$sImgFileName = 'Thumb'&$arr[$i]&'.jpg'
		InetGet($sImgUrl, $sImgDir & $sImgFileName) ; Saving Thumbnails in folder
		If FileExists($path) <> 1 Then Return
		disable_gui()

	; Code for download videos
	FileInstall(".\youtube-dl.exe", @TempDir & "\youtube-dl.exe", 0)
		Local $sOutput = ""
		Local $sCommand = @TempDir & '\youtube-dl.exe -o "' & $path & '\%(title)s-%(id)s.%(ext)s" ' & $youtubeurl
		Local $sAudioParam = ""
		$iPID = Run($sCommand & ' ' & $sAudioParam, @TempDir, @SW_HIDE, 0x2 + 0x4);$STDERR_CHILD + $STDOUT_CHILD)
		GUICtrlSetData($edit_out, '')
		While 1
			$sOutput = StdoutRead($iPID)
			If @error Then ExitLoop
			If $sOutput <> '' Then
				If StringInStr($sOutput, "[download]") > 1 Then
					GUICtrlSetData($edit_out, $sOutput)
				Else
					GUICtrlSetData($edit_out, GUICtrlRead($edit_out) & $sOutput)
				EndIf
			EndIf
			$sOutput = StderrRead($iPID)
			If @error Then ExitLoop
			If $sOutput <> '' Then GUICtrlSetData($edit_out, GUICtrlRead($edit_out) & $sOutput)
		WEnd


	enable_gui()
	Next
	$newpath = GUICtrlRead($input_dest)
	$newpath = $newpath&'\'&GUICtrlRead($project_name)

	FileWrite($newpath&"\info.html", $htmlSTRING)
EndFunc
Func button_paste_clicked()
	GUICtrlSetData($input_url, ClipGet())
EndFunc

Func button_select_clicked()
	Local $destinationDirectory = FileSelectFolder("Select destination directory", "", 7, "", $form_main)
	If $destinationDirectory <> "" Then GUICtrlSetData($input_dest, $destinationDirectory)
EndFunc

Func disable_gui()
	For $i = 0 To UBound($mButtons, 2) -1
		GUICtrlSetState($mButtons[0][$i], 128)
	Next
	$mButtons[1][6] = GUICtrlRead($input_url)
	$mButtons[1][7] = GUICtrlRead($input_dest)
EndFunc

Func enable_gui()
	For $i = 0 To UBound($mButtons, 2) -1
		GUICtrlSetState($mButtons[0][$i], 64)
		GUICtrlSetData($mButtons[0][$i], $mButtons[1][$i])
	Next
	$iPID = -1
EndFunc

Func close_clicked()
	If BitAND(WinGetState($form_main), 8) Then
		If ProcessExists($iPID) <> 0 Then
			ProcessClose($iPID)
			GUICtrlSetData($edit_out, '~ interrupt!')
		Else
			Exit
		EndIf
	EndIf
EndFunc
; for install .exe file in tem directory
Func _singleton($sOccurenceName, $iFlag = 0)
	Local Const $ERROR_ALREADY_EXISTS = 183
	Local Const $SECURITY_DESCRIPTOR_REVISION = 1
	Local Const $tagSECURITY_ATTRIBUTES = "dword Length;ptr Descriptor;bool InheritHandle"
	Local $tSecurityAttributes = 0
	If BitAND($iFlag, 2) Then
		; The size of SECURITY_DESCRIPTOR is 20 bytes.  We just
		; need a block of memory the right size, we aren't going to
		; access any members directly so it's not important what
		; the members are, just that the total size is correct.
		Local $tSecurityDescriptor = DllStructCreate("byte;byte;word;ptr[4]")
		; Initialize the security descriptor.
		Local $aRet = DllCall("advapi32.dll", "bool", "InitializeSecurityDescriptor", _
				"struct*", $tSecurityDescriptor, "dword", $SECURITY_DESCRIPTOR_REVISION)
		If @error Then Return SetError(@error, @extended, 0)
		If $aRet[0] Then
			; Add the NULL DACL specifying access to everybody.
			$aRet = DllCall("advapi32.dll", "bool", "SetSecurityDescriptorDacl", _
					"struct*", $tSecurityDescriptor, "bool", 1, "ptr", 0, "bool", 0)
			If @error Then Return SetError(@error, @extended, 0)
			If $aRet[0] Then
				; Create a SECURITY_ATTRIBUTES structure.
				$tSecurityAttributes = DllStructCreate($tagSECURITY_ATTRIBUTES)
				; Assign the members.
				DllStructSetData($tSecurityAttributes, 1, DllStructGetSize($tSecurityAttributes))
				DllStructSetData($tSecurityAttributes, 2, DllStructGetPtr($tSecurityDescriptor))
				DllStructSetData($tSecurityAttributes, 3, 0)
			EndIf
		EndIf
	EndIf
	Local $aHandle = DllCall("kernel32.dll", "handle", "CreateMutexW", "struct*", $tSecurityAttributes, "bool", 1, "wstr", $sOccurenceName)
	If @error Then Return SetError(@error, @extended, 0)
	Local $aLastError = DllCall("kernel32.dll", "dword", "GetLastError")
	If @error Then Return SetError(@error, @extended, 0)
	If $aLastError[0] = $ERROR_ALREADY_EXISTS Then
		If BitAND($iFlag, 1) Then
			DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $aHandle[0])
			If @error Then Return SetError(@error, @extended, 0)
			Return SetError($aLastError[0], $aLastError[0], 0)
		Else
			Exit -1
		EndIf
	EndIf
	Return $aHandle[0]
EndFunc

While 1
	Sleep(10000)
WEnd
