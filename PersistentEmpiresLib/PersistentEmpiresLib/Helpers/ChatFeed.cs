using System;
using System.Collections.Generic;

namespace PersistentEmpiresLib.Helpers
{
    public class ChatLine
    {
        public long Seq;
        public DateTime At;
        public string Channel;
        public string Name;
        public string Text;
    }

    /// <summary>The last few hundred global chat lines, kept in memory for the admin dashboard's live view. Local and team chat are already in the action log.</summary>
    public static class ChatFeed
    {
        private const int Keep = 300;
        private static readonly LinkedList<ChatLine> Lines = new LinkedList<ChatLine>();
        private static long _seq;

        public static void Add(string channel, string name, string text)
        {
            if (text == null) return;
            lock (Lines)
            {
                Lines.AddLast(new ChatLine { Seq = ++_seq, At = DateTime.UtcNow, Channel = channel, Name = name, Text = text.Length > 300 ? text.Substring(0, 300) : text });
                while (Lines.Count > Keep) Lines.RemoveFirst();
            }
        }

        public static List<ChatLine> After(long seq)
        {
            lock (Lines)
            {
                var list = new List<ChatLine>();
                foreach (ChatLine l in Lines) if (l.Seq > seq) list.Add(l);
                return list;
            }
        }
    }
}
