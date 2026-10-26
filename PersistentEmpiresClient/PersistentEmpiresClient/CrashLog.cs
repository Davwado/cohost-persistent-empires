using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.ExceptionServices;

namespace PersistentEmpiresClient
{
    // Writes exceptions raised in (or passing through) Persistent Empires code to a plain text file, so players can attach it
    // to a bug report instead of a crash dump. File: %ProgramData%\Mount and Blade II Bannerlord\logs\CoHostPE_exceptions.txt
    public static class CrashLog
    {
        private static readonly object Sync = new object();
        private static readonly HashSet<string> Seen = new HashSet<string>();
        private static int written;
        private const int MaxEntries = 300;

        public static string Path
        {
            get
            {
                string dir = System.IO.Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), "Mount and Blade II Bannerlord", "logs");
                return System.IO.Path.Combine(dir, "CoHostPE_exceptions.txt");
            }
        }

        public static void Initialize()
        {
            try
            {
                AppDomain.CurrentDomain.FirstChanceException += OnFirstChance;
                AppDomain.CurrentDomain.UnhandledException += OnUnhandled;
                Write("--- session start " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " ---");
            }
            catch { }
        }

        private static void OnFirstChance(object sender, FirstChanceExceptionEventArgs e)
        {
            try
            {
                Exception ex = e.Exception;
                string trace = ex.StackTrace ?? "";
                // only what touches our code, plus load/link failures that would crash a view
                bool ours = trace.IndexOf("PersistentEmpires", StringComparison.Ordinal) >= 0 || trace.IndexOf("PE_", StringComparison.Ordinal) >= 0;
                bool linkFailure = ex is MissingMemberException || ex is TypeLoadException || ex is TypeInitializationException || ex is InvalidProgramException;
                if (!ours && !linkFailure) return;
                string top = trace.Split('\n')[0].Trim();
                string key = ex.GetType().FullName + "|" + ex.Message + "|" + top;
                lock (Sync)
                {
                    if (written >= MaxEntries || !Seen.Add(key)) return;
                }
                Write("[first-chance] " + ex);
            }
            catch { }
        }

        private static void OnUnhandled(object sender, UnhandledExceptionEventArgs args)
        {
            try { Write("[UNHANDLED" + (args.IsTerminating ? ", terminating" : "") + "] " + args.ExceptionObject); }
            catch { }
        }

        public static void Write(string text)
        {
            lock (Sync)
            {
                written++;
                Directory.CreateDirectory(System.IO.Path.GetDirectoryName(Path));
                File.AppendAllText(Path, DateTime.Now.ToString("HH:mm:ss") + " " + text + Environment.NewLine + Environment.NewLine);
            }
        }
    }
}
