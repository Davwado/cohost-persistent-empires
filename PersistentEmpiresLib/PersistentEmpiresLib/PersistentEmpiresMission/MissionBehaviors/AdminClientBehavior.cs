using PersistentEmpiresLib.Helpers;
using PersistentEmpiresLib.NetworkMessages.Client;
using PersistentEmpiresLib.NetworkMessages.Server;
using PersistentEmpiresLib.SceneScripts;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using TaleWorlds.Core;
using TaleWorlds.Library;
using TaleWorlds.MountAndBlade;

namespace PersistentEmpiresLib.PersistentEmpiresMission.MissionBehaviors
{
    public class AdminClientBehavior : MissionNetwork
    {
        public delegate void AdminPanelClick();
        public event AdminPanelClick OnAdminPanelClick;
        public static List<AdminTp> AdminTps = new List<AdminTp>();
        // Admins hide from other players with this (client side state; the server keeps the real list)
        public static bool IsVisible = true;
#if SERVER
        public static bool CanUseSuicide = true;
        // false = only admins can change their clothing colours
        public static bool CanUseChangeColor = true;
        // set by AdminServerBehavior: true when this player may change colours (everyone, an admin, or on ColorWhitelist.txt)
        public static Func<NetworkCommunicator, bool> CanChangeColorFor = (p) => CanUseChangeColor;
#endif

        public void HandleAdminPanelClick()
        {
            if (this.OnAdminPanelClick != null)
            {
                this.OnAdminPanelClick();
            }
        }

        public void HandleUnbanPlayerClick()
        {
            InformationManager.ShowTextInquiry(
             new TextInquiryData(
             GameTexts.FindText("AdminClientBehaviorInqCaption", null).ToString()
             , GameTexts.FindText("AdminClientBehaviorInqText", null).ToString()
             , true
             , true
             , GameTexts.FindText("PE_InquiryData_Select", null).ToString()
             , GameTexts.FindText("PE_InquiryData_Cancel", null).ToString()
             , OnIdWritten
             , (Action)null
             , false
             , IsNameApplicable
             , ""
             , ""));
        }
        
        private void OnIdWritten(string name)
        {
            var message = new RequestUnBan(GameNetwork.MyPeer.VirtualPlayer?.ToPlayerId(), name);
            GameNetwork.BeginModuleEventAsClient();
            GameNetwork.WriteMessage(message);
            GameNetwork.EndModuleEventAsClient();
        }

        private Tuple<bool, string> IsNameApplicable(string inputText)
        {
            var reg = new Regex(@"^[0-9.]+$");
            var result = reg.Match(inputText);

            if (!result.Success)
                return new Tuple<bool, string>(false, GameTexts.FindText("AdminClientBehaviorError1", null).ToString());

            if (string.IsNullOrWhiteSpace(inputText))
                return new Tuple<bool, string>(false, GameTexts.FindText("AdminClientBehaviorError2", null).ToString());

            if (inputText.Length > 30)
                return new Tuple<bool, string>(false, GameTexts.FindText("AdminClientBehaviorError3", null).ToString());

            return new Tuple<bool, string>(true, inputText);
        }

        public override void OnBehaviorInitialize()
        {
            base.OnBehaviorInitialize();
            IsVisible = true;
            this.AddRemoveMessageHandlers(GameNetwork.NetworkMessageHandlerRegisterer.RegisterMode.Add);
#if SERVER
            CanUseSuicide = ConfigManager.GetBoolConfig("CanUseSuicide", true);
            CanUseChangeColor = ConfigManager.GetBoolConfig("CanUseChangeColor", true);
#endif
        }
        public override void OnRemoveBehavior()
        {
            AdminTps.Clear();
            IsVisible = true;
            base.OnRemoveBehavior();
            this.AddRemoveMessageHandlers(GameNetwork.NetworkMessageHandlerRegisterer.RegisterMode.Remove);
        }

        public void AddRemoveMessageHandlers(GameNetwork.NetworkMessageHandlerRegisterer.RegisterMode mode)
        {
            GameNetwork.NetworkMessageHandlerRegisterer networkMessageHandlerRegisterer = new GameNetwork.NetworkMessageHandlerRegisterer(mode);
            if (GameNetwork.IsClient)
            {
                networkMessageHandlerRegisterer.Register<AuthorizeAsAdmin>(this.HandleAuthorizeAsAdminFromServer);
                networkMessageHandlerRegisterer.Register<ToggleVisibilityForAgent>(this.HandleToggleVisibilityForAgent);
                networkMessageHandlerRegisterer.Register<BroadcastChangeCustomColors>(this.HandleBroadcastChangeCustomColors);
            }
        }

        private void HandleToggleVisibilityForAgent(ToggleVisibilityForAgent message)
        {
            if (message.Agent == null || message.Agent.AgentVisuals == null) return;
            message.Agent.AgentVisuals.SetVisible(message.Visible);
            message.Agent.AgentVisuals.LazyUpdateAgentRendererData();
        }

        private void HandleBroadcastChangeCustomColors(BroadcastChangeCustomColors message)
        {
            NetworkCommunicator peer = GameNetwork.NetworkPeers.FirstOrDefault(x => x.VirtualPlayer.Id.ToString() == message.PlayerUserId);
            if (peer == null || peer.ControlledAgent == null) return;
            peer.ControlledAgent.SetClothingColor1(BannerManager.GetColor(message.PrimaryColor));
            peer.ControlledAgent.SetClothingColor2(BannerManager.GetColor(message.SecondaryColor));
            AgentHelpers.ResetAgentMesh(peer.ControlledAgent);
        }

        public void ToggleInvisible()
        {
            IsVisible = !IsVisible;
            GameNetwork.BeginModuleEventAsClient();
            GameNetwork.WriteMessage(new RequestToggleInvisibility(IsVisible));
            GameNetwork.EndModuleEventAsClient();
        }

        private void HandleAuthorizeAsAdminFromServer(AuthorizeAsAdmin message)
        {
            GameNetwork.MyPeer.GetComponent<PersistentEmpireRepresentative>().IsAdmin = true;
        }


        internal static void Register(AdminTp adminTp)
        {
            AdminTps.Add(adminTp);
        }
    }
}