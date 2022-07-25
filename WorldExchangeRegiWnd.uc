//================================================================================
// WorldExchangeRegiWnd.
//================================================================================
class WorldExchangeRegiWnd extends UICommonAPI;

var int lastLoadedPage;
var int nMaxPage;
var bool bRQ_C_EX_WORLD_EXCHANGE_ITEM_LIST;
var array<_WorldExchangeItemData> _itemDatas;
var WindowHandle FindDisable_Wnd;
var WindowHandle WindowDisable_Wnd;
var L2UITimerObject tObject;
var L2UITimerObject tObjectListAdd;
var RichListCtrlHandle ExchangeFind_RichList;
var ItemInfo sellItemInfo;
var ItemInfo readySellItemInfo;
var int scrollPos;
var int _regieditemNum;
var int sortHeaderIndex;
var UIControlNumberInput itemSell_NumberInputScr;
var UIControlNumberInput bundlePrice_NumberInputScr;
var WorldExchangeRegiWndItemHistoryTabWnd historyScr;
enum E_WORLD_EXCHANGE_SORT_TYPE {
	EWEST_NONE,
	EWEST_ITEM_NAME,
	EWEST_ENCHANT_ASCE,
	EWEST_ENCHANT_DESC,
	EWEST_PRICE_ASCE,
	EWEST_PRICE_DESC
};

const MAXITEMNUM= 1;
const REFRESHLIMIT= 1000;
const LCOIN_CLASSID= 99422;
const ADENA_CLASSID= 99422;
const MINRegiBundlePrice= 10;
const MAXRegiItemNum= 15;

static function WorldExchangeRegiWnd Inst ()
{
	return WorldExchangeRegiWnd(GetScript("WorldExchangeRegiWnd"));
}

event OnRegisterEvent ()
{
	RegisterEvent(EV_PacketID(Class'UIPacket'.1020));
	RegisterEvent(EV_PacketID(Class'UIPacket'.1021));
}

function OnLoad ()
{
	SetClosingOnESC();
	ExchangeFind_RichList=GetRichListCtrlHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".RegiTabWnd.ExchangeFind_RichList");
	ExchangeFind_RichList.SetSelectedSelTooltip(False);
	ExchangeFind_RichList.SetAppearTooltipAtMouseX(True);
	ExchangeFind_RichList.SetSortable(False);
	itemSell_NumberInputScr=Class'UIControlNumberInput'.InitScript(GetWindowHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".RegiTabWnd.ItemRegi_Wnd.ItemSell_NumberInput"));
	bundlePrice_NumberInputScr=Class'UIControlNumberInput'.InitScript(GetWindowHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".RegiTabWnd.ItemRegi_Wnd.BundlePrice_NumberInput"));
	bundlePrice_NumberInputScr._SetMinCountCanBuy(0);
}

function SetScriptHistory ()
{
	local WindowHandle historyWnd;

	historyWnd=GetWindowHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".ItemHistoryTabWnd");
	historyWnd.SetScript("WorldExchangeRegiWndItemHistoryTabWnd");
	historyScr=WorldExchangeRegiWndItemHistoryTabWnd(historyWnd.GetScript());
	historyScr.m_hOwnerWnd=historyWnd;
}

event OnEvent (int EventID, string param)
{
	switch (EventID)
	{
		case EV_PacketID(Class'UIPacket'.1020):
		RT_S_EX_WORLD_EXCHANGE_ITEM_LIST();
		break;
		case EV_PacketID(Class'UIPacket'.1021):
		RT_S_EX_WORLD_EXCHANGE_REGI_ITEM();
		break;
		default:
	}
}

event OnScrollMove (string strID, int pos)
{
	switch (strID)
	{
		case "ExchangeFind_RichList":
		HandleScrollMove(pos);
		break;
		default:
	}
}

