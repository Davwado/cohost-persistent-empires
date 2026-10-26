using TaleWorlds.MountAndBlade;
using TaleWorlds.MountAndBlade.Network.Messages;

namespace PersistentEmpiresLib.NetworkMessages.Server
{
    [DefineGameNetworkMessageTypeForMod(GameNetworkMessageSendType.FromServer)]
    public sealed class ToggleVisibilityForAgent : GameNetworkMessage
    {
    	public Agent Agent { get; set; }

    	public bool Visible { get; set; }

    	public ToggleVisibilityForAgent()
    	{
    	}

    	public ToggleVisibilityForAgent(Agent agent, bool visible)
    	{
    		Agent = agent;
    		Visible = visible;
    	}

    	protected override MultiplayerMessageFilter OnGetLogFilter()
    	{
    		return MultiplayerMessageFilter.Equipment;
    	}

    	protected override string OnGetLogFormat()
    	{
    		return "ToggleVisibilityForAgent";
    	}

    	protected override bool OnRead()
    	{
    		bool bufferReadValid = true;
    		Agent = Mission.MissionNetworkHelper.GetAgentFromIndex(GameNetworkMessage.ReadAgentIndexFromPacket(ref bufferReadValid));
    		Visible = GameNetworkMessage.ReadBoolFromPacket(ref bufferReadValid);
    		return bufferReadValid;
    	}

    	protected override void OnWrite()
    	{
    		GameNetworkMessage.WriteAgentIndexToPacket(Agent.Index);
    		GameNetworkMessage.WriteBoolToPacket(Visible);
    	}
    }
}
