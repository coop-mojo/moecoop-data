/**
 * Authors: Mojo
 * License: MIT License
 */
module coop.view.editors;

import dlangui;

import std.algorithm;
import std.range;
import std.regex;
import std.traits;

class EditNumberLine(T): EditLine if (isNumeric!T)
{
    this(string id, dstring content)
    in{
        assert(content.empty || content.matchFirst(ctRegex!regex));
    } body {
        super(id, content);
    }

    override bool onKeyEvent(KeyEvent e)
    {
        if (e.action == KeyAction.Text)
        {
            if (!hasValidContent(e.text))
            {
                return true;
            }
        }
        return super.onKeyEvent(e);
    }

    override protected bool handleAction(const Action a)
    {
        if (a.id == EditorActions.Paste)
        {
            if (readOnly)
            {
                return true;
            }
            auto text = platform.getClipboardText;
            if (!hasValidContent(text))
            {
                return true;
            }
        }
        return super.handleAction(a);
    }
private:
    auto hasValidContent(dstring added)
    {
        if (added.matchFirst(ctRegex!regex))
        {
            static if (isFloatingPoint!T)
            {
                return !(text~added).startsWith(".") &&
                    !(text.canFind(".") && added.canFind("."));
            }
            else
            {
                return true;
            }
        }
        else
        {
            return false;
        }
    }

    static if (isIntegral!T)
    {
        enum regex = r"^\d*$"d;
    }
    else
    {
        enum regex = r"^\d*(\.\d*)?$"d;
    }
}

class EditIntLine: EditNumberLine!int
{
    this() { this(null); }

    this(string id, dstring content = int.init.to!dstring)
    {
        super(id, content);
    }
}

class EditRealLine: EditNumberLine!real
{
    this() { this(null); }

    // real.init == real.nan のため，初期値として不適
    this(string id, dstring content = 0.to!dstring)
    {
        super(id, content);
    }
}

import dlangui.widgets.metadata;
mixin(registerWidgets!(EditIntLine, EditRealLine)());