event OnShow ()
{
	SetMyInfos();
	historyScr.RQ_C_EX_WORLD_EXCHANGE_SETTLE_LIST();
	CheckWorldExchangeRegiSubWnd();
	Class'WorldExchangeBuyWnd'.Inst()._Hide();
	getInstanceL2Util().ItemRelationWindowHide(getCurrentWindowName(string(self)));
	DelItemInfo();
	GetTextBoxHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".ItemRegiDialog_Wnd.Dialog_Wnd.TaxRateTitle_txt").SetText(GetSystemString(1608) $ ":" @ string(API_GetWorldExchangeData().SellFee) $ "%");
	GetTextBoxHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".RegiTabWnd.ItemRegi_Wnd.TaxRateTitle_txt").SetText(GetSystemString(1608) $ ":" @ string(API_GetWorldExchangeData().SellFee) $ "%");
	if ( bRQ_C_EX_WORLD_EXCHANGE_ITEM_LIST )
	{
		tObjectListAdd._Reset();
		tObject._Reset();
	}
	SetHideSellDialogWindow();
}

event OnClickButton (string strID)
{
	Debug("OnClickButton" @ strID);
	switch (strID)
	{
		case "GetReward_Btn":
		HandleGetRewardBtn();
		break;
		case "WndClose_BTN":
		_Hide();
		break;
		case "Refresh_btn":
		HandleRefresh();
		break;
		case "MoveWnd_Btn":
		handleSwap();
		break;
		case "Cancel_Btn":
		SetHideSellDialogWindow();
		break;
		case "Ok_Btn":
		SetHideSellDialogWindow();
		RQ_C_EX_WORLD_EXCHANGE_REGI_ITEM();
		break;
		case "Cancel_Ok_Btn":
		HandleCancelOK();
		break;
		case "Cancel_Cancel_Btn":
		HandleCancelCancel();
		break;
		case "RegiList_Tab0":
		case "RegiList_Tab1":
		CheckWorldExchangeRegiSubWnd();
		break;
		default:
	}
}

event OnDBClickItemWithHandle (ItemWindowHandle a_hItemWindow, int a_Index)
{
	local ItemInfo iInfo;

	a_hItemWindow.GetItem(a_Index,iInfo);
	ItemDrop(iInfo);
}

event OnRClickItemWithHandle (ItemWindowHandle a_hItemWindow, int a_Index)
{
	local ItemInfo iInfo;

	a_hItemWindow.GetItem(a_Index,iInfo);
	ItemDrop(iInfo);
}

event OnDropItemSource (string strTarget, ItemInfo Info)
{
	if ( strTarget == "Item_ItemWnd" )
	{
		return;
	}
	if ( Info.DragSrcName != "Item_ItemWnd" )
	{
		return;
	}
	ItemDrop(Info);
}

