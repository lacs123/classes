//================================================================================
// WorldExchangeRegiWndItemHistoryTabWnd.
//================================================================================
class WorldExchangeRegiWndItemHistoryTabWnd extends UICommonAPI;

var array<_WorldExchangeItemData> _itemDatas;
var L2UITimerObject tObject;
var RichListCtrlHandle ItemHistory_RichList;
var TextureHandle AddReward;
var INT64 nWEIndexRequested;
var int receivedNum;
enum listType {
	Received,
	TimeOut,
	Normal
};

const REFRESHLIMIT= 2000;

function ReduceReceiveNum ()
{
	receivedNum--;
	CheckNoticeWnd();
}

function CheckNoticeWnd ()
{
	local NoticeWnd noticeWndScr;

	noticeWndScr=NoticeWnd(GetScript("NoticeWnd"));
	if ( receivedNum < 1 )
	{
		noticeWndScr._RemoveNoticButtonWorldExchangeBuy();
	} else {
		noticeWndScr._CreateWorldExchangeBuyNotice();
	}
}

function SetRegisterEvent ()
{
	RegisterEvent(EV_PacketID(Class'UIPacket'.1023));
	RegisterEvent(EV_PacketID(Class'UIPacket'.1024));
	Debug("           -----------   히스토리 온 레디스트 됐나? OnRegisterEvent");
}

function OnLoad ()
{
	SetClosingOnESC();
	tObject=Class'L2UITimer'.Inst()._AddNewTimerObject(2000);
	tObject.___DelegateOnEnd__Delegate
	self
	ItemHistory_RichList=GetRichListCtrlHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".ItemHistory_RichList");
	ItemHistory_RichList.SetSelectedSelTooltip(False);
	ItemHistory_RichList.SetAppearTooltipAtMouseX(True);
	Debug("          -----------   히스토리 온 로드 됐나? OnLoad :" @ m_hOwnerWnd.m_WindowNameWithFullPath $ ".ItemHistory_RichList");
	SetRegisterEvent();
}

event OnEvent (int EventID, string param)
{
	switch (EventID)
	{
		case EV_PacketID(Class'UIPacket'.1023):
		RT_S_EX_WORLD_EXCHANGE_SETTLE_LIST();
		break;
		case EV_PacketID(Class'UIPacket'.1024):
		RT_S_EX_WORLD_EXCHANGE_SETTLE_RECV_RESULT();
		break;
		default:
	}
}

event OnShow ()
{
	SetMyInfos();
}

function SetMyInfos ()
{
	Debug("OnSHOw");
}

event OnClickButton (string strID)
{
	Debug("OnClickButton" @ strID);
	switch (strID)
	{
		case "Refresh_Btn":
		HandleRefresh();
		break;
		default:
		ChckBtnName(strID);
		break;
	}
}

function RQ_C_EX_WORLD_EXCHANGE_SETTLE_LIST ()
{
	local array<byte> stream;
	local _C_EX_WORLD_EXCHANGE_SETTLE_LIST packet;

	if (  !Class'UIPacket'.Encode_C_EX_WORLD_EXCHANGE_SETTLE_LIST(stream,packet) )
	{
		return;
	}
	Debug("RQ_C_EX_WORLD_EXCHANGE_SETTLE_LIST");
	Class'UIPacket'.RequestUIPacket(Class'UIPacket'.785,stream);
}

function RT_S_EX_WORLD_EXCHANGE_SETTLE_LIST ()
{
	local _S_EX_WORLD_EXCHANGE_SETTLE_LIST packet;

	Debug("RT_S_EX_WORLD_EXCHANGE_SETTLE_LIST");
	if (  !Class'UIPacket'.Decode_S_EX_WORLD_EXCHANGE_SETTLE_LIST(packet) )
	{
		return;
	}
	ItemHistory_RichList.DeleteAllItem();
	AddList(packet.vRecvItemDataList,0);
	AddList(packet.vTimeOutItemDataList,1);
	AddList(packet.vRegiItemDataList,2);
	receivedNum=packet.vRecvItemDataList.Length;
	CheckNoticeWnd();
	handleResult();
}

