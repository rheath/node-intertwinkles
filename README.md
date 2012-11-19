# node-intertwinkles

Frontend and nodejs server library for apps connecting to InterTwinkles servers.

## Requirements

Assets are formatted for use with connect-assets:
https://github.com/TrevorBurnham/connect-assets

Requires an InterTwinkles server to connect to.

## Usage in a Node app:

1. Add to package.json for the app, inside "depenencies":

    "node-intertwinkles": "git+https://github.com/yourcelf/node-intertwinkles.git",

2. Install.

    npm install

3. Link assets into the connect-assets controlled dir for your app, so that non-concatenated paths to scripts will work during development:

    assets$ ln -s ../node_modules/node-intertwinkles/assets/ intertwinkles

4. Include in frontend code:

    scripts -- within "frontend.coffee":
        #= require ../intertwinkles/js/intertwinkles/index

    stylus -- within "style.styl":
        @import "../intertwinkles/css/intertwinkles"

    bootstrap -- extra file in "assets/css/bootstrap.less" for less compilation: 
        @import "../intertwinkles/css/bootstrap.less";

5. Add to templates:

    !=css("bootstrap")
    !=css("style")
    ...
    !=js("frontend")

6. Configure express to serve static images at /static:

    app.use '/static', express.static(__dirname + '/../assets')
    app.use '/static', express.static(__dirname + '/../node_modules/node-intertwinkles/assets')

## Usage with Django:

TODO

## Documentation

TODO
