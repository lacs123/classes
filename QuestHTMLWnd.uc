//================================================================================
// QuestHTMLWnd.
//================================================================================
class QuestHTMLWnd extends UICommonAPI;

var WindowHandle Me;
var HtmlHandle m_hHtmlViewer;
var bool m_bDrawBg;
var bool m_bPressCloseButton;
var bool m_bReShowWndMode;
var bool m_bReShowQuestHtmlWnd;
var string HtmlString;
var int htmlWidth;
var int bicIconLen;
const TABLEBG_WIDTH= 400;
const HTML_WIDTH= 400;

function OnRegisterEvent ()
{
	RegisterEvent(3323);
	RegisterEvent(3324);
	RegisterEvent(3322);
	RegisterEvent(3321);
	RegisterEvent(150);
	RegisterEvent(160);
}

function OnLoad ()
{
	SetClosingOnESC();
	OnRegisterEvent();
	Me=GetWindowHandle("QuestHTMLWnd");
	m_hHtmlViewer=GetHtmlHandle("QuestHTMLWnd.HtmlViewer");
}

function OnShow ()
{
	getInstanceL2Util().syncWindowLoc(getCurrentWindowName(string(self)),"QuestHTMLWnd,NPCDialogWnd");
}

function OnHide ()
{
	ProcCloseQuestHTMLWnd();
	getInstanceL2Util().syncWindowLocAuto("QuestHTMLWnd,NPCDialogWnd");
}

function OnDefaultPosition ()
{
}

function OnEvent (int Event_ID, string param)
{
	switch (Event_ID)
	{
		case 3323:
		ShowQuestHTMLWnd();
		break;
		case 3324:
		HideQuestHTMLWnd();
		break;
		case 3322:
		Me.SetWindowTitle(GetSystemString(444));
		HandleLoadHtmlFromString(param);
		break;
		case 3321:
		HandleQuestIDLoadHtmlFromString(param);
		break;
		case 19:
		m_hHtmlViewer.LoadHtmlFromString(param);
		break;
		default:
	}
}

function int getLanguageNumber ()
{
	local ELanguageType Language;
	local int languageNum;

	Language=GetLanguage();
	switch (Language)
	{
		case 0:
		languageNum=0;
		break;
		case 1:
		languageNum=1;
		break;
		case 2:
		languageNum=2;
		break;
		case 3:
		languageNum=3;
		break;
		case 4:
		languageNum=4;
		break;
		case 5:
		languageNum=5;
		break;
		case 6:
		languageNum=6;
		break;
		case 7:
		languageNum=7;
		break;
		case 8:
		languageNum=8;
		break;
		case 9:
		languageNum=9;
		break;
		case 10:
		languageNum=10;
		break;
		case 11:
		languageNum=11;
		break;
		case 12:
		languageNum=12;
		break;
		case 13:
		languageNum=13;
		break;
		default:
		languageNum=0;
		break;
	}
	return languageNum;
}