function ItemDrop (ItemInfo Info)
{
	if ( Class'InputAPI'.IsAltPressed() ||  !IsStackableItem(Info.ConsumeType) || JointName(Info.ItemNum,1) )
	{
		DelItemInfo();
	} else {
		Class'DialogBox'.Inst().SetDefaultAction(1);
		DialogShow(1,6,MakeFullSystemMsg(GetSystemMessage(1833),sellItemInfo.Name,""),string(self));
}

function OnDropItem (string strTarget, ItemInfo iInfo, int X, int Y)
{
	if ( _regieditemNum == 15 )
	{
		getInstanceL2Util().showGfxScreenMessage(GetSystemMessage(13688));
		return;
	}
	if ( iInfo.DragSrcName != "itemEnchantSubWndItemWnd" )
	{
		return;
	}
	sellItemInfo=iInfo;
	sellItemInfo.ItemNum=1;
	SetItemInfo();
	return;
	if ( Class'InputAPI'.IsAltPressed() ||  !IsStackableItem(iInfo.ConsumeType) )
	{
		sellItemInfo=iInfo;
		sellItemInfo.ItemNum=GetSellItemInfoNum(iInfo.Id.ServerID);
		SetItemInfo();
	} else {
		readySellItemInfo=iInfo;
		Class'DialogBox'.Inst().SetDefaultAction(1);
		DialogShow(1,6,MakeFullSystemMsg(GetSystemMessage(72),iInfo.Name,""),string(self));
}

event OnClickHeaderCtrl (string strID, int Index)
{
	if ( bRQ_C_EX_WORLD_EXCHANGE_ITEM_LIST )
	{
		return;
	}
	SetSortByHeaderIndex(Index);
	RQ_C_EX_WORLD_EXCHANGE_ITEM_LIST();
}

function WorldExchangeUIData API_GetWorldExchangeData ()
{
	return GetWorldExchangeData();
}

function int API_GetServerPrivateStoreSearchItemSubType (int a_AuctionCategory)
{
	return GetServerPrivateStoreSearchItemSubType(a_AuctionCategory);
}

function RQ_C_EX_WORLD_EXCHANGE_ITEM_LIST (optional int Page)
{
	local array<byte> stream;
	local _C_EX_WORLD_EXCHANGE_ITEM_LIST packet;

	if ( bRQ_C_EX_WORLD_EXCHANGE_ITEM_LIST )
	{
		return;
	}
	if ( _itemDatas.Length > 0 )
	{
		return;
	}
	if ( Page > 0 )
	{
		if ( nMaxPage < Page )
		{
			return;
		}
	}
	Debug("Page!!!! " @ string(Page));
	SetDisablbRefresh();
	lastLoadedPage=Page;
	packet.nCategory=API_GetServerPrivateStoreSearchItemSubType(sellItemInfo.AuctionCategory);
	packet.cSortType=GetSortType();
	packet.nPage=Page;
	packet.vItemIDList[0]=sellItemInfo.Id.ClassID;
	if (  !Class'UIPacket'.Encode_C_EX_WORLD_EXCHANGE_ITEM_LIST(stream,packet) )
	{
		return;
	}
	Debug("RQ_C_EX_WORLD_EXCHANGE_ITEM_LIST");
	Class'UIPacket'.RequestUIPacket(Class'UIPacket'.782,stream);
}

function RT_S_EX_WORLD_EXCHANGE_ITEM_LIST ()
{
	local _S_EX_WORLD_EXCHANGE_ITEM_LIST packet;

	if (  !m_hOwnerWnd.IsShowWindow() )
	{
		return;
	}
	if (  !Class'UIPacket'.Decode_S_EX_WORLD_EXCHANGE_ITEM_LIST(packet) )
	{
		return;
	}
	Debug("Handle_S_EX_WORLD_EXCHANGE_ITEM_LIST" @ string(_itemDatas.Length));
	if ( lastLoadedPage == 0 )
	{
		_itemDatas.Length=0;
		ExchangeFind_RichList.DeleteAllItem();
		FindDisable_Wnd.ShowWindow();
		nMaxPage=0;
	}
	if ( packet.vItemDataList.Length == 100 )
	{
		++nMaxPage;
	} else {
		nMaxPage=lastLoadedPage;
	}
	Handle_S_EX_WORLD_EXCHANGE_ITEM_LIST(packet);
}

function Handle_S_EX_WORLD_EXCHANGE_ITEM_LIST (_S_EX_WORLD_EXCHANGE_ITEM_LIST packet)
{
	local int i;

	Debug("Handle_S_EX_WORLD_EXCHANGE_ITEM_LIST");
	if ( packet.vItemDataList.Length == 0 )
	{
		return;
	}
	FindDisable_Wnd.HideWindow();
	i=0;
JL0055:
	if ( i < packet.vItemDataList.Length )
	{
		_itemDatas[_itemDatas.Length]=packet.vItemDataList[i];
		i++;
		goto JL0055;
	}
	tObjectListAdd._Reset();
}

function RQ_C_EX_WORLD_EXCHANGE_REGI_ITEM ()
{
	local array<byte> stream;
	local _C_EX_WORLD_EXCHANGE_REGI_ITEM packet;

	packet.nItemSid=sellItemInfo.Id.ServerID;
	packet.nAmount=itemSell_NumberInputScr.GetCount();
	packet.nPrice=bundlePrice_NumberInputScr.GetCount();
	if (  !Class'UIPacket'.Encode_C_EX_WORLD_EXCHANGE_REGI_ITEM(stream,packet) )
	{
		return;
}

function RT_S_EX_WORLD_EXCHANGE_REGI_ITEM ()
{
	local _S_EX_WORLD_EXCHANGE_REGI_ITEM packet;

	Debug("RT_S_EX_WORLD_EXCHANGE_REGI_ITEM");
	if (  !Class'UIPacket'.Decode_S_EX_WORLD_EXCHANGE_REGI_ITEM(packet) )
	{
		return;
	}
	Debug("packet.cSuccess" @ string(packet.cSuccess));
	if ( packet.cSuccess == 1 )
	{
		DelItemInfo();
		historyScr.RQ_C_EX_WORLD_EXCHANGE_SETTLE_LIST();
	} else {
		getInstanceL2Util().showGfxScreenMessage(GetSystemMessage(4334));
	}
}

function _ShowDisableWIndow ()
{
	WindowDisable_Wnd.ShowWindow();
	WindowDisable_Wnd.SetFocus();
}

function _HideDisableWindow ()
{
	WindowDisable_Wnd.HideWindow();
}

function SetDisablbRefresh ()
{
	bRQ_C_EX_WORLD_EXCHANGE_ITEM_LIST=True;
	_ShowDisableWIndow();
	tObject._Reset();
}

function SetEnableRefresh ()
{
	bRQ_C_EX_WORLD_EXCHANGE_ITEM_LIST=False;
	WindowDisable_Wnd.HideWindow();
}

function SetItemInfo ()
{
	local ItemWindowHandle Item_ItemWnd;

	Item_ItemWnd=GetItemWindowHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".RegiTabWnd.ItemRegi_Wnd.Item_ItemWnd");
	Item_ItemWnd.Clear();
	sellItemInfo.bShowCount=IsStackableItem(sellItemInfo.ConsumeType);
	Item_ItemWnd.AddItem(sellItemInfo);
	itemSell_NumberInputScr.SetCount(sellItemInfo.ItemNum);
	itemSell_NumberInputScr._SetForceDisable(False);
	bundlePrice_NumberInputScr._SetForceDisable(False);
	GetButtonHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".Refresh_btn").EnableWindow();
	RQ_C_EX_WORLD_EXCHANGE_ITEM_LIST(0);
	GetTextBoxHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".RegiTabWnd.ItemRegi_Wnd.SellTime_txt").SetText(GetSystemString(14084));
}

