//================================================================================
// WorldExchangeRegiSubWnd.
//================================================================================
class WorldExchangeRegiSubWnd extends UICommonAPI;

var ItemWindowHandle ItemWnd;

static function WorldExchangeRegiSubWnd Inst ()
{
	return WorldExchangeRegiSubWnd(GetScript("WorldExchangeRegiSubWnd"));
}

function Initialize ()
{
	ItemWnd=GetItemWindowHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".itemEnchantSubWndItemWnd");
	GetTextBoxHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".DescriptionMsgWnd.descTextBox").SetText(GetSystemMessage(4222));
}

event OnRegisterEvent ()
{
	RegisterEvent(9570);
}

event OnLoad ()
{
	Initialize();
}

event OnShow ()
{
	Refresh();
}

event OnRClickItem (string ControlName, int Index)
{
	OnDBClickItem(ControlName,Index);
}

event OnDBClickItem (string ControlName, int Index)
{
	local ItemInfo iInfo;

	ItemWnd.GetItem(Index,iInfo);
	iInfo.DragSrcName="itemEnchantSubWndItemWnd";
	Class'WorldExchangeRegiWnd'.Inst().OnDropItem("",iInfo,0,0);
}

event OnEvent (int Event_ID, string param)
{
	switch (Event_ID)
	{
		case 9570:
		if ( m_hOwnerWnd.IsShowWindow() )
		{
			RefreshItemNum();
		}
		break;
		default:
	}
}

function _Show ()
{
	m_hOwnerWnd.ShowWindow();
	Refresh();
}

function _Hide ()
{
	m_hOwnerWnd.HideWindow();
}

function RefreshItemNum ();

function Refresh ()
{
	SetSellItems();
}

function _ResetSellItem ()
{
	local int idx;
	local ItemInfo iInfo;
	local ItemInfo inveniInfo;
	local ItemInfo sellItemInfo;

	Class'WorldExchangeRegiWnd'.Inst()._GetSellItemInfo(sellItemInfo);
	if (  !Class'UIDATA_INVENTORY'.HasItem(sellItemInfo.Id.ServerID) )
	{
		Class'WorldExchangeRegiWnd'.Inst().DelItemInfo();
		Refresh();
		return;
	}
	Class'UIDATA_INVENTORY'.FindItem(sellItemInfo.Id.ServerID,inveniInfo);
	idx=ItemWnd.FindItem(sellItemInfo.Id);
	if ( idx == -1 )
	{
		Refresh();
		return;
	} else {
		ItemWnd.GetItem(idx,iInfo);
		Refresh();
		return;
	}
	iInfo.ItemNum=AddTargetPos(inveniInfo.ItemNum,sellItemInfo.ItemNum);
	ItemWnd.SetItem(idx,iInfo);
}

function SetSellItems ()
{
	local int i;
	local ItemInfo sellItemInfo;
	local array<ItemInfo> iInfos;

	ItemWnd.Clear();
	iInfos=GetAllItemInfo();
	Class'WorldExchangeRegiWnd'.Inst()._GetSellItemInfo(sellItemInfo);
	i=0;
JL0040:
	if ( i < iInfos.Length )
	{
		if (  !iInfos[i].bIsAuctionAble )
		{
			goto JL0147;
		}
		if ( sellItemInfo.Id==iInfos[i].Id )
		{
			iInfos[i].ItemNum=AddTargetPos(iInfos[i].ItemNum,sellItemInfo.ItemNum);
		}
		if ( JointName(iInfos[i].ItemNum,0) )
		{
			goto JL0147;
		}
		if ( iInfos[i].bSecurityLock )
		{
			goto JL0147;
		}
		if ( iInfos[i].CurrentPeriod > 0 )
		{
			goto JL0147;
		}
		iInfos[i].bShowCount=IsStackableItem(iInfos[i].ConsumeType);
		ItemWnd.AddItem(iInfos[i]);
JL0147:
		i++;
		goto JL0040;
	}
	SetDescTextBox();
}

function array<ItemInfo> GetAllItemInfo ()
{
	local array<ItemInfo> allItem;

	Class'UIDATA_INVENTORY'.GetAllInvenItem(allItem);
	return allItem;
}

function SetDescTextBox ()
{
	if ( ItemWnd.GetItemNum() == 0 )
	{
		GetWindowHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".DescriptionMsgWnd").ShowWindow();
	} else {
		GetWindowHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".DescriptionMsgWnd").HideWindow();
	}
}