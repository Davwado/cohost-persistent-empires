using TaleWorlds.MountAndBlade;

namespace PersistentEmpiresLib
{
    public class Main : MBSubModuleBase
    {
        // Module id: the folder under Modules/ and the id in SubModule.xml. Config, XML data and the module-list check use it.
        public const string ModuleName = "CoHostPersistentEmpires";
        // Game type / mission name: what servers put in their config ("GameType PersistentEmpires"), what the game-type strings
        // (str_multiplayer_game_type.PersistentEmpires) are keyed by, and the name the mission and its views are registered under.
        public const string GameTypeName = "PersistentEmpires";

        // Scenes made for the original mod store ModuleFolder = "PersistentEmpires" on their markets / crafting stations,
        // which overrides the field default. Those names belong to this module here, so map them to our module id.
        public static string ResolveModuleId(string id)
        {
            if (string.IsNullOrEmpty(id) || string.Equals(id, "PersistentEmpires", System.StringComparison.OrdinalIgnoreCase)) return ModuleName;
            return id;
        }
        public delegate bool IsAdminDelegate(NetworkCommunicator player);
        public static IsAdminDelegate IsAdminFunc { get; set; }

        public static bool IsAdmin(NetworkCommunicator player)
        {
            if (IsAdminFunc != null) { return IsAdminFunc(player); }
            return false;
        }

        internal static bool IsPlayerAdmin(NetworkCommunicator player)
        {
            if (IsAdminFunc != null) { return IsAdminFunc(player); }
            return false;
        }
    }
}
