//================================================================================
// WorldExchangeBuyWnd.
//================================================================================
class WorldExchangeBuyWnd extends UICommonAPI;

var int lastLoadedPage;
var int nMaxPage;
var bool bRQ_C_EX_WORLD_EXCHANGE_ITEM_LIST;
var array<_WorldExchangeItemData> _itemDatas;
var L2UITimerObject tObjectListAdd;
var UIControlTextInput uicontrolTextInputScr;
var RichListCtrlHandle List_RichList;
var WindowHandle itemBuyDialog_Wnd;
var WindowHandle ItemBuyPopUp_Wnd;
var WindowHandle ItemBuyResultPopUp_Wnd;
var WindowHandle FindDisable_Wnd;
var string lastFindString;
var array<int> ItemList;
var bool bFirst;
var int scrollPos;
var int requestedScrollPos;
var UIControlGroupButtonAssets TopGroupButtonAsset;
var UIControlGroupButtonAssets SubGroupButtonAsset;
var INT64 nWEIndex;
var int sortHeaderIndex;
var array<categoryStruct> categoryArray;
var delegate __OnSortCompareByName__Delegate;
struct categoryStruct
{
	var int subSelectedIndex;
	var array<int> subCategoryStringArray;
	var array<int> subCategoryKeyArray;
};

enum E_WORLD_EXCHANGE_SORT_TYPE {
	EWEST_NONE,
	EWEST_ITEM_NAME,
	EWEST_ENCHANT_ASCE,
	EWEST_ENCHANT_DESC,
	EWEST_PRICE_ASCE,
	EWEST_PRICE_DESC
};

enum ItemSubtype {
	Weapon,
	Armor,
	Accessary,
	EtcEquipment,
	ArtifactB1,
	ArtifactC1,
	ArtifactD1,
	ArtifactA1,
	ENCHANTSCROLL,
	BlessEnchantScroll,
	MultiEnchantScroll,
	AncientEnchantScroll,
	Spiritshot,
	Soulshot,
	Buff,
	VariationStone,
	dye,
	SoulCrystal,
	SkillBook,
	EtcEnchant,
	PotionAndEtcScroll,
	ticket,
	Craft,
	IncEnchantProp,
	EtcSubtype
};

enum ItemMainType {
	Equipment,
	Artifact,
	Enchant,
	Consumable,
	EtcType,
	Collection
};

const MAIN_TAB_MAX= 3;
const RESTARTPOINTITEM_LCOIN= 99422;
const COLLECTION_ITEM_TYPE= 10000;
const REFRESHLIMIT= 1000;

static function WorldExchangeBuyWnd Inst ()
{
	return WorldExchangeBuyWnd(GetScript("WorldExchangeBUyWNd"));
}

event OnRegisterEvent ()
{
	RegisterEvent(40);
	RegisterEvent(EV_PacketID(Class'UIPacket'.1020));
	RegisterEvent(EV_PacketID(Class'UIPacket'.1022));
}