function DelItemInfo ()
{
	local ItemInfo emptyInfo;

	GetItemWindowHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".RegiTabWnd.ItemRegi_Wnd.Item_ItemWnd").Clear();
	itemSell_NumberInputScr._SetForceDisable(True);
	bundlePrice_NumberInputScr._SetForceDisable(True);
	if ( JointIndex(itemSell_NumberInputScr.GetCount(),0) )
	{
		itemSell_NumberInputScr.SetCount(0);
	}
	if ( JointIndex(bundlePrice_NumberInputScr.GetCount(),0) )
	{
		bundlePrice_NumberInputScr.SetCount(0);
	}
	Get_UnitPriceCount_Txt().SetText("0");
	Get_RegiFeePiceCount_Txt().SetText("0" @ GetSystemString(469));
	Get_RegiFeePiceCount_TxtUnit_Txt().SetText("");
	Get_SellFeePiceCount_Txt().SetText("0" @ GetSystemString(3931));
	Get_UnitPriceCount_Txt().SetText("0");
	GetButtonHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".RegiTabWnd.ItemRegi_Wnd.GetReward_Btn").DisableWindow();
	sellItemInfo=emptyInfo;
	lastLoadedPage=0;
	ExchangeFind_RichList.DeleteAllItem();
	FindDisable_Wnd.ShowWindow();
	tObjectListAdd._Stop();
	GetButtonHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".Refresh_btn").DisableWindow();
	GetTextBoxHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".RegiTabWnd.ItemRegi_Wnd.SellTime_txt").SetText("-");
}

function INT64 GetCanSellItemNum ()
{
	return GetSellItemInfoNum(sellItemInfo.Id.ServerID);
}

function INT64 GetSellItemInfoNum (int sererID)
{
	local ItemInfo iInfo;

	if ( Class'UIDATA_INVENTORY'.FindItem(sellItemInfo.Id.ServerID,iInfo) )
	{
		return Min64(1,iInfo.ItemNum);
	}
	return 0;
}

