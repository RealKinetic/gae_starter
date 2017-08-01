A Google App Engine (Python) Project
====================================


THIS MAY MAKE MORE SENSE AS A GENERAL GAE POST AS A SETUP.

We're big fans of Google App Engine (GAE). It's our favorite go to tool kit to get a project started. Even if it's not a long term fit for the project we still find it is great for the initial prototype. It comes with a full suite of tools from multiple storage solutions including cache to queues to search. There are limitations for sure. But in our experience it has covered the 80% case of nearly every project we've done. It also comes with a SDK for easy local usage to help create a pretty solid local development experience. And best of all it handles the hard parts. It comes with a built in scheduler for spinning up and down instances. The datastore handles the sharding and partitioning of tables to allow near infinite scale with no operational burden. And even supports multi-tenancy with the support of namespaces.

However there are some rough edges. There are some design patterns that are a bit unique to GAE. Although many are more common these days with the emergance of Microservices and serverless. Part of what allows GAE to be a low operational overhead system is it's limitations and boundaries. To get the full value of GAE and not cause scale and performance issues it's important to learn the good design patterns for GAE. As well as learning the gotchas to avoid. We hope to turn this into a series of posts that walk through the good and bad patterns on GAE.




While Google has a decent amount of documentation for Google App Engine and the standard getting started guides and tutorials there isn't much material out there on setting up a proper, production ready GAE project. This post is a walk-through of laying out how we structure our Python based Google App Engine - Standard projects. This includes packaging dependencies for deployment as well as ensuring libraries are accessible in the local environment and tests. 

A note this guide focus on Python 2.7 on the GAE standard environment. In future posts we hope to show how to use other languages on the Flexible environment.

### Initial Skeleton

We're going to start with the same steps as the [Google provided Quickstart](https://cloud.google.com/appengine/docs/standard/python/quickstart). So go ahead and walk through that guide for the hello world as the first step. While it's not a requirement for you to have a deep understanding of GAE we do recommend understanding some of the basics. So we recommend stepping through the rest of the guide to develop a flask app. This will help you understand the basic structure and capabilities of GAE. We'll also be creating a Flask project so much of the material will translate.

For the first step of this guide we're going to start from the [hello world example provided by Google](https://github.com/GoogleCloudPlatform/python-docs-samples/tree/master/appengine/standard/hello_world). You can either clone the full examples repo and go to that directory or since they are only 3 files you could just copy them down. Once done you should end up with a single directory that holds 3 files: `app.yaml`, `main.py` and `main_test.py`.

Once you have those files in your directory you can test your app by running:

```
$ dev_appserver.py app.yaml
```

Or the shorthand version of:

```
$ dev_appserver.py .
```

Which will look for the app.yaml to run off of.

### Virtual Environments

Now we are proponents of Python Virtual Environments. If you're not familiar with [Python virtualenv](http://pypi.python.org/pypi/virtualenv) you can learn more in the excellent ["The Hitchhiker's Guide to Python"](http://python-guide-pt-br.readthedocs.io/en/latest/) and it's [section on Virtual Environments](http://python-guide-pt-br.readthedocs.io/en/latest/dev/virtualenvs/). Personally I'm also a fan of [virtualenvwrapper](https://virtualenvwrapper.readthedocs.io/en/latest/index.html) which is covered at the [bottom of the same guide](http://python-guide-pt-br.readthedocs.io/en/latest/dev/virtualenvs/#virtualenvwrapper). Virtualenv wrapper provides some nice UX improvements over vitrualenv.

Here's how I use virtualenv and virtualenvwrapper for my Python projects.

I first `cd` to the directory of the project I'm working on.

```
$ cd ~/projects/gae_starter
```

Once in the directory I then create the virtual environment.

```
$ mkvirtualenv -a $PWD gaestarter
```

The `-a $PWD` tells virtualenvwrapper that the current working directory is the directory to attach to this virtual environment. This will automatically switch you to that directory when activating your virtual environment. The `gaestarter` is the name of the virtual environment for the project. You can use any name you'd like but obviously a name specific to the project is ideal. The value of having virtual environments is supporting more than one project environment and keeping your dependencies isolated. So these environments should be scoped to the specific project.

