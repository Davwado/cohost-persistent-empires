using System;
using System.Collections.Generic;
using System.Reflection;
using System.Runtime.CompilerServices;
using TaleWorlds.MountAndBlade;
using TaleWorlds.MountAndBlade.Network.Messages;

namespace PersistentEmpiresLib.Helpers
{
    // Wraps a network message handler so an exception in it is caught and reported (the dashboard's Errors tab) instead of
    // travelling back into the game's network code. Used on every handler registration:
    //     registerer.Register<SomeMessage>(HandlerGuard.Wrap<SomeMessage>(this.HandleSomeMessage));
    //
    // The game removes a handler by comparing delegates, so asking for the wrapper of the same handler again must give back the
    // same wrapper object. They are cached per target object (weakly, so a finished mission's behaviours can still be collected).
    public static class HandlerGuard
    {
        private static readonly ConditionalWeakTable<object, Dictionary<MethodInfo, Delegate>> ByTarget = new ConditionalWeakTable<object, Dictionary<MethodInfo, Delegate>>();
        private static readonly Dictionary<MethodInfo, Delegate> Statics = new Dictionary<MethodInfo, Delegate>();
        private static readonly object Gate = new object();

        private static TDelegate Cached<TDelegate>(Delegate original, Func<TDelegate> make) where TDelegate : class
        {
            lock (Gate)
            {
                Dictionary<MethodInfo, Delegate> map = original.Target == null ? Statics : ByTarget.GetOrCreateValue(original.Target);
                Delegate wrapper;
                if (!map.TryGetValue(original.Method, out wrapper))
                {
                    wrapper = (Delegate)(object)make();
                    map[original.Method] = wrapper;
                }
                return (TDelegate)(object)wrapper;
            }
        }

        // A message the server receives from a player.
        public static GameNetworkMessage.ClientMessageHandlerDelegate<T> Wrap<T>(GameNetworkMessage.ClientMessageHandlerDelegate<T> handler) where T : GameNetworkMessage
        {
            return Cached<GameNetworkMessage.ClientMessageHandlerDelegate<T>>(handler, () => (peer, message) =>
            {
                try
                {
                    return handler(peer, message);
                }
                catch (Exception ex)
                {
                    ErrorGuard.Report("handling " + typeof(T).Name, peer, ex);
                    return false;
                }
            });
        }

        // A message the client receives from the server.
        public static GameNetworkMessage.ServerMessageHandlerDelegate<T> Wrap<T>(GameNetworkMessage.ServerMessageHandlerDelegate<T> handler) where T : GameNetworkMessage
        {
            return Cached<GameNetworkMessage.ServerMessageHandlerDelegate<T>>(handler, () => message =>
            {
                try
                {
                    handler(message);
                }
                catch (Exception ex)
                {
                    ErrorGuard.Report("handling " + typeof(T).Name, ex);
                }
            });
        }
    }
}
