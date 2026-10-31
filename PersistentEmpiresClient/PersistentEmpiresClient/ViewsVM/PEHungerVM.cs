using System;
using TaleWorlds.Engine;
using TaleWorlds.Library;
using TaleWorlds.MountAndBlade;
using TaleWorlds.MountAndBlade.ViewModelCollection;

namespace PersistentEmpires.Views.ViewsVM
{
    public class PEHungerVM : MissionAgentStatusVM
    {
        private int _hunger;
        private bool _isWounded;

        public PEHungerVM(int Hunger, Mission mission, Camera missionCamera, Func<float> getCameraToggleProgress) : base(mission, missionCamera, getCameraToggleProgress)
        {
            this.Hunger = Hunger;
        }

        [DataSourceProperty]
        public bool IsWounded
        {
            get => this._isWounded;
            set
            {
                if (value != this._isWounded)
                {
                    this._isWounded = value;
                    base.OnPropertyChangedWithValue(value, "IsWounded");
                }
            }
        }

        [DataSourceProperty]
        public string WoundedText
        {
            get => "WOUNDED";
        }

        [DataSourceProperty]
        public int MaxHunger
        {
            get => 100;
        }

        [DataSourceProperty]
        public int Hunger
        {
            get => this._hunger;
            set
            {
                if (value != this._hunger)
                {
                    this._hunger = value;
                    base.OnPropertyChangedWithValue(value, "Hunger");
                }
            }
        }
    }
}