function INT64 GetCanLcoinPriceItemNum ()
{
	local WorldExchangeUIData tmpWorldExchangeUIData;

	tmpWorldExchangeUIData=API_GetWorldExchangeData();
	if ( NumJoints(GetAdena(),tmpWorldExchangeUIData.MaxSellFee) )
	{
		return 2147483647;
	}
	return UnknownFunction403(GetAdena(),tmpWorldExchangeUIData.RegistFee);
}

function INT64 GetCommitionRegist ()
{
	local WorldExchangeUIData tmpWorldExchangeUIData;

	tmpWorldExchangeUIData=API_GetWorldExchangeData();
	return Min64(tmpWorldExchangeUIData.MaxSellFee,UnknownFunction401(bundlePrice_NumberInputScr.GetCount(),tmpWorldExchangeUIData.RegistFee));
}

function int GetCommitionSell ()
{
	local WorldExchangeUIData tmpWorldExchangeUIData;

	tmpWorldExchangeUIData=API_GetWorldExchangeData();
}

function bool CanSell ()
{
	return NumJoints(GetAdena(),GetCommitionRegist());
}

function _GetSellItemInfo (out ItemInfo ItemInfo)
{
	ItemInfo=sellItemInfo;
}

function HandleScrollMove (optional int pos)
{
	scrollPos=pos;
	if ( bRQ_C_EX_WORLD_EXCHANGE_ITEM_LIST )
	{
		return;
	}
	if ( pos == ExchangeFind_RichList.GetRecordCount() - ExchangeFind_RichList.GetShowRow() )
	{
		RQ_C_EX_WORLD_EXCHANGE_ITEM_LIST(lastLoadedPage + 1);
	}
}

function TInsertRecordOnTime (int Count)
{
	TInsertRecord();
}

function TInsertRecord ()
{
	local RichListCtrlRowData RowData;

	if ( _itemDatas.Length == 0 )
	{
		tObjectListAdd._Stop();
	}
	if ( MakeRowData(_itemDatas[0],RowData) )
	{
		ExchangeFind_RichList.InsertRecord(RowData);
		_itemDatas.Remove (0,1);
	}
}

function TInserDelayCheck ()
{
	HandleScrollMove(scrollPos);
}

function bool MakeRowData (_WorldExchangeItemData _itemData, out RichListCtrlRowData outRowData)
{
	local RichListCtrlRowData RowData;
	local ItemInfo iInfo;
	local string strcom;
	local string itemParam;

	RowData.cellDataList.Length=2;
	if ( _itemData.nItemClassID < 1 )
	{
		return False;
	}
	if (  !Class'UIDATA_ITEM'.GetItemInfo(GetItemID(_itemData.nItemClassID),iInfo) )
	{
		return False;
	}
	RowData.nReserved1=_itemData.nWEIndex;
	RowData.nReserved2=ExchangeFind_RichList.GetRecordCount();
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

function HandleDialogOKSource ()
}

function HandleDialogOKDrop ()
{
	local INT64 ItemNum;
}

function HandleDialogOkEdit ()
{
	local INT64 ItemNum;
}

function HandleDialogOKPrice ()
{
	local INT64 ItemNum;
}

function HandleGetRewardBtn ()
{
	SetSellPopupInfos();
}

function SetSellPopupInfos ()
{
	local string popupPath;

	popupPath=m_hOwnerWnd.m_WindowNameWithFullPath $ ".ItemRegiDialog_Wnd";
	GetWindowHandle(popupPath).ShowWindow();
	GetItemWindowHandle(popupPath $ ".Dialog_Wnd.Item_ItemWnd").Clear();
	GetItemWindowHandle(popupPath $ ".Dialog_Wnd.Item_ItemWnd").AddItem(sellItemInfo);
}

function SetHideSellDialogWindow ()
{
	local string popupPath;

	popupPath=m_hOwnerWnd.m_WindowNameWithFullPath $ ".ItemRegiDialog_Wnd";
	GetWindowHandle(popupPath).HideWindow();
}

function _Show ()
{
	m_hOwnerWnd.ShowWindow();
	m_hOwnerWnd.SetFocus();
}

function _Hide ()
{
	m_hOwnerWnd.HideWindow();
}

