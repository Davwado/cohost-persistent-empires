using TaleWorlds.Core;
using TaleWorlds.Core.ViewModelCollection.ImageIdentifiers;

namespace PersistentEmpires.Views
{
    // Bannerlord 1.4.8 split ImageIdentifierVM into an abstract base plus Item/Banner subclasses.
    // These keep the call sites in the views as one-liners.
    public static class PEImageIdentifiers
    {
        public static ItemImageIdentifierVM Item(ItemObject item)
        {
            return new ItemImageIdentifierVM(item);
        }

        public static ItemImageIdentifierVM Empty()
        {
            return new ItemImageIdentifierVM(null);
        }

        public static BannerImageIdentifierVM Banner(Banner banner)
        {
            if (banner == null) banner = new Banner();
            return new BannerImageIdentifierVM(banner, true);
        }

        public static BannerImageIdentifierVM Banner(string bannerCode)
        {
            if (string.IsNullOrEmpty(bannerCode)) return Banner(new Banner());
            return new BannerImageIdentifierVM(new Banner(bannerCode), true);
        }
    }
}