By default when you create a virtual env with virtualenvwrapper it will activate the virtualenv. However to see who to interact with the virtualenv in the future you can follow these steps.

First you can deactivate the current virtualenv by ensuring your in an active virtualenv shell in your terminal by issuing the following command:

```
$ deactivate
```

To activate your virtualenv (if using virtualenvwrapper) you can be in any shell in any directory and issue the following command:

```
$ workon gaestarter
```

This will take you to the project directory and activate the virtualenv.

### Flask REST API Server

The first thing we're going to build out is a [REST](https://en.wikipedia.org/wiki/Representational_state_transfer) server to expose http endpoints via [Flask](http://flask.pocoo.org/).

  Flask is a microframework for Python based on Werkzeug, Jinja 2 and good intentions. And before you ask: It's BSD licensed!

Flask is our favorite Python web framework as it's relatively simple and provides the flexibility to be configured for many different use cases. As mentioned our first use case is as a REST API. We're going to send and receive JSON encoded data over http.

Let's update our `main.py` to be a Flask based request instead of webapp2. Remove all the existing code in `main.py` and replace it with the following:

```
from flask import Flask

app = Flask(__name__)

@app.route('/')
def home():
    return "Hello Flask World!"
```

Now if you run the app you'll get a 500 error in the page and if you look at your console you'll see an `ImportError` like the following:

```
Traceback (most recent call last):
  File "/Users/username/programs/google-cloud-sdk/platform/google_appengine/google/appengine/runtime/wsgi.py", line 240, in Handle
    handler = _config_handle.add_wsgi_middleware(self._LoadHandler())
  File "/Users/username/programs/google-cloud-sdk/platform/google_appengine/google/appengine/runtime/wsgi.py", line 299, in _LoadHandler
    handler, path, err = LoadObject(self._handler)
  File "/Users/username/programs/google-cloud-sdk/platform/google_appengine/google/appengine/runtime/wsgi.py", line 85, in LoadObject
    obj = __import__(path[0])
  File "/Users/username/projects/open/gae_guides/gae_starter/main.py", line 15, in <module>
    from flask import Flask
```

We don't have the Flask library installed in our project. So let's do that next.

Adding Flask to our project takes us to one of the under documented yet important part of your application. Dependency and package management. It's one thing to add a library to our project but how do we ensure it gets deployed correctly while running correctly locally both with the development server and via our unit tests.

### Dependency Management, 3rd Party Libraries, etc

We like to use as many standard Python practices as possible. This is why we're using tools such as `pip` and `virtualenv` however there's some tricks we need to do to ensure they work correctly with GAE.

By default when installing libraries with pip they will be installed into your `site-packages` directory. If you're not using `virutalenv` this will be the global site-packages directory that sits within your Python directory.

Deactive your virtualenv and you can see where your system Python site-packages directory is by running this command:

```
$ python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())"
```

You'll see a result similar to this:

```
/usr/local/Cellar/python/2.7.13/Frameworks/Python.framework/Versions/2.7/lib/python2.7/site-packages
```

If you activate your virtualenv (venv) and do the same you'll see somthing like:

```
/Users/username/.virtualenvs/gaestarter/lib/python2.7/site-packages
```

This is how virtual environments keep your libraries separate. A note virtual env creates a global variable for your virtual environment. In an active virtual environment run:

```
$ echo $VIRTUAL_ENV
```

The problem with storing our libraries in site-packages is when deploying our GAE project it only pulls files from our directory up. So it will not bundle our libraries in site-packages and deploy them. You will end up with import errors when trying to run the deployed application.

To mitigate this problem pip gives us a way to override where packages are install when running the pip command. In this case we're going to create a `vendor` directory to store the libraries we want deployed with our application.

```
mkdir vendor
```

We could then install a single library like so:

```
$ pip install flask -t vendor
```

