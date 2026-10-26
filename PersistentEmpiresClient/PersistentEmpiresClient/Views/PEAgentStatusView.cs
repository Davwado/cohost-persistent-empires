using PersistentEmpires.Views.ViewsVM;
using PersistentEmpiresLib.PersistentEmpiresMission.MissionBehaviors;
using PersistentEmpiresLib.SceneScripts;
using System;
using TaleWorlds.Core;
using TaleWorlds.Engine;
using TaleWorlds.Engine.GauntletUI;
using TaleWorlds.MountAndBlade;
using TaleWorlds.MountAndBlade.GauntletUI.Mission;
using TaleWorlds.MountAndBlade.Missions.MissionLogics;
using TaleWorlds.MountAndBlade.View;
using TaleWorlds.MountAndBlade.View.MissionViews;
using TaleWorlds.MountAndBlade.ViewModelCollection;
using TaleWorlds.MountAndBlade.ViewModelCollection.Missions.Interaction.InteractionItems;
using TaleWorlds.ScreenSystem;

namespace PersistentEmpires.Views.Views
{
    // The agent status HUD (health / weapon / interaction prompt) plus PE's hunger bar. Same structure as the game's
    // MissionGauntletAgentStatus (Bannerlord 1.4.8), driving PEHungerVM instead of MissionAgentStatusVM.
    public class PEAgentStatusView : MissionAgentStatusUIHandler
    {
        private GauntletLayer _gauntletLayer;
        private PEHungerVM _dataSource;
        private MissionMainAgentController _missionMainAgentController;
        private MissionGauntletMainAgentEquipmentControllerView _missionMainAgentEquipmentControllerView;
        private MissionHintLogic _missionHintLogic;
        private bool _isInDeployement;
        private AgentHungerBehavior _agentHungerBehavior;

        public override void AddInteractionMessage(MissionInteractionItemBaseVM message)
        {
            base.AddInteractionMessage(message);
            this._dataSource?.InteractionInterface.AddSecondaryMessage(message);
        }

        public override void RemoveInteractionMessage(MissionInteractionItemBaseVM message)
        {
            base.RemoveInteractionMessage(message);
            this._dataSource?.InteractionInterface.RemoveSecondaryMessage(message);
        }

        public override bool HasInteractionMessage(MissionInteractionItemBaseVM message)
        {
            if (this._dataSource == null) return false;
            return this._dataSource.InteractionInterface.HasSecondaryInteractionMessage(message);
        }

        public override void OnMissionStateActivated()
        {
            base.OnMissionStateActivated();
            this._dataSource?.OnMainAgentWeaponChange();
        }

        public override void EarlyStart()
        {
            base.EarlyStart();
            this._dataSource = new PEHungerVM(100, base.Mission, base.MissionScreen.CombatCamera, new Func<float>(base.MissionScreen.GetCameraToggleProgress));
            this._gauntletLayer = new GauntletLayer("PEAgentStatusView", this.ViewOrderPriority);
            this._gauntletLayer.LoadMovie("PEAgentStatusMain", this._dataSource);
            base.MissionScreen.AddLayer(this._gauntletLayer);
            this._dataSource.TakenDamageController.SetIsEnabled(BannerlordConfig.EnableDamageTakenVisuals);
            this.RegisterInteractionEvents();
            CombatLogManager.OnGenerateCombatLog += this.OnGenerateCombatLog;
            ManagedOptions.OnManagedOptionChanged = (ManagedOptions.OnManagedOptionChangedDelegate)Delegate.Combine(ManagedOptions.OnManagedOptionChanged, new ManagedOptions.OnManagedOptionChangedDelegate(this.OnManagedOptionChanged));
            this._agentHungerBehavior = base.Mission.GetMissionBehavior<AgentHungerBehavior>();
            this._agentHungerBehavior.OnAgentHungerChanged += this.SetHunger;
        }

        public void SetHunger(int hunger)
        {
            if (this._dataSource != null) this._dataSource.Hunger = hunger;
        }

        protected override void OnCreateView()
        {
            this._dataSource.IsAgentStatusAvailable = true;
        }

        protected override void OnDestroyView()
        {
            this._dataSource.IsAgentStatusAvailable = false;
        }

