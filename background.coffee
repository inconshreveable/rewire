# Rewire's background script
############################

# constants
###########
defaultSuspendDuration = 10 * 60 * 1000 # 10 minutes
extRe = new RegExp(String(chrome.runtime.id)) # regex to make sure we never rewire ourself


# util
######
navigate = (url) ->
    chrome.tabs.query({active: true, currentWindow: true}, (tabs) ->
        chrome.tabs.update(tabs[0].id, {url: url})
    )

# classes
#########
class RewiredPattern
    constructor: (@source, @access, @suspend_duration) ->
        @re = RegExp(@source)
        @access = 0 if !@access?
        @suspend_duration = defaultSuspendDuration if !@suspend_duration?
        @suspend_until = 0

    serialize: () ->
        source: @source
        access: @access
        suspend_duration: @suspend_duration
        id: @id

    # true if this pattern exists in str
    # also makes sure a pattern can never rewire an extension
    match: (str) -> return str.match(@re)? && !str.match(extRe)

    # suspend this pattern for the given duration
    suspend: () -> @suspend_until = Date.now() + @suspend_duration

    # true if this pattern is not suspended
    active: () -> Date.now() > @suspend_until

    markAccess: () -> @access = Date.now()


class RewiredPatterns
    @defaultPatterns: [
        "://(www\.)?twitter.com",
        "://(www\.)?facebook.com",
        "://(www\.)?reddit.com",
    ]

    @load: () ->
        patterns = new RewiredPatterns()

        try
            savedPatterns = JSON.parse(localStorage["RewiredPatterns"])
            patterns.add(new RewiredPattern(p.source, p.access, p.suspend_duration)) for p in savedPatterns
        catch err
            console.log(err)
            patterns.addSource(src) for src in RewiredPatterns.defaultPatterns

        return patterns

    constructor: (@patterns = {}) ->

    add: (p) ->
        p.id = uuid()
        @patterns[p.id] = p
        @save()
        return p.id

    del: (id) ->
        delete @patterns[id]
        @save()

    get: (id) -> @patterns[id]

    list: () -> p for _, p of @patterns

    addSource: (src) -> @add(new RewiredPattern(src))

    save: () -> localStorage["RewiredPatterns"] = JSON.stringify(p.serialize() for p in @list())

    forUrl: (url) -> p for p in @list() when p.match(url)

    suspendForUrl: (url) ->
        p.suspend() for p in @forUrl(url)
        parts = parseUri(url)
        chrome.notifications.create("",
            type: "basic"
            iconUrl: "chrome-extension://" + chrome.runtime.id + "/rewire16.png"
            title: "Unwired"
            message: "You have 10 minutes on " + parts.host
        , () ->
        )

class Settings
    @defaults =
        destinations: ["https://khanacademy.org", "", ""]

    @load: () ->
        s = new Settings()
        try
            state = JSON.parse(localStorage["settings"])
            s.destinations = state["destinations"] if state["destinations"]?
        catch err
            console.log(err)
            s.destinations = Settings.defaults.destinations
        return s

    setDestination: (idx, url) ->
        @destinations[idx] = url
        @save()

    save: () -> localStorage["settings"] = JSON.stringify({"destinations": @destinations})

# globals
#########
patterns = RewiredPatterns.load()
settings = Settings.load()

# listeners
###########

# process requests from other pages
chrome.runtime.onMessage.addListener((request, sender, sendResponse) ->
    switch request.type
        when "add-pattern"
            patterns.addSource(request.pattern)
            sendResponse(null)

        when "del-pattern"
            patterns.del(request.id)
            sendResponse(null)

        when "get-pattern"
            p = patterns.get(request.id)
            sendResponse(p.serialize() if p else null)

        when "get-patterns-by-url"
            sendResponse(p.serialize() for p in patterns.forUrl(request.url))

        when "list-patterns"
            sendResponse(p.serialize() for p in patterns.list())
	
        when "suspend-for-url"
            patterns.suspendForUrl(request.url)
            sendResponse(null)

        when "list-destinations"
            sendResponse(settings.destinations)

        when "set-destination"
            settings.setDestination(request.idx, request.url)
            sendResponse(null)
)

# interceptor for rewiring http requests
chrome.webRequest.onBeforeRequest.addListener(
    ((info) ->
        if info.type != "main_frame"
            return

        for p in patterns.forUrl(info.url)
            if p.active()
                console.log("Request to " + info.url + " matches filter " + p.source)

                # pick a non-empty destination at random
                dests = (d for d in settings.destinations when d.length > 0)
                dest = dests[Math.floor(Math.random() * dests.length)]
                return {redirectUrl: dest}
            else
                p.markAccess()
                console.log("Allowing request to suspended pattern: " + p.source)
    ),

    # filters
    { urls: ["<all_urls>"] },

    # extra
    ["blocking"]
)

# omnibox listener which lets you navigate to rewired URLs, suspending those patterns
chrome.omnibox.onInputEntered.addListener((input, disposition) ->
    console.log(input)

    if input.indexOf("http") != 0
        input = "http://" + input

    patterns.suspendForUrl(input)

    switch disposition
        when "currentTab"
            navigate(input)

        when "newBackgroundTab"
            chrome.tabs.create(
                url: input
                active: false
            )

        when "newForegroundTab"
            chrome.tabs.create(
                url: input
            )
)

# context menu items which lets you navigate to rewired URLs, suspending those patterns
clickHandler = (info, tab) ->
    patterns.suspendForUrl(info.linkUrl)
    chrome.tabs.update(tab.id, {url: info.linkUrl})

chrome.contextMenus.create({ contexts: ["link"], onclick: clickHandler, title: "Unwire this URL" }, () ->
    console.log("Error, if any, creating context menu item: " + chrome.runtime.lastError)
)

# what happens when you click the extension's icon 
chrome.browserAction.onClicked.addListener(()->
    chrome.tabs.create(
        # XXX: send you to the stats page once that's ready
        url: "chrome-extension://" + chrome.runtime.id + "/options.html"
    )
)

# timers
########
setInterval(() ->
    chrome.tabs.query({}, (tabs) ->
        toclose = []
        for p in patterns.list()
            if p.active()
                toclose.push(t.id) for t in tabs when p.match(t.url)
        chrome.tabs.remove(toclose)
    )
, 60000
)
