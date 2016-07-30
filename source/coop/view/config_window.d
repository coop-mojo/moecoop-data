/**
 * Copyright: Copyright (c) 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.view.config_window;

import dlangui;
import dlangui.dialogs.dialog;
import dlangui.dialogs.filedlg;

import coop.model.config;
import coop.model.character;
import coop.view.main_frame;
import coop.view.recipe_tab_frame;
import coop.view.recipe_material_tab_frame;

import std.algorithm;
import std.array;
import std.file;
import std.path;

class ConfigDialog: Dialog
{
    this(Window parent, Character[dstring] chars, Config con)
    {
        super(UIString("設定"d), parent, DialogFlag.Popup);
        chars_ = chars;
        config_ = con;
    }

    override void initialize()
    {
        version(Windows) {
            enum directory = "フォルダ";
        } else {
            enum directory = "ディレクトリ";
        }

        auto wLayout = parseML(q{
                TableLayout {
                    colCount: 3
                    padding: 10

                    TextWidget {
                        text: "キャラクター管理"
                    }
                    EditLine { id: toBeAdded }
                    Button {
                        id: addCharacter
                        text: "追加"
                    }
                    TextWidget {
                        text: ""
                    }
                    ListWidget {
                        id: characters
                        backgroundColor: "white"
                    }
                    Button {
                        id: deleteCharacter
                        text: "選択したキャラクターを削除"
                    }

                    TextWidget {
                        text: "Migemo ライブラリ"
                    }
                    TextWidget {
                        id: migemoStatus
                    }
                    Button {
                        id: migemoInstaller
                        text: "インストール"
                    }
                }
            });

        StringListAdapter charList = new StringListAdapter;
        chars_.keys.each!(c => charList.add(c));
        wLayout.childById!ListWidget("characters").ownAdapter = charList;
        dstring baseDir = chars_.values.front.baseDirectory;

        with(wLayout.childById("toBeAdded"))
        {
            keyEvent = (Widget src, KeyEvent e) {
                wLayout.childById("addCharacter").enabled = chars_.keys.all!(c => c != text);
                return false;
            };
        }
        wLayout.childById("addCharacter").click = (Widget src) {
            auto newChar = wLayout.childById("toBeAdded").text;
            chars_[newChar] = new Character(newChar, baseDir);
            charList.add(newChar);
            auto mainWidget = _parentWindow.mainWidget;
            with(mainWidget)
            {
                childById!RecipeTabFrame("binderFrame").characters = chars_.keys;
                childById!RecipeTabFrame("skillFrame").characters = chars_.keys;
                childById!RecipeMaterialTabFrame("materialFrame").characters = chars_.keys;
            }
            return true;
        };
        wLayout.childById("deleteCharacter").click = (Widget src) {
            auto list = wLayout.childById!ListWidget("characters");
            auto deletedIdx = list.selectedItemIndex;
            auto deleted = charList.items[deletedIdx];
            auto c = chars_[deleted];
            chars_.remove(deleted);
            c.deleteConfig;
            charList.clear;
            chars_.keys.each!(c => charList.add(c));
            auto mainWidget = _parentWindow.mainWidget;
            with(mainWidget)
            {
                childById!RecipeTabFrame("binderFrame").characters = chars_.keys;
                childById!RecipeTabFrame("skillFrame").characters = chars_.keys;
                childById!RecipeMaterialTabFrame("materialFrame").characters = chars_.keys;
            }
            return true;
        };

        if (config_.migemoLib.exists)
        {
            wLayout.childById("migemoStatus").text = "インストールされています";
            wLayout.childById("migemoInstaller").enabled = false;
        }
        else
        {
            wLayout.childById("migemoStatus").text = "インストールされていません";
            version(Posix)
            {
                wLayout.childById("migemoInstaller").enabled = false;
            }
            else version(Win32)
            {
                wLayout.childById("migemoInstaller").enabled = false;
            }
        }

        version(Windows)
        {
            wLayout.childById("migemoInstaller").click = (Widget src) {
                wLayout.childById("migemoInstaller").enabled = false;
                childById("button-action1").enabled = false;
                scope(exit) childById("button-action1").enabled = true;

                childById("button-action2").enabled = false;
                scope(exit) childById("button-action2").enabled = true;

                wLayout.childById("migemoStatus").text = "インストール中...";
                scope(success) wLayout.childById("migemoStatus").text = "インストールできました！";
                scope(failure) wLayout.childById("migemoStatus").text = "インストールに失敗しました";
                installMigemo(config_.migemoLib.dirName);
                return true;
            };
        }

        wLayout.backgroundColor = 0xCCCCCC;
        addChild(wLayout);

        auto exits = new HorizontalLayout;
        auto spacer = new FrameLayout;
        spacer.layoutWidth(FILL_PARENT);
        spacer.minWidth(400);
        exits.addChild(spacer);
        exits.addChild(new Button(ACTION_OK));
        exits.addChild(new Button(ACTION_CANCEL));
        _buttonActions = [ACTION_OK, ACTION_CANCEL];
        addChild(exits);
    }

    override void close(const Action action)
    {
        if (action) {
            if (action.id == StandardAction.Ok)
            {
                (cast(MainFrame)_parentWindow.mainWidget).controller.loadMigemo;
            }
        }
        _parentWindow.removePopup(_popup);
    }
private:
    Config config_;
    Character[dstring] chars_;
}

auto showConfigWindow(Window parent, Character[dstring] chars, Config config)
{
    auto dlg = new ConfigDialog(parent, chars, config);
    dlg.show;
}

auto installMigemo()(string dest)
{
    version(Windows)
    {
        import std.net.curl;
        import std.format;
        import std.zip;
        import std.file: remove;

        enum baseURL = "http://files.kaoriya.net/cmigemo/";
        enum ver = "20110227";
        version(X86)
        {
            enum arch = "32";
        }
        else
        {
            enum arch = "64";
        }

        auto src = format("%s/cmigemo-default-win%s-%s.zip", baseURL, arch, ver);
        auto archive = src.baseName;
        download(src, archive);
        assert(archive.exists);
        scope(exit) archive.remove;

        unzip(archive, dest);
    }
    else
    {
        static assert(false, "It should not be called from non-Windows systems.");
    }
}

auto unzip(string srcFile, string destDir)
{
    import std.exception;
    import std.regex;
    import std.zip;

    enforce(srcFile.exists);

    auto zip = new ZipArchive(read(srcFile));
    foreach(name, am; zip.directory)
    {
        if (name.endsWith("/"))
        {
            continue;
        }
        auto target = buildPath(destDir, name.replaceFirst(ctRegex!r"^.+?/", ""));
        auto dir = target.dirName;
        mkdirRecurse(dir);
        assert(am.expandedData.length == 0);
        zip.expand(am);
        assert(am.expandedData.length == am.expandedSize);
        target.write(am.expandedData);
    }
}