function OnLoad ()
{
	SetClosingOnESC();
	itemBuyDialog_Wnd=GetWindowHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".ItemBuyDialog_Wnd");
	ItemBuyPopUp_Wnd=GetWindowHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".ItemBuyDialog_Wnd.ItemBuyPopUp_Wnd");
	ItemBuyResultPopUp_Wnd=GetWindowHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".ItemBuyDialog_Wnd.ItemBuyResultPopUp_Wnd");
	FindDisable_Wnd=GetWindowHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".FindDisable_Wnd");
	FindDisable_Wnd.ShowWindow();
	ShowBuyResultPopup();
	List_RichList=GetRichListCtrlHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".List_RichList");
	List_RichList.SetSelectedSelTooltip(False);
	List_RichList.SetAppearTooltipAtMouseX(True);
	List_RichList.SetSortable(False);
	uicontrolTextInputScr=Class'UIControlTextInput'.InitScript(GetWindowHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".ItemFind_Wnd.TextInput"));
	uicontrolTextInputScr.__DelegateESCKey__Delegate
	bool(switch (uicontrolTextInputScr.__DelegateOnChangeEdited__Delegate))
	{
		bool(assert (uicontrolTextInputScr));
		switch (stop)
		{
			__DelegateOnCompleteEditBox__Delegate
			if ( uicontrolTextInputScr )
			{
				switch (stop)
				{
					__DelegateOnClear__Delegate
					vector("~")
}

event OnClickHeaderCtrl (string strID, int Index)
{
	if ( bRQ_C_EX_WORLD_EXCHANGE_ITEM_LIST )
	{
		return;
	}
	SetSortByHeaderIndex(Index);
	if ( (Index == 0) || (Index == 3) )
	{
		if ( Index == 0 )
		{
			DelegateOnCompleteEditBox(uicontrolTextInputScr.GetString());
		}
		RQ_C_EX_WORLD_EXCHANGE_ITEM_LIST();
	}
}

event OnEvent (int EventID, string param)
{
	switch (EventID)
	{
		case 40:
		break;
		case EV_PacketID(Class'UIPacket'.1020):
		RT_S_EX_WORLD_EXCHANGE_ITEM_LIST();
		break;
		case EV_PacketID(Class'UIPacket'.1022):
		RT_S_EX_WORLD_EXCHANGE_BUY_ITEM();
		break;
		default:
		break;
	}
}

event OnShow ()
{
	if (  !CheckOpenCondition() )
	{
		m_hOwnerWnd.HideWindow();
		return;
	}
	if (  !bFirst )
	{
		TopGroupButtonAsset._GetGroupButtonsInstance()._setTopOrder(0);
		SetGroupButtonCategorySub(0);
		SubGroupButtonAsset._GetGroupButtonsInstance()._setTopOrder(0);
		TopGroupButtonAsset._GetGroupButtonsInstance()._SetDisable(3);
		GetTextureHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".TabIcon04_Tex").SetAlpha(100,0.50);
		bFirst=True;
	}
	Class'WorldExchangeRegiWnd'.Inst()._Hide();
	HideBuyDialog();
	getInstanceL2Util().ItemRelationWindowHide(getCurrentWindowName(string(self)));
	if ( bRQ_C_EX_WORLD_EXCHANGE_ITEM_LIST )
	{
		tObjectListAdd._Reset();
	}
}

event OnClickButton (string strID)
{
	switch (strID)
	{
		case "WndClose_BTN":
		_Hide();
		break;
		case "Refresh_btn":
		HandleBtnRefresh();
		break;
		case "BtnFind":
		HandleBtnFind();
		break;
		case "MoveWnd_Btn":
		HandleBtnSwap();
		break;
		case "Cancel_Btn":
		HideBuyDialog();
		break;
		case "Ok_Btn":
		RQ_C_EX_WORLD_EXCHANGE_BUY_ITEM();
		HideBuyDialog();
		break;
		case "OkResult_Btn":
		HideBuyDialog();
		break;
		default:
		ChckBtnName(strID);
		break;
		break;
	}
}

function OnDBClickListCtrlRecord (string ListCtrlID)
{
	local RichListCtrlRowData RowData;

}

event OnScrollMove (string strID, int pos)
{
	switch (strID)
	{
		case "List_RichList":
		HandleScrollMove(pos);
		break;
		default:
	}
}

function initGroupButton ()
{
	TopGroupButtonAsset=Class'UIControlGroupButtonAssets'._InitScript(GetWindowHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".UIControlGroupButtonAsset1"));
	TopGroupButtonAsset._SetStartInfo("L2UI_EPIC.PrivateShopFindWnd.PrivateShopFindWnd_Tab_Center_Unselected","L2UI_EPIC.PrivateShopFindWnd.PrivateShopFindWnd_Tab_Center_Selected","L2UI_EPIC.PrivateShopFindWnd.PrivateShopFindWnd_Tab_Center_Unselected_Over",True);
	SubGroupButtonAsset=Class'UIControlGroupButtonAssets'._InitScript(GetWindowHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".SubUIControlGroupButtonAsset"));
	SubGroupButtonAsset._SetStartInfo("L2UI_ct1.RankingWnd.RankingWnd_SubTabButton","L2UI_ct1.RankingWnd.RankingWnd_SubTabButton_Down","L2UI_ct1.RankingWnd.RankingWnd_SubTabButton_Over",True);
	TopGroupButtonAsset._GetGroupButtonsInstance().__DelegateOnClickButton__Delegate;
	int(string(SubGroupButtonAsset._GetGroupButtonsInstance().__DelegateOnClickButton__Delegate));
}

