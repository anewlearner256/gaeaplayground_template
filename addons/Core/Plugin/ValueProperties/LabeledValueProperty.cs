﻿using Gaea.Utils;
using Godot;

#if TOOLS
namespace Gaea.Plugin
{
    [Tool]
    public class LabeledValueProperty : WrappedValueProperty
    {
        private string _propertyName = "";
        [Export]
        public string PropertyName
        {
            get => _propertyName;
            set
            {
                _propertyName = value;
                if (IsInsideTree())
                    _label.Text = _propertyName;
            }
        }

        private Label _label;

        public LabeledValueProperty() { }
        public LabeledValueProperty(string propertyName, ValueProperty valueProperty) : base(valueProperty)
        {
            _propertyName = propertyName;
        }

        public override void _Ready()
        {
            base._Ready();
#if TOOLS
            if (NodeUtils.IsInEditorSceneTab(this))
                return;
#endif
            _label = new Label
            {
                Text = PropertyName,
                SizeFlagsHorizontal = ValueProperty.SizeFlagsHorizontal = (int)SizeFlags.ExpandFill
            };

            var hSplit = new HSplitContainer
            {
                DraggerVisibility = SplitContainer.DraggerVisibilityEnum.Hidden
            };
            hSplit.AddChild(_label);
            hSplit.AddChild(ValueProperty);

            AddChild(hSplit);
        }
    }
}
#endif