function handleResult ()
{
	GetTextBoxHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".MyRegiItemNumTxt_Apply").SetText(string(_GetRegiItemCount()));
	AddReward=GetTextureHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".AddReward");
	Class'WorldExchangeRegiWnd'.Inst()._SetCurrentRigedItemNum(_GetRegiItemCount());
	if ( receivedNum == 0 )
	{
		AddReward.HideWindow();
	} else {
		if ( receivedNum < 10 )
		{
			AddReward.SetTexture("L2UI_CT1.tab.TabNoticeCount_0" $ string(receivedNum));
			AddReward.ShowWindow();
		} else {
			if ( receivedNum > 9 )
			{
				AddReward.SetTexture("L2UI_CT1.tab.TabNoticeCount_09Plus");
				AddReward.ShowWindow();
			}
		}
	}
}

function int _GetRegiItemCount ()
{
	return ItemHistory_RichList.GetRecordCount();
}

function AddList (array<_WorldExchangeItemData> itemDatas, listType _listType)
{
	local int i;
	local RichListCtrlRowData RowData;

	i=0;
JL0007:
	if ( i < itemDatas.Length )
	{
		if ( MakeRowData(itemDatas[i],RowData,_listType) )
		{
			ItemHistory_RichList.InsertRecord(RowData);
		}
		i++;
		goto JL0007;
	}
}

function RQ_C_EX_WORLD_EXCHANGE_SETTLE_RECV_RESULT ()
{
	local array<byte> stream;
	local _C_EX_WORLD_EXCHANGE_SETTLE_RECV_RESULT packet;
}

function RT_S_EX_WORLD_EXCHANGE_SETTLE_RECV_RESULT ()
{
	local _S_EX_WORLD_EXCHANGE_SETTLE_RECV_RESULT packet;

	Debug("RT_S_EX_WORLD_EXCHANGE_SETTLE_RECV_RESULT");
	if (  !Class'UIPacket'.Decode_S_EX_WORLD_EXCHANGE_SETTLE_RECV_RESULT(packet) )
	{
		return;
	}
	switch (packet.cSuccess)
	{
		case 1:
		HandleRecvResult();
		break;
		case 0:
		getInstanceL2Util().showGfxScreenMessage(GetSystemMessage(13686));
		break;
		case -1:
		getInstanceL2Util().showGfxScreenMessage(GetSystemMessage(13687));
		break;
		default:
	}
	GetWindowHandle("WorldExchangeRegiWnd.CancelSaleDialog_Wnd").HideWindow();
}