function SetMainCategoryButtons ()
{
	local UIControlGroupButtons mainGroupBtnScr;

	mainGroupBtnScr=TopGroupButtonAsset._GetGroupButtonsInstance();
	mainGroupBtnScr._setButtonText(0,GetSystemString(116));
	mainGroupBtnScr._setButtonValue(0,0);
	mainGroupBtnScr._setButtonText(1,GetSystemString(2066));
	mainGroupBtnScr._setButtonValue(1,2);
	mainGroupBtnScr._setButtonText(2,GetSystemString(13891));
	mainGroupBtnScr._setButtonValue(2,3);
	mainGroupBtnScr._setButtonText(3,GetSystemString(13476));
	mainGroupBtnScr._setButtonValue(3,5);
	mainGroupBtnScr._setShowButtonNum(4);
	mainGroupBtnScr._setAutoWidth(958,0);
	mainGroupBtnScr._setButtonTexture(3,"L2UI_EPIC.PrivateShopFindWnd.PrivateShopFindWnd_Tab_Right_Unselected","L2UI_EPIC.PrivateShopFindWnd.PrivateShopFindWnd_Tab_Right_Selected","L2UI_EPIC.PrivateShopFindWnd.PrivateShopFindWnd_Tab_Right_Unselected_Over");
}

function AddSubCategoryData (int mainIndex, int Key, int stringNum)
{
	local int subIndex;
	local categoryStruct Data;

	Data=categoryArray[mainIndex];
	subIndex=Data.subCategoryKeyArray.Length;
	Data.subCategoryKeyArray[subIndex]=Key;
	Data.subCategoryStringArray[subIndex]=stringNum;
	categoryArray[mainIndex]=Data;
}

function SetSubCategoryData ()
{
	AddSubCategoryData(0,0,2520);
	AddSubCategoryData(0,1,2532);
	AddSubCategoryData(0,2,2537);
	AddSubCategoryData(0,3,49);
	AddSubCategoryData(1,0,0);
	AddSubCategoryData(2,8,1532);
	AddSubCategoryData(2,17,2554);
	AddSubCategoryData(2,15,2553);
	AddSubCategoryData(2,16,25);
	AddSubCategoryData(2,18,2558);
	AddSubCategoryData(2,19,49);
	AddSubCategoryData(1,0,0);
	AddSubCategoryData(3,20,13848);
	AddSubCategoryData(3,21,5834);
	AddSubCategoryData(3,22,13892);
	AddSubCategoryData(3,24,49);
	AddSubCategoryData(4,0,0);
	AddSubCategoryData(5,0,116);
	AddSubCategoryData(5,2,13846);
	AddSubCategoryData(5,4,49);
}

function SetGroupButtonCategorySub (int mainIndex)
{
	local int i;
	local int Len;
	local UIControlGroupButtons subGroupBtnScr;

	subGroupBtnScr=SubGroupButtonAsset._GetGroupButtonsInstance();
	Len=categoryArray[mainIndex].subCategoryStringArray.Length;
	subGroupBtnScr._setShowButtonNum(Len);
	subGroupBtnScr._fixedWidth(110,5);
	i=0;
JL005A:
	if ( i < Len )
	{
		subGroupBtnScr._setButtonText(i,GetSystemString(categoryArray[mainIndex].subCategoryStringArray[i]));
		subGroupBtnScr._setButtonValue(i,categoryArray[mainIndex].subCategoryKeyArray[i]);
		i++;
		goto JL005A;
	}
	subGroupBtnScr._setTopOrder(categoryArray[mainIndex].subSelectedIndex);
}