        protected override void OnSuspendView()
        {
            if (this._gauntletLayer != null) ScreenManager.SetSuspendLayer(this._gauntletLayer, true);
        }

        protected override void OnResumeView()
        {
            if (this._gauntletLayer != null) ScreenManager.SetSuspendLayer(this._gauntletLayer, false);
        }

        private void OnManagedOptionChanged(ManagedOptions.ManagedOptionsType changedManagedOptionsType)
        {
            if (changedManagedOptionsType == ManagedOptions.ManagedOptionsType.EnableDamageTakenVisuals)
            {
                this._dataSource?.TakenDamageController.SetIsEnabled(BannerlordConfig.EnableDamageTakenVisuals);
            }
        }

        public override void AfterStart()
        {
            base.AfterStart();
            this._dataSource?.InitializeMainAgentPropterties();
        }

        public override void OnMissionScreenInitialize()
        {
            base.OnMissionScreenInitialize();
            this._isInDeployement = base.Mission.Mode == MissionMode.Deployment;
        }

        public override void OnDeploymentFinished()
        {
            base.OnDeploymentFinished();
            this._isInDeployement = false;
        }

        public override void OnMissionScreenFinalize()
        {
            base.OnMissionScreenFinalize();
            this.UnregisterInteractionEvents();
            if (this._agentHungerBehavior != null) this._agentHungerBehavior.OnAgentHungerChanged -= this.SetHunger;
            ManagedOptions.OnManagedOptionChanged = (ManagedOptions.OnManagedOptionChangedDelegate)Delegate.Remove(ManagedOptions.OnManagedOptionChanged, new ManagedOptions.OnManagedOptionChangedDelegate(this.OnManagedOptionChanged));
            CombatLogManager.OnGenerateCombatLog -= this.OnGenerateCombatLog;
            base.MissionScreen.RemoveLayer(this._gauntletLayer);
            this._gauntletLayer = null;
            this._dataSource?.OnFinalize();
            this._dataSource = null;
            this._missionMainAgentController = null;
        }

        public override void OnMissionScreenTick(float dt)
        {
            base.OnMissionScreenTick(dt);
            if (this._dataSource == null) return;
            this._dataSource.IsInDeployement = this._isInDeployement;
            this._dataSource.Tick(dt);
            this._dataSource.InteractionInterface.DisplayInteractionText = !base.MissionScreen.IsRadialMenuActive && !base.Mission.IsOrderMenuOpen;
            this.UpdateFocusedHealth();
        }

        // PE objects that can be damaged show their hit points in the interaction prompt.
        private void UpdateFocusedHealth()
        {
            if (this._missionMainAgentController == null || this._missionMainAgentController.InteractionComponent == null) return;
            IFocusable focused = this._missionMainAgentController.InteractionComponent.CurrentFocusedObject;
            if (focused == null) return;

            ScriptComponentBehavior script = focused as ScriptComponentBehavior;
            if (script == null) return;

            if (focused is PE_DestructibleWithItem)
            {
                PE_DestructibleWithItem comp = script.GameEntity.GetFirstScriptOfType<PE_DestructibleWithItem>();
                if (comp != null) this._dataSource.InteractionInterface.OnFocusedHealthChanged(focused, comp.HitPoint / comp.MaxHitPoint, true);
                return;
            }

            if (focused is PE_Gate || focused is PE_NativeGate || focused is PE_InventoryEntity || focused is PE_RepairableDestructableComponent)
            {
                PE_RepairableDestructableComponent comp = script.GameEntity.GetFirstScriptOfType<PE_RepairableDestructableComponent>();
                if (comp != null) this._dataSource.InteractionInterface.OnFocusedHealthChanged(focused, comp.HitPoint / comp.MaxHitPoint, true);
            }
        }

        public override void OnFocusGained(Agent mainAgent, IFocusable focusableObject, bool isInteractable)
        {
            base.OnFocusGained(mainAgent, focusableObject, isInteractable);
            this._dataSource?.OnFocusGained(mainAgent, focusableObject, isInteractable);
        }

        public override void OnAgentInteraction(Agent userAgent, Agent agent, sbyte agentBoneIndex)
        {
            base.OnAgentInteraction(userAgent, agent, agentBoneIndex);
            this._dataSource?.OnAgentInteraction(userAgent, agent, agentBoneIndex);
        }

