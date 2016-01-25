/**
   MoeCoop
   Copyright (C) 2016  Mojo

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
module coop.view.recipe_base_frame;

import dlangui;

import std.algorithm;
import std.array;
import std.range;

import coop.model.item;
import coop.model.recipe;
import coop.util;

import coop.view.widget;
import coop.controller.recipe_frame_controller;

immutable MaxNumberOfBinderPages = 128;

class BinderTabFrame: HorizontalLayout
{
    mixin TabFrame;

    this() { super(); }

    this(string id) {
        super(id);
        auto layout = new HorizontalLayout;
        addChild(layout);
        layout.margins = 20;
        layout.padding = 10;

        layout.addChild(recipeListLayout);
        layout.addChild(recipeDetailsLayout);
        layout.layoutHeight(FILL_PARENT);
        layout.layoutWidth(FILL_PARENT);
        with(childById!ComboBox("nColumns"))
        {
            items = ["1列表示"d, "2列表示", "4列表示"];
            selectedItemIndex = 2;
            itemClick = (Widget src, int idx) {
                nColumnChanged();
                return true;
            };
        }

        with(childById!EditLine("searchQuery"))
        {
            focusChange = (Widget src, bool checked) {
                queryFocused();
                return true;
            };
            keyEvent = (Widget src, KeyEvent e) {
                queryChanged();
                return false;
            };
        }
        childById!CheckBox("metaSearch").checkChange = (Widget src, bool checked) {
            metaSearchOptionChanged();
            return true;
        };

        childById!CheckBox("migemo").checkChange = (Widget src, bool checked) {
            migemoOptionChanged();
            return true;
        };

        childById!ComboBox("categories").itemClick = (Widget src, int idx) {
            categoryChanged();
            return true;
        };

        childById!ComboBox("characters").itemClick = (Widget src, int idx) {
            characterChanged();
            return true;
        };
    }

    @property auto categories(dstring[] cats)
    {
        childById!ComboBox("categories").items = cats;
    }

    @property auto selectedCategory()
    {
        return childById!ComboBox("categories").selectedItem;
    }

    @property auto characters(dstring[] chars)
    {
        childById!ComboBox("characters").items = chars;
    }

    @property auto selectedCharacter()
    {
        return childById!ComboBox("characters").selectedItem;
    }

    auto showRecipeList(Widget[] recipes, int nColumns)
    {
        auto recipeList = childById("recipeList");
        recipeList.removeAllChildren;
        recipeList.backgroundColor = recipes.empty ? "white" : "black";

        auto scroll = new ScrollWidget;
        auto horizontal = new HorizontalLayout;

        recipes
            .chunks(MaxNumberOfBinderPages/nColumns)
            .map!((rs) {
                    auto col = new VerticalLayout;
                    rs.each!(r => col.addChild(r));
                    return col;
                })
            .each!(col => horizontal.addChild(col));
        scroll.contentWidget = horizontal;
        scroll.backgroundColor = "white";
        recipeList.addChild(scroll);
    }

    @property auto recipeDetail(Widget recipe)
    {
        auto frame = childById("recipeDetail");
        frame.removeAllChildren;
        frame.addChild(recipe);
    }

    auto setItemDetail(Widget item, int idx)
    {
        auto frame = childById("detail"~(idx+1).to!string);
        frame.removeAllChildren;
        frame.addChild(item);
    }

    @property auto queryText()
    {
        return childById!EditLine("searchQuery").text;
    }

    @property auto queryText(dstring str)
    {
        childById!EditLine("searchQuery").text = str;
    }

    auto hideItemDetail(int idx)
    {
        childById("item"~(idx+1).to!string).visibility = Visibility.Gone;
    }

    auto showItemDetail(int idx)
    {
        childById("item"~(idx+1).to!string).visibility = Visibility.Visible;
    }

    @property auto numberOfColumns()
    {
        return childById!ComboBox("nColumns").selectedItem[0..1].to!int;
    }

    @property auto useMetaSearch()
    {
        return childById!CheckBox("metaSearch").checked;
    }

    @property auto useMigemo()
    {
        return childById!CheckBox("migemo").checked;
    }

    @property auto disableMigemoBox()
    {
        childById!CheckBox("migemo").enabled = false;
    }

    @property auto enableMigemoBox()
    {
        childById!CheckBox("migemo").enabled = true;
    }

    auto setCategoryName(dstring cat)
    {
        import std.format;
        childById("categoryCaption").text = cat;
        childById("metaSearch").text = format("全ての%sから検索"d, cat);
    }

    EventHandler!() queryFocused;
    EventHandler!() queryChanged;
    EventHandler!() metaSearchOptionChanged;
    EventHandler!() migemoOptionChanged;
    EventHandler!() categoryChanged;
    EventHandler!() characterChanged;
    EventHandler!() nColumnChanged;
}

auto recipeListLayout()
{
    auto layout = parseML(q{
            VerticalLayout {
                HorizontalLayout {
                    TextWidget { text: "キャラクター" }
                    ComboBox {
                        id: characters
                    }

                    TextWidget { id: categoryCaption }
                    ComboBox {
                        id: categories
                    }
                }

                HorizontalLayout {
                    EditLine {
                        id: searchQuery
                        minWidth: 200
                        text: "見たいレシピ"
                    }
                    CheckBox {
                        id: metaSearch;
                    }
                    CheckBox { id: migemo; text: "Migemo 検索" }
                }

                HorizontalLayout {
                    TextWidget { text: "レシピ一覧" }
                    ComboBox { id: nColumns }
                }
                FrameLayout {
                    id: recipeList
                    padding: 1
                }
            }
        });
    return layout;
}

auto recipeDetailsLayout()
{
    auto layout = parseML(q{
            VerticalLayout {
                padding: 10
                minWidth: 400
                TextWidget { text: "レシピ情報" }
                FrameLayout {
                    id: recipeDetail
                    padding: 1
                    backgroundColor: "black"
                }

                VerticalLayout {
                    id: item1
                    TextWidget { text: "アイテム情報1" }
                    FrameLayout {
                        id: detail1
                        padding: 1
                        backgroundColor: "black"
                    }
                }

                VerticalLayout {
                    id: item2
                    TextWidget { text: "アイテム情報2" }
                    FrameLayout {
                        id: detail2
                        padding: 1
                        backgroundColor: "black"
                    }
                }
            }
        });
    return layout;
}

class RecipeEntryWidget: HorizontalLayout
{
    this()
    {
        super();
    }

    this(dstring recipe)
    {
        super();
        box = new CheckBox(null, ""d);
        link = new LinkWidget(null, recipe);
        addChild(box);
        addChild(link);
        box.checkChange = (Widget src, bool checked) {
            filedStateChanged(checked);
            return true;
        };
        link.click = (Widget src) {
            detailClicked();
            return true;
        };
    }

    override @property bool checked() { return box.checked; }
    override @property Widget checked(bool c) {
        box.checked = c;
        return this;
    }

    EventHandler!(bool) filedStateChanged;
    EventHandler!() detailClicked;
private:
    CheckBox box;
    LinkWidget link;
}

class LinkWidget: TextWidget
{
    this() {
        super();
        clickable = true;
        // textColor = "blue";
        // textFlags = TextFlag.Underline;
    }

    this(string id, dstring txt)
    {
        super(id, txt);
        clickable = true;
        // textColor = "blue";
        // textFlags = TextFlag.Underline;
    }
}