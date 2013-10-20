# Rewire - Transform distracting browsing habits into productive time

Rewire is a simple browser extension that helps you build skills instead of wasting time on the internet. You configure certain URL patterns to be rewired to sites where you can productively build skills (study online courses, learn languages, your todo list, etc).

#### How do I access a site that I've rewired?
At some point you may need to go to sites that you've rewired. In the address bar (the omnibox), type "unwire", then a space, then the url of the site you want to go to. Like this:

    unwire example.com

This will temporarily suspend your rewiring for example.com and navigate you to the site.

#### How do I click on a link to a site that I've rewired?
Right-click the link (or command click) to open the context menu. Then click *Unwire this URL*. This will temproarily suspend your rewiring for the linked URL and navigate you to the site.

#### How do I configure Rewire to send me to a different URL or to add additional patterns to rewire?
Click on the rewire icon in your browser's toolbar to access the options page. The rewire icon currently looks like two arrows in opposing directions.

#### How do I install Rewire?
Rewire is currently being alpha-tested. To try it out you'll need to manually load it into your browser.

1. Clone the code

        $ git clone https://github.com/inconshreveable/rewire.git
        $ cd rewire

1. Use npm to install CoffeeScript

        $ npm install coffee-script

1. Compile the extension:

        $ node_modules/coffee-script/bin/coffee -c *.coffee

1. Follow the instructions here [http://developer.chrome.com/extensions/getstarted.html#unpacked](http://developer.chrome.com/extensions/getstarted.html#unpacked). The short version is:
    - In Chrome, navigate to [chrome://extensions](chrome://extensions)
    - Make sure the "Developer Mode" checkbox is enabled
    - Click "Load unpacked extension..." and then navigate to the folder where you cloned Rewire
