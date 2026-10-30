using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.CompilerServices;
using PersistentEmpiresLib.SceneScripts;
using TaleWorlds.Engine;
using TaleWorlds.Library;
using TaleWorlds.MountAndBlade;

namespace PersistentEmpiresLib.Helpers
{
    public static class EntityHelper
    {
        private static readonly ConditionalWeakTable<object, object> RemovedBy = new ConditionalWeakTable<object, object>();

        // Removes the scene entity that belongs to `owner` (the script or object that holds it), at most once. Removing an entity
        // that is already gone is a native call on freed memory and can abort the whole server, so every removal goes through
        // here. Returns false when there was nothing to remove.
        public static bool RemoveOnce(object owner, WeakGameEntity entity, int delayMs = 0)
        {
            if (owner == null || !entity.IsValid) return false;
            lock (RemovedBy)
            {
                object marker;
                if (RemovedBy.TryGetValue(owner, out marker)) return false;
                RemovedBy.Add(owner, new object());
            }
            entity.Remove(delayMs);
            return true;
        }
    }

    public static class OpenListSweep
    {
        // "Who has this market / trade centre open" lists only get an entry when a player opens it and lose it when the player
        // closes it. A player who dies, disconnects or walks off never sends the close, so the entry stayed for the whole match.
        // Drops the players that can no longer be using the object.
        public static void Sweep(Dictionary<MissionObject, List<NetworkCommunicator>> open, float margin)
        {
            foreach (MissionObject key in open.Keys.ToList())
            {
                List<NetworkCommunicator> list = open[key];
                float range = ((key as PE_UsableFromDistance) != null ? ((PE_UsableFromDistance)key).Distance : 3f) + margin;
                list.RemoveAll(peer =>
                {
                    if (peer == null || !peer.IsConnectionActive) return true;
                    Agent agent = peer.ControlledAgent;
                    if (agent == null || !agent.IsActive()) return true;
                    if (key.GameEntity == null) return true;
                    return key.GameEntity.GetGlobalFrame().origin.Distance(agent.Position) > range;
                });
                if (list.Count == 0) open.Remove(key);
            }
        }
    }
}