function handleSwap ()
{
	Debug("HandleSwap");
	Class'WorldExchangeBuyWnd'.Inst()._Show();
	getInstanceL2Util().syncWindowLoc(m_hOwnerWnd.m_WindowNameWithFullPath,"WorldExchangeBuyWnd");
}

function HandleRefresh ()
{
	RQ_C_EX_WORLD_EXCHANGE_ITEM_LIST();
}

function CheckWorldExchangeRegiSubWnd ()
{
	if ( GetTabHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".RegiList_Tab").GetTopIndex() == 0 )
	{
		Class'WorldExchangeRegiSubWnd'.Inst()._Show();
	} else {
		Class'WorldExchangeRegiSubWnd'.Inst()._Hide();
	}
}

function SetMyInfos ()
{
	local array<ItemInfo> iInfos;
}

function HandleMyItemChanged (optional array<ItemInfo> iInfos, optional int Index)
{
	SetMyInfos();
}

function HandleOnitemCountEdited (INT64 changedNum)
{
	local ItemWindowHandle Item_ItemWnd;
	local string commitionRegist;
}

function HandleOnPriceCountEdited (INT64 changedNum)
{
	local string commitionRegist;
}

function HandleOnOverInput ()
{
	getInstanceL2Util().showGfxScreenMessage(GetSystemString(13448));
}

function HandleOnItemCountEditBtonClicked ()
{
	DialogShow(1,6,MakeFullSystemMsg(GetSystemMessage(72),sellItemInfo.Name,""),string(self));
	DialogSetInputlimit(GetSellItemInfoNum(readySellItemInfo.Id.ServerID));
	DialogSetParamInt64(1);
}

function HandleOnPriceCountEditBtonClicked ()
{
	DialogShow(1,6,GetSystemMessage(322),string(self));
	DialogSetInputlimit(GetCanLcoinPriceItemNum());
	DialogSetParamInt64(2147483647);
}

function CheckGetRewardBtn ()
{
	if ( JointName(itemSell_NumberInputScr.GetCount(),0) || (GetCommitionSell() == 0) )
	{
		GetButtonHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".RegiTabWnd.ItemRegi_Wnd.GetReward_Btn").DisableWindow();
	} else {
		GetButtonHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".RegiTabWnd.ItemRegi_Wnd.GetReward_Btn").EnableWindow();
	}
}

function _SetShowCancelDialog (string itemReservedString)
{
	local ItemInfo iInfo;
	local string CancelSaleDialogPath;

	GetWindowHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".CancelSaleDialog_Wnd").ShowWindow();
	CancelSaleDialogPath=m_hOwnerWnd.m_WindowNameWithFullPath $ ".CancelSaleDialog_Wnd.CancelSalePopUp_Wnd";
	ParamToItemInfo(itemReservedString,iInfo);
	GetTextBoxHandle(CancelSaleDialogPath $ ".ItemName_Txt").SetText(GetItemNameAll(iInfo));
	GetItemWindowHandle(CancelSaleDialogPath $ ".Result_ItemWnd").Clear();
	GetItemWindowHandle(CancelSaleDialogPath $ ".Result_ItemWnd").AddItem(iInfo);
}

function _SetCurrentRigedItemNum (int Num)
{
	_regieditemNum=Num;
	GetTextBoxHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".RegiTabWnd.ItemRegi_Wnd.RegiItemNumTxt_Apply").SetText(string(Num));
	GetTextBoxHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".RegiTabWnd.ItemRegi_Wnd.RegiItemNumTxt_Total").SetText("/" $ string(10));
	if ( Num == 10 )
	{
		GetWindowHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".RegiTabWnd.ItemRegi_Wnd.ItemFullDisable_Wnd").ShowWindow();
	} else {
		GetWindowHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".RegiTabWnd.ItemRegi_Wnd.ItemFullDisable_Wnd").HideWindow();
	}
}

function HandleCancelOK ()
{
	historyScr._RQ_C_EX_WORLD_EXCHANGE_SETTLE_RECV_RESULT();
}

function HandleCancelCancel ()
{
	GetWindowHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".CancelSaleDialog_Wnd").HideWindow();
}