function DelegateOnClickButtonSub (string parentWndName, string strName, int subIndex)
{
	local int topButtonGroupIndex;

	topButtonGroupIndex=GetCurrentMainType();
	categoryArray[topButtonGroupIndex].subSelectedIndex=subIndex;
	RQ_C_EX_WORLD_EXCHANGE_ITEM_LIST();
}

function DelegateOnClickButtonTop (string parentWndName, string strName, int mainIndex)
{
	local int topButtonGroupIndex;

	topButtonGroupIndex=GetCurrentMainType();
	SetGroupButtonCategorySub(topButtonGroupIndex);
}

function HandleClear ()
{
	lastFindString="";
	ItemList.Length=0;
	RQ_C_EX_WORLD_EXCHANGE_ITEM_LIST();
}

function DelegateESCKey ()
{
	Debug(" Esc 체크 ");
	OnReceivedCloseUI();
}

function DelegateOnClear ()
{
	HandleClear();
}

function DelegateOnChangeEdited (string Text)
{
	if ( lastFindString == Text )
	{
		GetButtonHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".ItemFind_Wnd.BtnFind").DisableWindow();
	} else {
		GetButtonHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".ItemFind_Wnd.BtnFind").EnableWindow();
	}
}

function bool CheckFindString (string Text, out array<int> _itemList)
{
	if ( Text == "" )
	{
		return True;
	}
	API_GetStringMatchingItemList(Text," ",1,List_RichList.IsAscending(0),_itemList);
	return _itemList.Length > 0;
}

function DelegateOnCompleteEditBox (string Text)
{
	local array<int> _itemList;

	if (  !CheckFindString(Text,_itemList) )
	{
		Class'L2Util'.Inst().showGfxScreenMessage("&#34;" $ Text $ "&#34;" $ GetSystemMessage(4356));
		return;
	}
	lastFindString=Text;
	ItemList=_itemList;
	RQ_C_EX_WORLD_EXCHANGE_ITEM_LIST();
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

function HandleBtnSwap ()
{
	_Hide();
	Class'WorldExchangeRegiWnd'.Inst()._Show();
	getInstanceL2Util().syncWindowLoc(m_hOwnerWnd.m_WindowNameWithFullPath,"WorldExchangeRegiWnd");
}

function HandleBtnRefresh ()
{
	RQ_C_EX_WORLD_EXCHANGE_ITEM_LIST();
}

function HandleBtnFind ()
{
	DelegateOnCompleteEditBox(uicontrolTextInputScr.GetString());
}

function HandleScrollMove (optional int pos)
{
	scrollPos=pos;
	if ( bRQ_C_EX_WORLD_EXCHANGE_ITEM_LIST )
	{
		return;
	}
	Debug("HandleScrollMove" @ string(pos) @ string(List_RichList.GetRecordCount()) @ string(List_RichList.GetShowRow()) @ string(lastLoadedPage) @ string(nMaxPage));
	if ( pos == List_RichList.GetRecordCount() - List_RichList.GetShowRow() )
	{
		RQ_C_EX_WORLD_EXCHANGE_ITEM_LIST(lastLoadedPage + 1);
	}
}

function SetDisablbRefresh ()
{
	local int i;

	bRQ_C_EX_WORLD_EXCHANGE_ITEM_LIST=True;
	GetButtonHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".Refresh_btn").DisableWindow();
	GetButtonHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".ItemFind_Wnd.BtnFind").DisableWindow();
	uicontrolTextInputScr.SetDisable(True);
	TopGroupButtonAsset._SetDisable();
	SubGroupButtonAsset._SetDisable();
	GetButtonHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".MoveWnd_Btn").DisableWindow();
	i=1;
JL00D0:
	if ( i <= 3 )
	{
		if ( TopGroupButtonAsset._GetGroupButtonsInstance()._getSelectButtonIndex() + 1 != i )
		{
			GetTextureHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".TabIcon0" $ string(i) $ "_Tex").SetAlpha(100,0.50);
		} else {
			GetTextureHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".TabIcon0" $ string(i) $ "_Tex").SetAlpha(180,0.50);
		}
		i++;
		goto JL00D0;
	}
	tObjectListAdd._Reset();
}

