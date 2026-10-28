using System;
using System.Collections.Generic;
using System.Linq;
using TaleWorlds.Engine;
using TaleWorlds.Library;
using TaleWorlds.MountAndBlade;

namespace PersistentEmpiresLib.PersistentEmpiresMission.MissionBehaviors
{
    public class DrowningBehavior : MissionLogic
    {
        public bool IsSetProperly = false;
        public float UpperLimit;
        public float LowerLimit;

        public long LastCheckedAt = 0;
        public long Duration = 10;

        // Horses and other non-human agents in the water are removed rather than hurt (a mount with a rider dies, a loose one fades out)
        private readonly object _lock = new object();
        private readonly List<Agent> _agentsToRemove = new List<Agent>();

        public override void OnAgentHit(Agent affectedAgent, Agent affectorAgent, in MissionWeapon affectorWeapon, in Blow blow, in AttackCollisionData attackCollisionData)
        {
            if (this.IsSetProperly && affectedAgent != null && affectedAgent.IsActive() && !affectedAgent.IsHuman && IsInWater(affectedAgent))
            {
                if (affectedAgent.Health < (float)blow.InflictedDamage)
                {
                    affectedAgent.Health += blow.InflictedDamage;
                }
                lock (_lock)
                {
                    _agentsToRemove.Add(affectedAgent);
                }
            }
        }

        private bool IsInWater(Agent agent)
        {
            return this.IsSetProperly && agent.IsActive() && agent.Position.Z < UpperLimit && agent.Position.Z > LowerLimit;
        }

        private void RemoveNoneHumanAgent(Agent agent)
        {
            if (agent == null || !agent.IsActive()) return;
            if (agent.RiderAgent != null)
            {
                Blow b = new Blow(agent.Index);
                b.DamageType = TaleWorlds.Core.DamageTypes.Blunt;
                b.BoneIndex = -1;
                b.GlobalPosition = agent.Position;
                b.BaseMagnitude = 1f;
                b.InflictedDamage = 400;
                b.SwingDirection = agent.LookDirection;
                b.Direction = agent.LookDirection;
                b.WeaponRecord.FillAsMeleeBlow(null, null, -1, -1);
                agent.Die(b);
            }
            else
            {
                agent.FadeOut(false, false);
            }
        }

        public override void AfterStart()
        {

            GameEntity upperLimit = base.Mission.Scene.FindEntityWithTag("drowning_upper_limit");
            GameEntity lowerLimit = base.Mission.Scene.FindEntityWithTag("drowning_lower_limit");

            if (upperLimit == null || lowerLimit == null)
            {
                this.IsSetProperly = false;
                return;
            }
            this.IsSetProperly = true;
            this.UpperLimit = upperLimit.GetGlobalFrame().origin.Z;
            this.LowerLimit = lowerLimit.GetGlobalFrame().origin.Z;
            this.LastCheckedAt = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        }

        public override void OnMissionTick(float dt)
        {
            if (_agentsToRemove.Count > 0)
            {
                List<Agent> toRemove;
                lock (_lock)
                {
                    toRemove = _agentsToRemove.ToList();
                    _agentsToRemove.Clear();
                }
                foreach (Agent a in toRemove) RemoveNoneHumanAgent(a);
                return;
            }
            if ((this.LastCheckedAt + this.Duration < DateTimeOffset.UtcNow.ToUnixTimeSeconds()) && this.IsSetProperly)
            {
                this.LastCheckedAt = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
                foreach (Agent agent in base.Mission.Agents.ToList())
                {
                    if (IsInWater(agent))
                    {
                        if (!agent.IsHuman)
                        {
                            RemoveNoneHumanAgent(agent);
                            continue;
                        }
                        Blow blow = new Blow(agent.Index);
                        blow.DamageType = TaleWorlds.Core.DamageTypes.Pierce;
                        blow.BoneIndex = agent.Monster.HeadLookDirectionBoneIndex;
                        blow.GlobalPosition = agent.Position;
                        blow.GlobalPosition.z = blow.GlobalPosition.z + agent.GetEyeGlobalHeight();
                        blow.BaseMagnitude = 40;
                        blow.WeaponRecord.FillAsMeleeBlow(null, null, -1, -1);
                        blow.InflictedDamage = 40;
                        blow.SwingDirection = agent.LookDirection;
                        MatrixFrame frame = agent.Frame;
                        blow.SwingDirection = frame.rotation.TransformToParent(new Vec3(-1f, 0f, 0f, -1f));
                        blow.SwingDirection.Normalize();
                        blow.Direction = blow.SwingDirection;
                        blow.DamageCalculated = true;
                        blow.IsFallDamage = true;
                        sbyte mainHandItemBoneIndex = agent.Monster.MainHandItemBoneIndex;
                        AttackCollisionData attackCollisionDataForDebugPurpose = AttackCollisionData.GetAttackCollisionDataForDebugPurpose(false, false, false, true, false, false, false, false, false, false, false, false, CombatCollisionResult.StrikeAgent, -1, 0, 2, blow.BoneIndex, BoneBodyPartType.Head, mainHandItemBoneIndex, Agent.UsageDirection.AttackLeft, -1, CombatHitResultFlags.NormalHit, 0.5f, 1f, 0f, 0f, 0f, 0f, 0f, 0f, Vec3.Up, blow.Direction, blow.GlobalPosition, Vec3.Zero, Vec3.Zero, agent.Velocity, Vec3.Up);
                        agent.RegisterBlow(blow, attackCollisionDataForDebugPurpose);
                    }
                }
            }
        }
    }
}