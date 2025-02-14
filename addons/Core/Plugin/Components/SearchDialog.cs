﻿using Gaea.Utils;
using Godot;

namespace Gaea.Plugin
{
    [CSharpScript]
    [Tool]
    public class SearchDialog : AcceptDialog
    {
        [Signal]
        public delegate void EntrySelected(string entry);

        private SearchEntry[] _searchEntries = new SearchEntry[0];
        public SearchEntry[] SearchEntries
        {
            get => _searchEntries;
            set
            {
                var old = _searchEntries;
                _searchEntries = value;
                if (old != _searchEntries && IsInsideTree())
                    UpdateSearchEntries();
            }
        }
        [Export]
        public bool CaseSensitive { get; set; } = false;

        private LineEdit _searchBar;
        private ItemList _searchEntriesItemList;

        public override void _Ready()
        {
#if TOOLS
            if (NodeUtils.IsInEditorSceneTab(this))
                return;
#endif

            GetOk().Disabled = true;
            GetOk().Connect("pressed", this, nameof(OnOkPressed));

            var cancelButton = AddCancel("Cancel");
            cancelButton.Connect("pressed", this, nameof(OnCancelled));

            RectSize = new Vector2(400, 200);
            if (WindowTitle == "Alert!")
                WindowTitle = "Search";

            _searchBar = new LineEdit
            {
                PlaceholderText = "Filter",
                SizeFlagsHorizontal = (int)SizeFlags.ExpandFill,
                RightIcon = GetIcon("Search", "EditorIcons")
            };
            _searchBar.Connect("text_changed", this, nameof(OnSearchBarTextChanged));

            _searchEntriesItemList = new ItemList
            {
                SelectMode = ItemList.SelectModeEnum.Single
            };
            _searchEntriesItemList.SizeFlagsHorizontal = _searchEntriesItemList.SizeFlagsVertical = (int)SizeFlags.ExpandFill;
            _searchEntriesItemList.Connect("item_activated", this, nameof(OnItemActivated));
            _searchEntriesItemList.Connect("item_selected", this, nameof(OnItemSelected));

            var rootVBox = new VBoxContainer();
            rootVBox.SizeFlagsHorizontal = rootVBox.SizeFlagsVertical = (int)SizeFlags.ExpandFill;
            rootVBox.AddChild(_searchBar);
            rootVBox.AddChild(_searchEntriesItemList);

            var marginContainer = new MarginContainer();
            marginContainer.AddChild(rootVBox);
            AddChild(marginContainer);
            marginContainer.SetAnchorsAndMarginsPreset(LayoutPreset.Wide);

            Connect("about_to_show", this, nameof(OnPopup));
        }

        private void OnPopup()
        {
            UpdateSearchEntries();
        }

        private void UpdateSearchEntries()
        {
            _searchEntriesItemList.Clear();
            foreach (var entry in SearchEntries)
            {
                if (_searchBar.Text != "" && ((CaseSensitive && entry.Text.Find(_searchBar.Text) < 0) || entry.Text.ToLower().Find(_searchBar.Text.ToLower()) < 0))
                    continue;
                _searchEntriesItemList.AddItem(entry.Text, entry.Icon);
            }
        }

        private void OnCancelled() => Hide();
        private void OnSearchBarTextChanged(string newText) => UpdateSearchEntries();
        private void OnOkPressed() => OnItemActivated(_searchEntriesItemList.GetSelectedItems()[0]);

        private void OnItemActivated(int index)
        {
            EmitSignal(nameof(EntrySelected), _searchEntriesItemList.GetItemText(index));
            Visible = false;
        }

        private void OnItemSelected(int index)
        {
            if (GetOk().Disabled)
                GetOk().Disabled = false;
        }
    }
}