If you run that command you'll see many directories now exist in our vendor directory. This includes Flask all of the libraries that Flask is dependent upon. Unfortunately if we want to uninstall Flask we can't just use `pip uninstall flask` as it looks only in site-directories and as of the moment the `-t` flag is not supported by uninstall. However for now we can just clear all of the libraries out of our vendor directory.

```
$ rm -rf vendor/*
```

Now this would be annoying if we had to do this for all packages. But thankfully pip comes with support for using a file that lists all our libraries which we generally call `requirements.txt`. So create a file named `requirements.txt` and add the following line

```
Flask>=0.12,<0.13
```

By adding the `>=0.12,<0.13` to the entry we're ensuring that when install Flask it will always use the most recent version of Flask above version `0.12` but below version `0.13`. This is generally called pinning a version. This is often critical in managing our dependencies to avoid pulling in broken or non-tested changes from upstream providers. Or often you'll hit collisions with multiple libraries not supporting the same versions of dependencies.

To install the libraries from our requirements.txt file you run the following command:

```
$ pip install -Ur requirements.txt -t vendor
```

The `-r` says we're passing in a file of libraries instead of a library name. The `-U` says to check for updates to any of the libraries and install those if there's a newer version than we currently have installed.

If you run that command now you'll see the same install steps we witnessed when installing Flask directly.

* FYI for those using git you will want to add `vendor` to your `.gitignore` file as there's no need to commit these files into your repo.

#### Library Configuration

