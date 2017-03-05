/**
 * Copyright: Copyright 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */

version(linux)
{
    version(DMD)
    {
        static this()
        {
            import etc.linux.memoryerror;
            assert(registerMemoryErrorHandler());
        }
    }
}

import vibe.d;

void main(string[] args)
{
    import std.format;
    import std.getopt;
    import std.process;

    import coop.core.wisdom;
    import coop.core;
    import coop.server.model;
    import coop.server.model.internal;
    import coop.util;

    ushort port = 8080;
    string msg;

    auto hinfo = args.getopt("port|p", &port);

    if (hinfo.helpWanted)
    {
        defaultGetoptPrinter("moecoop server.", hinfo.options);
        return;
    }

    auto wisdom = new Wisdom(SystemResourceBase);
    auto model = new WisdomModel(wisdom);

    auto router = new URLRouter;
    router.get("/", staticTemplate!"index.dt");
    router.registerRestInterface(new WebModel(model, environment.get("MOECOOP_MESSAGE", "")));
    auto settings = new HTTPServerSettings;
    settings.port = port;
    listenHTTP(settings, router);
    lowerPrivileges;
    runEventLoop;
}