        public override void OnFocusLost(Agent agent, IFocusable focusableObject)
        {
            base.OnFocusLost(agent, focusableObject);
            this._dataSource?.OnFocusLost(agent, focusableObject);
        }

        public override void OnAgentDeleted(Agent affectedAgent)
        {
            this._dataSource?.OnAgentDeleted(affectedAgent);
        }

        public override void OnAgentRemoved(Agent affectedAgent, Agent affectorAgent, AgentState agentState, KillingBlow killingBlow)
        {
            this._dataSource?.OnAgentRemoved(affectedAgent);
        }

        private void OnGenerateCombatLog(CombatLogData logData)
        {
            if (logData.IsVictimAgentMine && logData.TotalDamage > 0)
            {
                this._dataSource?.OnMainAgentHit(logData.TotalDamage, logData.IsRangedAttack ? 1 : 0);
            }
            else if (logData.IsAttackerAgentMine && logData.ReflectedDamage > 0)
            {
                this._dataSource?.OnMainAgentHit(logData.ReflectedDamage, logData.IsRangedAttack ? 1 : 0);
            }
        }

        private void RegisterInteractionEvents()
        {
            this._missionMainAgentController = base.Mission.GetMissionBehavior<MissionMainAgentController>();
            if (this._missionMainAgentController != null)
            {
                this._missionMainAgentController.InteractionComponent.OnFocusGained += this._dataSource.OnSecondaryFocusGained;
                this._missionMainAgentController.InteractionComponent.OnFocusLost += this._dataSource.OnSecondaryFocusLost;
                this._missionMainAgentController.InteractionComponent.OnFocusHealthChanged += this._dataSource.InteractionInterface.OnFocusedHealthChanged;
            }
            this._missionMainAgentEquipmentControllerView = base.Mission.GetMissionBehavior<MissionGauntletMainAgentEquipmentControllerView>();
            if (this._missionMainAgentEquipmentControllerView != null)
            {
                this._missionMainAgentEquipmentControllerView.OnEquipmentDropInteractionViewToggled += this._dataSource.OnEquipmentInteractionViewToggled;
                this._missionMainAgentEquipmentControllerView.OnEquipmentEquipInteractionViewToggled += this._dataSource.OnEquipmentInteractionViewToggled;
            }
            this._missionHintLogic = base.Mission.GetMissionBehavior<MissionHintLogic>();
            if (this._missionHintLogic != null)
            {
                this._missionHintLogic.OnActiveHintChanged += this._dataSource.InteractionInterface.OnActiveMissionHintChanged;
            }
        }

        private void UnregisterInteractionEvents()
        {
            if (this._missionMainAgentController != null)
            {
                this._missionMainAgentController.InteractionComponent.OnFocusGained -= this._dataSource.OnSecondaryFocusGained;
                this._missionMainAgentController.InteractionComponent.OnFocusLost -= this._dataSource.OnSecondaryFocusLost;
                this._missionMainAgentController.InteractionComponent.OnFocusHealthChanged -= this._dataSource.InteractionInterface.OnFocusedHealthChanged;
            }
            if (this._missionMainAgentEquipmentControllerView != null)
            {
                this._missionMainAgentEquipmentControllerView.OnEquipmentDropInteractionViewToggled -= this._dataSource.OnEquipmentInteractionViewToggled;
                this._missionMainAgentEquipmentControllerView.OnEquipmentEquipInteractionViewToggled -= this._dataSource.OnEquipmentInteractionViewToggled;
            }
            this._missionHintLogic = base.Mission.GetMissionBehavior<MissionHintLogic>();
            if (this._missionHintLogic != null)
            {
                this._missionHintLogic.OnActiveHintChanged -= this._dataSource.InteractionInterface.OnActiveMissionHintChanged;
            }
        }

        public override void OnPhotoModeActivated()
        {
            base.OnPhotoModeActivated();
            if (this._gauntletLayer != null) this._gauntletLayer.UIContext.ContextAlpha = 0f;
            this.UnregisterInteractionEvents();
        }

        public override void OnPhotoModeDeactivated()
        {
            base.OnPhotoModeDeactivated();
            if (this._gauntletLayer != null) this._gauntletLayer.UIContext.ContextAlpha = 1f;
            this.RegisterInteractionEvents();
        }
    }
}
