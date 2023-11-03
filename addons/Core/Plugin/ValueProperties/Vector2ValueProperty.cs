using Godot;

#if TOOLS
namespace Gaea.Plugin
{
    [Tool]
    public class Vector2ValueProperty : ValueProperty<Vector2>
    {
        private EditorSpinSlider _xSpinSlider;
        private EditorSpinSlider _ySpinSlider;

        public Vector2ValueProperty() : this(0.0001f) { }
        public Vector2ValueProperty(float step) : base()
        {
            var hBox = new HBoxContainer();
            AddChild(hBox);

            _xSpinSlider = new EditorSpinSlider
            {
                Flat = true,
                Label = "x",
                Step = step,
                AllowLesser = true,
                AllowGreater = true,
                // HideSlider = true,
                SizeFlagsHorizontal = (int)SizeFlags.ExpandFill
            };
            _xSpinSlider.Connect("value_changed", this, nameof(OnXSpinSliderChanged));
            hBox.AddChild(_xSpinSlider);

            _ySpinSlider = new EditorSpinSlider
            {
                Flat = true,
                Label = "y",
                Step = step,
                AllowLesser = true,
                AllowGreater = true,
                // HideSlider = true,
                SizeFlagsHorizontal = (int)SizeFlags.ExpandFill
            };
            _ySpinSlider.Connect("value_changed", this, nameof(OnYSpinSliderChanged));
            hBox.AddChild(_ySpinSlider);
        }

        public override void UpdateProperty()
        {
            _xSpinSlider.SetBlockSignals(true);
            _ySpinSlider.SetBlockSignals(true);
            _xSpinSlider.Value = Value.x;
            _ySpinSlider.Value = Value.y;
            _xSpinSlider.SetBlockSignals(false);
            _ySpinSlider.SetBlockSignals(false);
        }

        protected override void OnDisabled(bool disabled)
        {
            _xSpinSlider.ReadOnly = disabled;
            _ySpinSlider.ReadOnly = disabled;
        }

        private void OnXSpinSliderChanged(float newValue)
        {
            var value = Value;
            value.x = newValue;
            Value = value;
        }

        private void OnYSpinSliderChanged(float newValue)
        {
            var value = Value;
            value.y = newValue;
            Value = value;
        }
    }
}
#endif