function bool IsShowHistory ()
{
	local TabHandle regilistTab;

	regilistTab=GetTabHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".RegiList_Tab");
	return m_hOwnerWnd.IsShowWindow() && (regilistTab.GetTopIndex() == 1);
}

function _CheckOnClickNoticeBtn ()
{
	local TabHandle regilistTab;

	regilistTab=GetTabHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".RegiList_Tab");
	if ( IsShowHistory() )
	{
		m_hOwnerWnd.HideWindow();
	} else {
		_Show();
		regilistTab.SetTopOrder(1,True);
	}
	CheckWorldExchangeRegiSubWnd();
}

function int GetSortType ()
{
	switch (sortHeaderIndex)
	{
		case 0:
		if ( ExchangeFind_RichList.IsAscending(sortHeaderIndex) )
		{
			return 2;
		} else {
			return 3;
		}
		case 1:
		if ( ExchangeFind_RichList.IsAscending(sortHeaderIndex) )
		{
			return 4;
		} else {
			return 5;
		}
		default:
	}
	return 2;
}

function SetSortByHeaderIndex (int Index)
{
	Debug("SetSortByHeaderIndex" @ string(Index));
	switch (Index)
	{
		case 0:
		if ( ExchangeFind_RichList.IsAscending(Index) )
		{
			SetSortType(3);
		} else {
			SetSortType(2);
		}
		break;
		case 1:
		if ( ExchangeFind_RichList.IsAscending(Index) )
		{
			SetSortType(5);
		} else {
			SetSortType(4);
		}
		break;
		default:
		SetSortType(2);
		break;
	}
}

function SetSortType (E_WORLD_EXCHANGE_SORT_TYPE sortType)
{
	local bool bAscend;

	Debug("SetSortType" @ string(sortType));
	switch (sortType)
	{
		case 2:
		sortHeaderIndex=0;
		bAscend=True;
		break;
		case 3:
		sortHeaderIndex=0;
		bAscend=False;
		break;
		case 4:
		sortHeaderIndex=1;
		bAscend=True;
		break;
		case 5:
		sortHeaderIndex=1;
		bAscend=False;
		break;
		default:
		sortHeaderIndex=0;
		bAscend=True;
		break;
	}
	ExchangeFind_RichList.SetAscend(sortHeaderIndex,bAscend);
	ExchangeFind_RichList.ShowSortIcon(sortHeaderIndex);
}

function _SetUnity (float unitPrice)
{
	local string unitPriceStr;

	unitPriceStr=Class'WorldExchangeBuyWnd'.Inst().MakeUintString(unitPrice);
	Get_UnitPriceCount_Txt().SetText(unitPriceStr);
}

function TextBoxHandle Get_UnitPriceCount_Txt ()
{
	return GetTextBoxHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".RegiTabWnd.ItemRegi_Wnd.UnitPriceCount_Txt");
}

function TextBoxHandle Get_RegiFeePiceCount_Txt ()
{
	return GetTextBoxHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".RegiTabWnd.ItemRegi_Wnd.RegiFeePiceCount_Txt");
}

function TextBoxHandle Get_RegiFeePiceCount_TxtUnit_Txt ()
{
	return GetTextBoxHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".RegiTabWnd.ItemRegi_Wnd.RegiFeePiceCount_TxtUnit_Txt");
}

function TextBoxHandle Get_SellFeePiceCount_Txt ()
{
	return GetTextBoxHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".RegiTabWnd.ItemRegi_Wnd.SellFeePiceCount_Txt");
}

function TextBoxHandle Get_MyAdenaCount_Txt ()
{
	return GetTextBoxHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".RegiTabWnd.ItemRegi_Wnd.MyAdenaCount_Txt");
}

function TextBoxHandle Get_MyLcoinCount_Txt ()
{
	return GetTextBoxHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".RegiTabWnd.ItemRegi_Wnd.MyLcoinCount_Txt");
}

event OnReceivedCloseUI ()
{
	local string popupPath;

	popupPath=m_hOwnerWnd.m_WindowNameWithFullPath $ ".ItemRegiDialog_Wnd";
	if ( GetWindowHandle(popupPath).IsShowWindow() )
	{
		SetHideSellDialogWindow();
	} else {
		PlayConsoleSound(6);
		_Hide();
	}
}