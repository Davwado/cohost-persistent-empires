using TaleWorlds.MountAndBlade;
using TaleWorlds.MountAndBlade.Network.Messages;

namespace PersistentEmpiresLib.NetworkMessages.Server
{
    [DefineGameNetworkMessageTypeForMod(GameNetworkMessageSendType.FromServer)]
    public sealed class BroadcastChangeCustomColors : GameNetworkMessage
    {
    	public string PlayerUserId { get; private set; }

    	public int PrimaryColor { get; set; }

    	public int SecondaryColor { get; set; }

    	public BroadcastChangeCustomColors(string userid, int primaryColor, int secondaryColor)
    	{
    		PlayerUserId = userid;
    		PrimaryColor = primaryColor;
    		SecondaryColor = secondaryColor;
    	}

    	public BroadcastChangeCustomColors()
    	{
    	}

    	protected override MultiplayerMessageFilter OnGetLogFilter()
    	{
    		return MultiplayerMessageFilter.General;
    	}

    	protected override string OnGetLogFormat()
    	{
    		return "Faction added.";
    	}

    	protected override bool OnRead()
    	{
    		bool bufferReadValid = true;
    		PlayerUserId = GameNetworkMessage.ReadStringFromPacket(ref bufferReadValid);
    		PrimaryColor = GameNetworkMessage.ReadIntFromPacket(new CompressionInfo.Integer(-1, int.MaxValue, maximumValueGiven: true), ref bufferReadValid);
    		SecondaryColor = GameNetworkMessage.ReadIntFromPacket(new CompressionInfo.Integer(-1, int.MaxValue, maximumValueGiven: true), ref bufferReadValid);
    		return bufferReadValid;
    	}

    	protected override void OnWrite()
    	{
    		GameNetworkMessage.WriteStringToPacket(PlayerUserId);
    		GameNetworkMessage.WriteIntToPacket(PrimaryColor, new CompressionInfo.Integer(-1, int.MaxValue, maximumValueGiven: true));
    		GameNetworkMessage.WriteIntToPacket(SecondaryColor, new CompressionInfo.Integer(-1, int.MaxValue, maximumValueGiven: true));
    	}
    }
}
