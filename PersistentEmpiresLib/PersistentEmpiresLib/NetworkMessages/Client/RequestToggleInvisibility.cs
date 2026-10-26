using TaleWorlds.MountAndBlade;
using TaleWorlds.MountAndBlade.Network.Messages;

namespace PersistentEmpiresLib.NetworkMessages.Client
{
    [DefineGameNetworkMessageTypeForMod(GameNetworkMessageSendType.FromClient)]
    public sealed class RequestToggleInvisibility : GameNetworkMessage
    {
    	public bool IsVisible;

    	public RequestToggleInvisibility()
    	{
    	}

    	public RequestToggleInvisibility(bool isVivible)
    	{
    		IsVisible = isVivible;
    	}

    	protected override MultiplayerMessageFilter OnGetLogFilter()
    	{
    		return MultiplayerMessageFilter.Administration;
    	}

    	protected override string OnGetLogFormat()
    	{
    		return "Received RequestToggleInvisibility";
    	}

    	protected override bool OnRead()
    	{
    		bool bufferReadValid = true;
    		IsVisible = GameNetworkMessage.ReadBoolFromPacket(ref bufferReadValid);
    		return bufferReadValid;
    	}

    	protected override void OnWrite()
    	{
    		GameNetworkMessage.WriteBoolToPacket(IsVisible);
    	}
    }
}
