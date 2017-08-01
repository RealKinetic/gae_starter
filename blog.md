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
Flask>=0.11,<0.12
```

By adding the `>=0.11,<0.12` to the entry we're ensuring that when install Flask it will always use the most recent version of Flask above version `0.11` but below version `0.12`. This is generally called pinning a version. This is often critical in managing our dependencies to avoid pulling in broken or non-tested changes from upstream providers. Or often you'll hit collisions with multiple libraries not supporting the same versions of dependencies.

To install the libraries from our requirements.txt file you run the following command:

```
$ pip install -Ur requirements.txt -t vendor
```

The `-r` says we're passing in a file of libraries instead of a library name. The `-U` says to check for updates to any of the libraries and install those if there's a newer version than we currently have installed.

If you run that command now you'll see the same install steps we witnessed when installing Flask directly.

* FYI for those using git you will want to add `vendor` to your `.gitignore` file as there's no need to commit these files into your repo.

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
