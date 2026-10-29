using System;
using System.Collections.Generic;
using TaleWorlds.Library;

namespace PersistentEmpiresLib.Helpers
{
    // Used around per-player work in loops that run every tick (spawning, saving, ...), so that one player in a bad state
    // is logged and skipped instead of stopping the loop for everybody. The same error is only written once per
    // ReportEverySeconds, because a failing tick would otherwise write it 60 times a second.
    public static class ErrorGuard
    {
        private const double ReportEverySeconds = 30;
        private static readonly Dictionary<string, DateTime> LastReported = new Dictionary<string, DateTime>();

        public static void Report(string where, Exception ex)
        {
            string key = where + "|" + ex.GetType().Name + "|" + ex.Message;
            DateTime now = DateTime.UtcNow;
            lock (LastReported)
            {
                DateTime last;
                if (LastReported.TryGetValue(key, out last) && (now - last).TotalSeconds < ReportEverySeconds) return;
                LastReported[key] = now;
            }
            Debug.Print("*PERSISTENT EMPIRES* Error in " + where, 0, Debug.DebugColor.Red);
#if SERVER
            // writes the exception to the log and sends it to the Discord exception webhook, if one is set
            PersistentEmpiresServer.ServerMissions.DiscordBehavior.NotifyException(ex);
#else
            Debug.Print(ex.ToString(), 0, Debug.DebugColor.Red);
#endif
        }

        public static void Report(string where, TaleWorlds.MountAndBlade.NetworkCommunicator peer, Exception ex)
        {
            Report(where + " (player " + (peer != null ? peer.UserName : "?") + ")", ex);
        }
    }
}
