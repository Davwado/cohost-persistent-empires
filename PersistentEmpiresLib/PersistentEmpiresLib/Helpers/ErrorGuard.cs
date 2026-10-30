using System;
using System.Collections.Generic;
using TaleWorlds.Library;

namespace PersistentEmpiresLib.Helpers
{
    // Used around per-player work in loops that run every tick (spawning, saving, ...), so that one player in a bad state
    // is logged and skipped instead of stopping the loop for everybody. The same error is only written once per
    // ReportEverySeconds, because a failing tick would otherwise write it 60 times a second.
    public class ErrorEntry
    {
        public string Where;
        public string Type;
        public string Message;
        public string Detail;
        public int Count;
        public DateTime FirstSeen;
        public DateTime LastSeen;
    }

    public static class ErrorGuard
    {
        private const int KeepEntries = 100;
        private static readonly Dictionary<string, ErrorEntry> Seen = new Dictionary<string, ErrorEntry>();

        /// <summary>Counts an error for the admin dashboard's error feed (every occurrence, not only the ones that are logged).</summary>
        public static void Record(string where, Exception ex)
        {
            string key = where + "|" + ex.GetType().Name + "|" + ex.Message;
            DateTime now = DateTime.UtcNow;
            lock (Seen)
            {
                ErrorEntry e;
                if (!Seen.TryGetValue(key, out e))
                {
                    if (Seen.Count >= KeepEntries)
                    {
                        string oldest = null; DateTime oldestAt = DateTime.MaxValue;
                        foreach (var kv in Seen) if (kv.Value.LastSeen < oldestAt) { oldestAt = kv.Value.LastSeen; oldest = kv.Key; }
                        if (oldest != null) Seen.Remove(oldest);
                    }
                    Seen[key] = e = new ErrorEntry { Where = where, Type = ex.GetType().Name, Message = ex.Message, Detail = ex.ToString(), FirstSeen = now };
                }
                e.Count++;
                e.LastSeen = now;
            }
        }

        public static List<ErrorEntry> Recent()
        {
            lock (Seen)
            {
                var list = new List<ErrorEntry>(Seen.Values);
                list.Sort((a, b) => b.LastSeen.CompareTo(a.LastSeen));
                return list;
            }
        }

        public static void Clear() { lock (Seen) Seen.Clear(); }

        private const double ReportEverySeconds = 30;
        private static readonly Dictionary<string, DateTime> LastReported = new Dictionary<string, DateTime>();

        public static void Report(string where, Exception ex)
        {
            Record(where, ex);
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
            PersistentEmpiresServer.ServerMissions.DiscordBehavior.NotifyException(ex, false);
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
