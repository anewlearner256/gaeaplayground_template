﻿using Gaea.Utils;
using Godot;

namespace Gaea.Plugin
{
    [CSharpScript]
    [Tool]
    public class SearchEdit : LineEdit
    {
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
        public int Limit { get; set; } = 5;
        [Export]
        public bool CaseSensitive { get; set; } = false;

        private PopupMenu _searchEntriesPopupMenu;

        public override void _Ready()
        {
#if TOOLS
            if (NodeUtils.IsInEditorSceneTab(this))
                return;
#endif
            _searchEntriesPopupMenu = new PopupMenu
            {
                PopupExclusive = false
            };
            _searchEntriesPopupMenu.Connect("index_pressed", this, nameof(OnSearchMenuIndexPressed));
            AddChild(_searchEntriesPopupMenu);

            GetViewport().Connect("gui_focus_changed", this, nameof(OnFocusChanged));
            Connect("text_changed", this, nameof(OnTextChanged));
        }

        private void OnTextChanged(string newText)
        {
            if (SearchEntries.Length == 0)
                return;
            UpdateSearchEntries();
            PopupSearchEntries();
        }

        private void UpdateSearchEntries()
        {
            _searchEntriesPopupMenu.Clear();
            int index = 0;
            foreach (var entry in SearchEntries)
            {
                if (Text != "" && ((CaseSensitive && entry.Text.Find(Text) < 0) || entry.Text.ToLower().Find(Text.ToLower()) < 0))
                    continue;
                if (entry.Icon != null)
                    _searchEntriesPopupMenu.AddIconItem(entry.Icon, entry.Text);
                else
                    _searchEntriesPopupMenu.AddItem(entry.Text);
                index++;
                if (Limit >= 0 && index >= Limit)
                    return;
            }
        }

        private bool _searchEntriesFocused = false;
        private bool _searchEdiFocused = false;

        private void OnFocusChanged(Control control)
        {
            if (control == this)
                PopupSearchEntries();
            else
                _searchEntriesPopupMenu.Hide();
        }

        private void OnSearchMenuIndexPressed(int index)
        {
            Text = _searchEntriesPopupMenu.GetItemText(index);
            EmitSignal("text_changed", Text);
        }

        private void PopupSearchEntries()
        {
            UpdateSearchEntries();
            var globalRect = GetGlobalRect();
            // Force update to minsize
            _searchEntriesPopupMenu.RectSize = Vector2.Zero;
            var searchEntriesGlobalRect = _searchEntriesPopupMenu.GetGlobalRect();
            if (globalRect.End.y + searchEntriesGlobalRect.Size.y > OS.WindowSize.y)
                // Show on top, sine there's no room on the bottom
                searchEntriesGlobalRect.Position = globalRect.Position - new Vector2(0, searchEntriesGlobalRect.Size.y);
            else
                // Show on bottom
                searchEntriesGlobalRect.Position = globalRect.Position + new Vector2(0, globalRect.Size.y);

            _searchEntriesPopupMenu.FocusMode = FocusModeEnum.None;
            _searchEntriesPopupMenu.Popup_(searchEntriesGlobalRect);
        }

    }
}