Now that we have our vendor library we need to let GAE know about it. The best way to do this is to [add a reference to the appengine configuration](https://cloud.google.com/appengine/docs/standard/python/getting-started/python-standard-env). 

Create a file name `appengine_config.py` in the root project directory. once created add the following code:

```
from google.appengine.ext import vendor

# Add the libraries installed in our vendor folder.
vendor.add('vendor')
```

Now if we run our application again and open the page http://localhost:8080 you should see:

```
Hello Flask World!
```

Now the interesting thing about GAE and Flask is that we don't actually need to install it. GAE comes with some 3rd party libraries included and Flask happens to be one.

#### Built-in Libraries

[Here](https://cloud.google.com/appengine/docs/standard/python/tools/built-in-libraries-27) is the list of libraries (and they're versions) that Google includes with GAE. As you can see Flask "0.12" is included in our list. So we don't actually need to include it in our `requirements.txt` file. Sorry! However we wanted to walk through that process now as there will be libraries that we'll want to include later.

So if Flask is included as a library in GAE why did we get an error earlier prior to installing Flask? Because we didn't tell GAE that we wanted to use Flask. There's a startup cost of including unused code in your application so Google doesn't want to include unnecessary libraries.

To tell GAE that you want to use Flask we need to [update our `app.yaml` file](https://cloud.google.com/appengine/docs/standard/python/tools/using-libraries-python-27). To add flask we'll add a `libraries` entry to the end of our `app.yaml` file like so:

```
runtime: python27
api_version: 1
threadsafe: true

handlers:
- url: /.*
  script: main.app

libraries:
- name: flask
  version: "0.12"
```

* Note: If you want the latest version of the library you're using you can replace the version with `latest`. Although we prefer to pin as we do in our requirements file.

So now let's remove the files from our vendor folder again as we don't need them there any longer. Now if we run the dev server we should be good to go ... or are we? If we run it we see the `ImportError` again. What the ... Google? What is going on here?

If you read through Google's docs on ["Requesting a library"](https://cloud.google.com/appengine/docs/standard/python/tools/using-libraries-python-27#requesting_a_library) you'll see this bullet point `Some libraries must be installed locally.` Now if you click into that it has a list of libraries and Flask is not listed. Yeah. This is Google sucking at documentation. So how do we know what libraries are included or not. This is where things get fun. If you remember where you installed your Google Cloud SDK you can head there now but if not we'll use the trusty `dev_appserver.py` file to help us out. Run this command:

```
$ which dev_appserver.py
```

Which should give you something like:

```
/Users/username/programs/google-cloud-sdk/bin/dev_appserver.py
```

Now we know where our sdk is: `/Users/username/programs/google-cloud-sdk`

Within our sdk we have a `platform` directory which should have a `google_appengine` directory within it. That's where our GAE SDK lives. Within that directory we see a directory named `lib`. If we `ls` that directory we'll see that we've found the folder storing the libraries that Google gives us for local development.

```
ls ~/programs/google-cloud-sdk/platform/google_appengine/lib
```

As you can see Flask is not included in that list. Why? I do not know. Sometimes Google we'll say they're going to include a library in an upcoming release but we're still waiting on some of those. So if Google isn't providing the library for us locally but they are when we deploy what do we do? If we put it back in our vendor directory then it will be deployed. So we once again hit the issue of unnecessary code in our runtime. And Google by default will use our deployed version instead of the version they provide. And beyond less files there are other potential advantages to using Google's provided libraries. Many Python libraries included `clang` modules for performance. However GAE does not allow us to push up native code such as c modules as they are trying to keep a protected sandbox. This makes complete sense from their standpoint and why something like GAE Flex is appealing for those that do want their own native code. We'll cover that later. For now this means there's a potential performance benefit to using Google provided libraries.

This means for local development we'll want to have our libraries accessible but not allow them to be deployed. Well if we go back to the site-packages portion of our guide we can see that we have an answer already. Let's just pip install them into the virtual environments site-packages folder instead of our vendor folder.

To do this we like to create a separate requirements file named that we name: `requirements_dev.txt`. So let's create that file and them move our Flask entry from `requirements.txt` over to `requirements_dev.txt`.

Let's then add a new entry to our Makefile:

```
install-dev:
	pip install -Ur requirements_dev.txt
```

And let's update our install entry while we're at it:

```
install: install-dev
	pip install -Ur requirements.txt -t vendor
```

This will run our `install-dev` command as part of our `install` command.

So if we run our dev server again we should ... oh $@^&#%!$&@!. Are you kidding me. It still doesn't work. This issue right here has driven us nuts for so long. I won't bore you with all the details but it includes GAE overriding our Python path which is what bootstraps our site-packages into our environment when it starts up the dev server. For whatever reason Google does not want to keep your path references around. So after many terrible hacks and other attempts here's our best solution to this annoying situation.

If you pass in `-h` to `dev_appserver.py` (`dev_appserver.py -h`) to view the help menu and commands for the server you will see a very long list of options that we can pass into our dev server. The flag we are interested in is `--python_startup_script`. It's description is:

  the script to run at the startup of new Python runtime instances (useful for tools such as debuggers.  (default: None))

We're going to take advantage of the fact that GAE let's us pass in a script to run prior to it executing our application. However it does run after it blows away our system path. So we're going to create a startup script that we're going to call: `startup.py`. So go ahead and create that file in the project root folder.

Add this chunk of code to that file:

```
#!/usr/bin/env python

import os
import sys

# Add our Virtual Environment site packages path to our system path on bootup of
# the dev server. This will allow you to install things to your local venv like
# flask, pycrypto, etc and actually get them to be used by the dev_server.
venv = os.environ.get("VIRTUAL_ENV")
if venv:
    sys.path.append("{}/lib/python2.7/site-packages".format(venv))
```

This little hack of a script takes advantage of that `$VIRTUAL_ENV` global variable that we mentioned earlier. We take the path that is store in that variable and we add it to our system path. This puts our venv's site-packages back into the path as it should be.

Now we just need to update our `run` command

### Makefile

At Real Kinetic we're fans of using Makefiles to give us shortcuts to the commands we often run. We like Make as it's simple and is supported on OSX and Linux distributions. Create a file named `Makefile` in your project root.

Then add the following:

```
install:
    pip install -Ur requirements.txt -t vendor
```

Now you can run the following command as shorthand for the pip command:

```
make install
```

And while we're at it let's add a command to run our development server. Add the following to your Makefile:

```
run:
    dev_appserver.py .
```
