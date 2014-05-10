### Overview

A general high performance node server template. It's written in pure coffeescript and stylus.
It is especially good at small and standalone project.

When you using it you don't need to start a coffeescript or stylus file watcher to compile the
source code. The server will automatically compile cache the changed coffeescript, stylus and ejs files.
It has a standalone database inside, so you don't need any database configuration.

Though it contains lots of staffs, you still have the option to choose whether to load them or not.

This project is more like a general configuration than a framework.
It will give you some useful tools to quick setup a commmon node server project.

These are the server tools that you can take advantage of.

* express
* formidable
* bower
* underscore
* underscore.string
* coffee-script
* stylus
* forever
* request
* fs-extra
* nedb
* gaze
* socket.io

These are the client tools that you can take advantage of.

* requirejs
* jquery
* underscore
* underscore.string
* bootstrap
* font-awesome
* jquery.transit
* ys-keymaster


### Quick Start

Let's create a sample application with namespace `MOE` and named `App`.

0. First we clone the **nobone** to a directory.

   ```bash
   git clone https://github.com/ysmood/nobone.git
   cd nobone
   ```

0. Install dependencies.

    ```bash
    npm install
    ```

0. Create the module. (If you haven't installed coffee-script globally, install it first)

    ```bash
    cake module
    ```

    You can look into the `app` folder and custom whatever you want.

0. Edit the `var/config.coffee` file. Add your generated module to the `modules` array. You'd add this to the config file.
   add the line below to the `modules`.

    ```coffee
    'MOE.App': './app/app.coffee' # (The `.coffee` extension is optional.)
    ```

0. Run the development server.

    ```bash
    cake dev
    ```

0. Visit the `http://127.0.0.1:8013` in browser, the framework should work.


### Debug

Just execute the command below:

    cake debug

It will listen to a debug port.
