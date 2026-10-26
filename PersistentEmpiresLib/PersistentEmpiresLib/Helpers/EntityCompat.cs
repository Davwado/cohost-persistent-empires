using System.Collections.Generic;
using System.Linq;
using TaleWorlds.MountAndBlade;

namespace TaleWorlds.Engine
{
    /// <summary>
    /// Bridges the game's move from GameEntity to WeakGameEntity: Persistent Empires stores strong
    /// GameEntity values in fields, lists and dictionary keys (GameEntity has pointer-based equality).
    /// Lives in the TaleWorlds.Engine namespace so the extension methods resolve wherever PE already
    /// has "using TaleWorlds.Engine;".
    /// </summary>
    public static class PEEntityCompat
    {
        public static GameEntity ToGE(this WeakGameEntity weak)
        {
            return GameEntity.CreateFromWeakEntity(weak);
        }

        public static List<GameEntity> ToGEList(this IEnumerable<WeakGameEntity> source)
        {
            return source.Select(x => GameEntity.CreateFromWeakEntity(x)).Where(x => x != null).ToList();
        }

        public static IEnumerable<GameEntity> GetChildrenGE(this WeakGameEntity weak)
        {
            return weak.GetChildren().ToGEList();
        }

        public static List<GameEntity> CollectChildrenEntitiesWithTagGE(this WeakGameEntity weak, string tag)
        {
            return weak.CollectChildrenEntitiesWithTag(tag).ToGEList();
        }

        // Removed from the game; same idea as before: script components of type T on tagged children.
        public static List<T> CollectObjectsWithTag<T>(this WeakGameEntity weak, string tag) where T : ScriptComponentBehavior
        {
            return weak.CollectChildrenEntitiesWithTag(tag).Select(e => e.GetFirstScriptOfType<T>()).Where(s => s != null).ToList();
        }
    }
}