function HandleRecvResult ()
{
	local int i;
	local RichListCtrlRowData RowData;

	i=GetRichListCtrlRowData(nWEIndexRequested,RowData);
	if ( i < 0 )
	{
		return;
}

function int GetRichListCtrlRowData (INT64 nWEIndex, out RichListCtrlRowData outRowData)
{
	local int i;

	i=GetListIndexWithnWEIndex(nWEIndex);
	ItemHistory_RichList.GetRec(i,outRowData);
	return i;
}

function SetDisablbRefresh ()
{
	Class'WorldExchangeRegiWnd'.Inst()._ShowDisableWIndow();
	tObject._Reset();
}

function SetEnableRefresh ()
{
	Class'WorldExchangeRegiWnd'.Inst()._HideDisableWindow();
}

function ChckBtnName (string btnName)
{
	local array<string> names;

	Split(btnName,"_",names);
	if ( names[0] == "btnBuy" )
	{
		SetShowBuyDialogWindow(int(names[1]));
	}
}

function SetShowBuyDialogWindow (int WEIndex)
{
	local RichListCtrlRowData RowData;
	local int listIndex;

	if ( IsPlayerOnWorldRaidServer() )
	{
		getInstanceL2Util().showGfxScreenMessage(GetSystemMessage(4047));
		return;
	}
	listIndex=GetListIndexWithnWEIndex(WEIndex);
	ItemHistory_RichList.GetRec(listIndex,RowData);
	nWEIndexRequested=WEIndex;
	switch (RowData.nReserved3)
	{
		case 0:
		case 1:
		RQ_C_EX_WORLD_EXCHANGE_SETTLE_RECV_RESULT();
		break;
		case 2:
		ShowDialog(RowData.szReserved);
		break;
		default:
	}
}

function _RQ_C_EX_WORLD_EXCHANGE_SETTLE_RECV_RESULT ()
{
	RQ_C_EX_WORLD_EXCHANGE_SETTLE_RECV_RESULT();
}

function ShowDialog (string itemReservedString)
{
	Class'WorldExchangeRegiWnd'.Inst()._SetShowCancelDialog(itemReservedString);
}

function int GetListIndexWithnWEIndex (INT64 nWEIndex)
{
	local int i;
	local RichListCtrlRowData RowData;

	i=0;
JL0007:
	if ( i < ItemHistory_RichList.GetRecordCount() )
	{
		ItemHistory_RichList.GetRec(i,RowData);
		if ( JointName(RowData.nReserved1,nWEIndex) )
		{
			return i;
		}
		i++;
		goto JL0007;
	}
	return -1;
}

function _Show ()
{
}

function _Hide ()
{
	m_hOwnerWnd.HideWindow();
}

function HandleRefresh ()
{
	Debug(" Handle Refresh");
	SetDisablbRefresh();
	RQ_C_EX_WORLD_EXCHANGE_SETTLE_LIST();
}

function bool MakeRowData (_WorldExchangeItemData _itemData, out RichListCtrlRowData outRowData, listType _listType)
{
	local RichListCtrlRowData RowData;
	local ItemInfo iInfo;
	local string strcom;
	local string itemParam;
	local int nWidth;
	local int nHeight;
	local int buttonW;
	local int RemainTime;

	RowData.cellDataList.Length=5;
	if ( _itemData.nItemClassID < 1 )
	{
		return False;
	}
	if (  !Class'UIDATA_ITEM'.GetItemInfo(GetItemID(_itemData.nItemClassID),iInfo) )
	{
		return False;
	}
	RowData.nReserved1=_itemData.nWEIndex;
	RemainTime=_itemData.nExpiredTime - Class'UIData'.Inst().serverStartTime - Class'UIData'.Inst().GameConnectTimeSec();
	RowData.nReserved3=_listType;
	iInfo.ItemNum=_itemData.nAmount;
	iInfo.bShowCount=IsStackableItem(iInfo.ConsumeType);
	iInfo.Enchanted=_itemData.nEnchant;
	iInfo.RefineryOp1=_itemData.nVariationOpt1;
	iInfo.RefineryOp2=_itemData.nVariationOpt2;
	iInfo.AttackAttributeType=_itemData.nBaseAttributeAttackType;
	iInfo.AttackAttributeValue=_itemData.nBaseAttributeAttackValue;
	iInfo.DefenseAttributeValueFire=_itemData.nBaseAttributeDefendValue[0];
	iInfo.DefenseAttributeValueWater=_itemData.nBaseAttributeDefendValue[1];
	iInfo.DefenseAttributeValueWind=_itemData.nBaseAttributeDefendValue[2];
	iInfo.DefenseAttributeValueEarth=_itemData.nBaseAttributeDefendValue[3];
	iInfo.DefenseAttributeValueHoly=_itemData.nBaseAttributeDefendValue[4];
	iInfo.DefenseAttributeValueUnholy=_itemData.nBaseAttributeDefendValue[5];
	iInfo.LookChangeItemID=_itemData.nShapeShiftingClassId;
	iInfo.EnsoulOption[1 - 1].OptionArray[0]=_itemData.nEsoulOption[0];
	iInfo.EnsoulOption[1 - 1].OptionArray[1]=_itemData.nEsoulOption[1];
	iInfo.EnsoulOption[2 - 1].OptionArray[0]=_itemData.nEsoulOption[2];
	iInfo.IsBlessedItem=_itemData.nBlessOption == 1;
	addRichListCtrlTexture(RowData.cellDataList[0].drawitems,"l2ui_ct1.ItemWindow_DF_SlotBox_Default",36,36,8,1);
	AddRichListCtrlItem(RowData.cellDataList[0].drawitems,iInfo,32,32,-34,2);
}

function INT64 GetCommitionSell (INT64 Cnt)
{
	local WorldExchangeUIData tmpWorldExchangeUIData;

}

event OnReceivedCloseUI ()
{
	Class'WorldExchangeRegiWnd'.Inst()._Hide();
}