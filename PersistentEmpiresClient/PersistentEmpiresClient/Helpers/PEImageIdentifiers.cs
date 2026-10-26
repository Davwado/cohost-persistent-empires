using TaleWorlds.Core;
using TaleWorlds.Core.ViewModelCollection.ImageIdentifiers;

namespace PersistentEmpires.Views
{
    // Bannerlord 1.4.8 split ImageIdentifierVM into an abstract base plus Item/Banner subclasses.
    // These keep the call sites in the views as one-liners.
    public static class PEImageIdentifiers
    {
        public static ImageIdentifierVM Item(ItemObject item)
        {
            return new ItemImageIdentifierVM(item);
        }

        public static ImageIdentifierVM Empty()
        {
            return new ItemImageIdentifierVM(null);
        }

        public static ImageIdentifierVM Banner(Banner banner)
        {
            if (banner == null) return Empty();
            return new BannerImageIdentifierVM(banner, true);
        }

        public static ImageIdentifierVM Banner(string bannerCode)
        {
            if (string.IsNullOrEmpty(bannerCode)) return Empty();
            return new BannerImageIdentifierVM(new Banner(bannerCode), true);
        }
    }
}