function SetEnableRefresh ()
{
	local int i;

	bRQ_C_EX_WORLD_EXCHANGE_ITEM_LIST=False;
	GetButtonHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".Refresh_btn").EnableWindow();
	if ( lastFindString != uicontrolTextInputScr.GetString() )
	{
		GetButtonHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".ItemFind_Wnd.BtnFind").EnableWindow();
	}
	uicontrolTextInputScr.SetDisable(False);
	TopGroupButtonAsset._SetEnable();
	SubGroupButtonAsset._SetEnable();
	GetButtonHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".MoveWnd_Btn").EnableWindow();
	i=1;
JL00E9:
	if ( i <= 3 )
	{
		GetTextureHandle(m_hOwnerWnd.m_WindowNameWithFullPath $ ".TabIcon0" $ string(i) $ "_Tex").SetAlpha(255,0.50);
		i++;
		goto JL00E9;
	}
}

function int GetSortType ()
{
	switch (sortHeaderIndex)
	{
		case 0:
		if ( List_RichList.IsAscending(sortHeaderIndex) )
		{
			return 2;
		} else {
			return 3;
		}
		case 3:
		if ( List_RichList.IsAscending(sortHeaderIndex) )
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
	switch (Index)
	{
		case 0:
		if ( List_RichList.IsAscending(Index) )
		{
			SetSortType(3);
		} else {
			SetSortType(2);
		}
		break;
		case 1:
		case 2:
		return;
		case 3:
		if ( List_RichList.IsAscending(Index) )
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
		sortHeaderIndex=3;
		bAscend=True;
		break;
		case 5:
		sortHeaderIndex=3;
		bAscend=False;
		break;
		default:
		sortHeaderIndex=0;
		bAscend=True;
		break;
	}
	List_RichList.SetAscend(sortHeaderIndex,bAscend);
	List_RichList.ShowSortIcon(sortHeaderIndex);
}

delegate int OnSortCompareByName (int classIDA, int classIDB)
{
	if ( Class'UIDATA_ITEM'.GetItemName(GetItemID(classIDA)) < Class'UIDATA_ITEM'.GetItemName(GetItemID(classIDB)) )
	{
		return -1;
	} else {
		return 0;
	}
}

function WorldExchangeUIData API_GetWorldExchangeData ()
{
	return GetWorldExchangeData();
}

function int API_GetServerNo ()
{
	return GetServerNo();
}

function API_GetStringMatchingItemList (string a_str, string a_delim, EStringMatchingItemFilter a_filter, bool a_bAscend, out array<int> o_ItemList)
{
	Class'UIDATA_ITEM'.GetStringMatchingItemList(a_str,a_delim,a_filter,a_bAscend,o_ItemList);
}

function RQ_C_EX_WORLD_EXCHANGE_ITEM_LIST (optional int Page)
{
	local array<byte> stream;
	local _C_EX_WORLD_EXCHANGE_ITEM_LIST packet;

	if ( bRQ_C_EX_WORLD_EXCHANGE_ITEM_LIST )
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
	requestedScrollPos=scrollPos;
	if ( _itemDatas.Length > 0 )
	{
		return;
	}
	uicontrolTextInputScr.SetString(lastFindString);
	SetDisablbRefresh();
	lastLoadedPage=Page;
	packet.nCategory=GetCurrentSubType();
	packet.cSortType=GetSortType();
	packet.nPage=Page;
	packet.vItemIDList=ItemList;
	if (  !Class'UIPacket'.Encode_C_EX_WORLD_EXCHANGE_ITEM_LIST(stream,packet) )
	{
		return;
	}
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
	if ( lastLoadedPage == 0 )
	{
		_itemDatas.Length=0;
		List_RichList.DeleteAllItem();
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

	Debug("Handle_S_EX_WORLD_EXCHANGE_ITEM_LIST" @ string(packet.vItemDataList.Length));
	tObjectListAdd._Reset();
	if ( packet.vItemDataList.Length == 0 )
	{
		return;
	}
	FindDisable_Wnd.HideWindow();
	i=0;
JL0073:
	if ( i < packet.vItemDataList.Length )
	{
		_itemDatas[_itemDatas.Length]=packet.vItemDataList[i];
		i++;
		goto JL0073;
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
		return;
	}
	if ( MakeRowData(_itemDatas[0],RowData) )
	{
		List_RichList.InsertRecord(RowData);
		_itemDatas.Remove (0,1);
	}
}

function TInserDelayCheck ()
{
	Debug("타이머 종료");
	SetEnableRefresh();
	if ( requestedScrollPos != scrollPos )
	{
		HandleScrollMove(scrollPos);
	}
}

function RQ_C_EX_WORLD_EXCHANGE_BUY_ITEM ()
{
	local array<byte> stream;
	local _C_EX_WORLD_EXCHANGE_BUY_ITEM packet;

	packet.nWEIndex=nWEIndex;
	if (  !Class'UIPacket'.Encode_C_EX_WORLD_EXCHANGE_BUY_ITEM(stream,packet) )
	{
		return;
	}
	Debug("RQ_C_EX_WORLD_EXCHANGE_BUY_ITEM");
	Class'UIPacket'.RequestUIPacket(Class'UIPacket'.784,stream);
}

function RT_S_EX_WORLD_EXCHANGE_BUY_ITEM ()
{
	local _S_EX_WORLD_EXCHANGE_BUY_ITEM packet;

	Debug("RT_S_EX_WORLD_EXCHANGE_BUY_ITEM");
	if (  !Class'UIPacket'.Decode_S_EX_WORLD_EXCHANGE_BUY_ITEM(packet) )
	{
		return;
}

function int GetCurrentMainType ()
{
	local int topSelectedIndex;

	topSelectedIndex=TopGroupButtonAsset._GetGroupButtonsInstance()._getSelectButtonIndex();
	return TopGroupButtonAsset._GetGroupButtonsInstance()._getButtonValue(topSelectedIndex);
}

function int GetCurrentSubType ()
{
	local int subSelectedIndex;

	subSelectedIndex=SubGroupButtonAsset._GetGroupButtonsInstance()._getSelectButtonIndex();
	return SubGroupButtonAsset._GetGroupButtonsInstance()._getButtonValue(subSelectedIndex);
}

function bool MakeRowData (_WorldExchangeItemData _itemData, out RichListCtrlRowData outRowData)
{
	local RichListCtrlRowData RowData;
	local ItemInfo iInfo;
	local string strcom;
	local string itemParam;
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
	RemainTime=_itemData.nExpiredTime - Class'UIData'.Inst().serverStartTime - Class'UIData'.Inst().GameConnectTimeSec();
	RowData.nReserved1=_itemData.nWEIndex;
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
	iInfo.LookChangeItemName=Class'UIDATA_ITEM'.GetItemName(GetItemID(_itemData.nShapeShiftingClassId));
	iInfo.EnsoulOption[1 - 1].OptionArray[0]=_itemData.nEsoulOption[0];
	iInfo.EnsoulOption[1 - 1].OptionArray[1]=_itemData.nEsoulOption[1];
	iInfo.EnsoulOption[2 - 1].OptionArray[0]=_itemData.nEsoulOption[2];
	iInfo.IsBlessedItem=_itemData.nBlessOption == 1;
	addRichListCtrlTexture(RowData.cellDataList[0].drawitems,"l2ui_ct1.ItemWindow_DF_SlotBox_Default",36,36,8,1);
	AddRichListCtrlItem(RowData.cellDataList[0].drawitems,iInfo,32,32,-34,2);
}

function bool CheckOpenCondition ()
{
	if ( IsPlayerOnWorldRaidServer() )
	{
		getInstanceL2Util().showGfxScreenMessage(GetSystemMessage(4047));
		return False;
	}
	if (  !ChkUseableLevel() )
	{
		getInstanceL2Util().showGfxScreenMessage(MakeFullSystemMsg(GetSystemMessage(113),GetSystemString(14063)));
		return False;
	}
	if (  !ChkUseableServerID() )
	{
		getInstanceL2Util().showGfxScreenMessage(MakeFullSystemMsg(GetSystemMessage(113),GetSystemString(14063)));
		return False;
	}
	if ( GetWindowHandle("PrivateShopWndReport").IsShowWindow() )
	{
		getInstanceL2Util().showGfxScreenMessage(GetSystemMessage(4217));
		return False;
	}
	return True;
}

function bool ChkUseableServerID ()
{
	if ( GetBRWorldExchange() )
	{
		return True;
	}
	return False;
}

function bool ChkUseableLevel ()
{
	local UserInfo uInfo;

	if (  !GetPlayerInfo(uInfo) )
	{
		return False;
	}
	return uInfo.nLevel >= API_GetWorldExchangeData().UseableLevel;
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

function SetShowBuyDialogWindow (int _nWEIndex)
{
	local string popupPath;
	local RichListCtrlRowData RowData;
	local ItemInfo iInfo;
	local INT64 lcoinCount;
	local float unitPrice;

	popupPath=ItemBuyPopUp_Wnd.m_WindowNameWithFullPath;
	List_RichList.GetSelectedRec(RowData);
	if ( JointIndex(RowData.nReserved1,_nWEIndex) )
	{
		return;
	}
	ParamToItemInfo(RowData.szReserved,iInfo);
	GetItemWindowHandle(popupPath $ ".Item_ItemWnd").Clear();
	GetItemWindowHandle(popupPath $ ".Item_ItemWnd").AddItem(iInfo);
}

function string GetDecimalNnmStr (float Num)
{
	local array<string> nums;

	Split(string(Num),".",nums);
	return nums[1];
}

function string GetInt64NumStr (float Num)
{
	local array<string> nums;

	Split(string(Num),".",nums);
	return nums[0];
}

function string MakeUintString (float unitPrice)
{
	local string int64numStr;
	local string unitPricStr;

	return "-";
	int64numStr=MakeCostString(GetInt64NumStr(unitPrice));
	unitPricStr=GetDecimalNnmStr(unitPrice);
	return int64numStr $ "." $ unitPricStr;
}

function ShowBuyDialog ()
{
	itemBuyDialog_Wnd.ShowWindow();
	ItemBuyPopUp_Wnd.ShowWindow();
	ItemBuyResultPopUp_Wnd.HideWindow();
	uicontrolTextInputScr.SetDisable(True);
}

function showDisable ()
{
	itemBuyDialog_Wnd.ShowWindow();
	ItemBuyPopUp_Wnd.HideWindow();
	ItemBuyResultPopUp_Wnd.HideWindow();
	uicontrolTextInputScr.SetDisable(True);
}

function ShowBuyResultPopup ()
{
	local int SelectedIndex;
	local string popupPath;
	local ItemWindowHandle Result_ItemWnd;
	local RichListCtrlRowData RowData;
	local ItemInfo iInfo;

	SelectedIndex=List_RichList.GetSelectedIndex();
	List_RichList.GetSelectedRec(RowData);
	ParamToItemInfo(RowData.szReserved,iInfo);
	List_RichList.DeleteRecord(SelectedIndex);
	popupPath=m_hOwnerWnd.m_WindowNameWithFullPath $ ".ItemBuyDialog_Wnd.ItemBuyResultPopUp_Wnd";
	Result_ItemWnd=GetItemWindowHandle(popupPath $ ".Result_ItemWnd");
	Result_ItemWnd.Clear();
}

function HideBuyDialog ()
{
	itemBuyDialog_Wnd.HideWindow();
	uicontrolTextInputScr.SetDisable(False);
}

function HideDisable ()
{
	itemBuyDialog_Wnd.HideWindow();
	uicontrolTextInputScr.SetDisable(False);
}

event OnReceivedCloseUI ()
{
	if ( itemBuyDialog_Wnd.IsShowWindow() )
	{
		HideBuyDialog();
	} else {
		PlayConsoleSound(6);
		_Hide();
	}
}