function HandleQuestIDLoadHtmlFromString (string param)
{
	local int questID;
	local array<int> rewardIDList;
	local array<INT64> rewardNumList;
	local int i;
	local string addItemHtml;
	local string IconName;
	local string itemText;
	local string ItemName;
	local string rewardSmallIconHtml;
	local string rewardMsgHtml;
	local string rewardEndMsgHtml;
	local int tableIndex;
	local int smallIconIndex;

	ParseInt(param,"QuestID",questID);
	Class'UIDATA_QUEST'.GetQuestReward(questID,1,rewardIDList,rewardNumList);
	tableIndex=0;
	smallIconIndex=0;
	bicIconLen=0;
	rewardSmallIconHtml="<table width=278 border=0 cellpadding=0 cellspacing=1 background=L2UI_CT1.HtmlWnd.HTMLWnd_GroupBox_DF_Center>";
	i=0;
JL00C9:
	if ( i < rewardIDList.Length )
	{
		if ( (rewardIDList[i] != 57) && (rewardIDList[i] != 15623) && (rewardIDList[i] != 15624) && (rewardIDList[i] != 47130) )
		{
			bicIconLen++ ;
		}
		i++ ;
		goto JL00C9;
	}
	if ( bicIconLen == 1 )
	{
		rewardMsgHtml="<table width=278 border=0 cellpadding=0 cellspacing=1 background=L2UI_CT1.HtmlWnd.HTMLWnd_GroupBox_DF_Center>";
	} else {
		rewardMsgHtml="<table width=278 border=0 cellpadding=0 cellspacing=1 background=L2UI_CT1.HtmlWnd.HTMLWnd_GroupBox_DF_Center>";
	}
	if ( rewardIDList.Length > 0 )
	{
		i=0;
JL024C:
		if ( i < rewardIDList.Length )
		{
			if ( i == 0 )
			{
				addItemHtml="<br>" $ htmlTableAdd("L2UI_CT1.GroupBox.GroupBox_DF") $ "<font color="ffcc00" name=chatFontSize10>" $ GetSystemString(2006) $ "</font>" $ "</td></tr></table>";
			}
			switch (rewardIDList[i])
			{
				case 57:
				case 15623:
				case 15624:
				case 47130:
				case 95641:
				ItemName=Class'UIDATA_ITEM'.GetItemName(GetItemID(rewardIDList[i]));
				if ( rewardIDList[i] == 57 )
				{
					IconName="L2UI_CT1.HtmlWnd.HTMLWnd_adena";
					ItemName=GetSystemString(469);
				} else {
					if ( rewardIDList[i] == 15623 )
					{
						if (! getLanguageNumber() == 1 ) goto JL03BA;
JL03BA:
						IconName="L2UI_CT1.HtmlWnd.HTMLWnd_EXP";
					} else {
						if ( rewardIDList[i] == 15624 )
						{
							IconName="L2UI_CT1.HtmlWnd.HTMLWnd_SP";
						} else {
							if ( rewardIDList[i] == 47130 )
							{
								IconName="L2UI_CT1.HtmlWnd.HTMLWnd_FP";
							} else {
								if ( rewardIDList[i] == 95641 )
								{
									IconName="L2UI_CT1.HtmlWnd.htmlwnd_lv_point";
								}
							}
						}
					}
				}
				if ( JointName(rewardNumList[i],0) )
				{
					itemText=GetSystemString(584);
				} else {
					if ( rewardIDList[i] == 15624 )
}

function string htmlTableAdd (optional string backgroundUrl)
{
	local string htmlStr;

	if ( backgroundUrl == "" )
	{
		htmlStr="<table width=278 cellpadding=0 border=0 cellspacing=1" $ "><tr><td width=278>";
	} else {
		htmlStr="<table width=278 cellpadding=0 border=0 cellspacing=1 background=" $ backgroundUrl $ "><tr><td width=272>";
	}
	return htmlStr;
}

function string htmlTableTrAdd ()
{
	return "<tr><td width=46 ></td><td width=115 ></td><td width=46 ></td><td width=115 ></td></tr>";
}

function string htmlfontAdd (string strText, optional string FontColor)
{
	local string targetHtml;

	if ( FontColor == "" )
	{
		FontColor="d3c5ae";
	}
	targetHtml="<font color="" $ FontColor $ """ $ ">" $ strText $ "</font>";
	return targetHtml;
}

function OnHtmlMsgHideWindow (HtmlHandle a_HtmlHandle)
{
	if ( a_HtmlHandle == m_hHtmlViewer )
	{
		HideQuestHTMLWnd();
	}
}

function HandleLoadHtmlFromString (string param)
{
	ParseString(param,"HTMLString",HtmlString);
	m_hHtmlViewer.LoadHtmlFromString(HtmlString);
}

function ShowQuestHTMLWnd ()
{
	ExecuteEvent(3280);
	Me.ShowWindow();
	Me.SetFocus();
	m_bReShowQuestHtmlWnd=True;
}

function HideQuestHTMLWnd ()
{
	Me.HideWindow();
	m_bReShowQuestHtmlWnd=False;
}

function OnClickButton (string Name)
{
	PressCloseButton();
}

function OnExitState (name a_CurrentStateName)
{
	if ( a_CurrentStateName == 'NpcZoomCameraState' )
	{
		ReShowQuestHTMLWnd();
		Clear();
	}
}

function OnEnterState (name a_CurrentStateName)
{
	if ( a_CurrentStateName == 'NpcZoomCameraState' )
	{
		Clear();
		m_bReShowWndMode=True;
	}
}

function Clear ()
{
	m_bReShowWndMode=False;
	m_bPressCloseButton=False;
	m_bReShowQuestHtmlWnd=False;
}

function PressCloseButton ()
{
	if ( m_bReShowWndMode )
	{
		m_bPressCloseButton=True;
	}
}

function ProcCloseQuestHTMLWnd ()
{
	if ( m_bPressCloseButton && m_bReShowWndMode && m_bReShowQuestHtmlWnd )
	{
		m_bReShowWndMode=False;
		RequestFinishNPCZoomCamera();
	}
}

function ReShowQuestHTMLWnd ()
{
	if ( m_bReShowWndMode && m_bReShowQuestHtmlWnd )
	{
		ShowQuestHTMLWnd();
	}
}

function OnReceivedCloseUI ()
{
	PlayConsoleSound(6);
	PressCloseButton();
	GetWindowHandle("QuestHTMLWnd").HideWindow();
}