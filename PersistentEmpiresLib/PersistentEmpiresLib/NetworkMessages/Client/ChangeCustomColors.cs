using TaleWorlds.MountAndBlade;
using TaleWorlds.MountAndBlade.Network.Messages;

namespace PersistentEmpiresLib.NetworkMessages.Client
{
    [DefineGameNetworkMessageTypeForMod(GameNetworkMessageSendType.FromClient)]
    public sealed class ChangeCustomColors : GameNetworkMessage
    {
    	public int PrimaryColor { get; set; }

    	public int SecondaryColor { get; set; }

    	public ChangeCustomColors()
    	{
    	}

    	public ChangeCustomColors(int primaryColor, int secondaryColor)
    	{
    		PrimaryColor = primaryColor;
    		SecondaryColor = secondaryColor;
    	}

    	protected override MultiplayerMessageFilter OnGetLogFilter()
    	{
    		return MultiplayerMessageFilter.Administration;
    	}

    	protected override string OnGetLogFormat()
    	{
    		return "Received ChangeCustomColors";
    	}

    	protected override bool OnRead()
    	{
    		bool bufferReadValid = true;
    		PrimaryColor = GameNetworkMessage.ReadIntFromPacket(new CompressionInfo.Integer(-1, int.MaxValue, maximumValueGiven: true), ref bufferReadValid);
    		SecondaryColor = GameNetworkMessage.ReadIntFromPacket(new CompressionInfo.Integer(-1, int.MaxValue, maximumValueGiven: true), ref bufferReadValid);
    		return bufferReadValid;
    	}

    	protected override void OnWrite()
    	{
    		GameNetworkMessage.WriteIntToPacket(PrimaryColor, new CompressionInfo.Integer(-1, int.MaxValue, maximumValueGiven: true));
    		GameNetworkMessage.WriteIntToPacket(SecondaryColor, new CompressionInfo.Integer(-1, int.MaxValue, maximumValueGiven: true));
    	}
    }
}
