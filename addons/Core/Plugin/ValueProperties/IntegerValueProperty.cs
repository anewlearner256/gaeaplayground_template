﻿using Godot;

#if TOOLS
namespace Gaea.Plugin
{
    [Tool]
    public class IntegerValueProperty : ValueProperty<int>
    {
        private SpinBox _spinBox;

        public IntegerValueProperty() : base()
        {
            _spinBox = new SpinBox
            {
                Rounded = true,
                Step = 1,
                AllowGreater = true,
                AllowLesser = true,
                SizeFlagsHorizontal = (int)SizeFlags.ExpandFill
            };
            _spinBox.Connect("value_changed", this, nameof(OnSpinBoxChanged));
            AddChild(_spinBox);
        }

        public override void UpdateProperty()
        {
            _spinBox.SetBlockSignals(true);
            _spinBox.Value = Value;
            _spinBox.SetBlockSignals(false);
        }

        protected override void OnDisabled(bool disabled) => _spinBox.Editable = !disabled;

        private void OnSpinBoxChanged(float newValue)
        {
            Value = (int)newValue;
        }
    }
}
#endif