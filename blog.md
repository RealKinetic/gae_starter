A Google App Engine (Python) Project
====================================


THIS MAY MAKE MORE SENSE AS A GENERAL GAE POST AS A SETUP.

We're big fans of Google App Engine (GAE). It's our favorite go to tool kit to get a project started. Even if it's not a long term fit for the project we still find it is great for the initial prototype. It comes with a full suite of tools from multiple storage solutions including cache to queues to search. There are limitations for sure. But in our experience it has covered the 80% case of nearly every project we've done. It also comes with a SDK for easy local usage to help create a pretty solid local development experience. And best of all it handles the hard parts. It comes with a built in scheduler for spinning up and down instances. The datastore handles the sharding and partitioning of tables to allow near infinite scale with no operational burden. And even supports multi-tenancy with the support of namespaces.

However there are some rough edges. There are some design patterns that are a bit unique to GAE. Although many are more common these days with the emergance of Microservices and serverless. Part of what allows GAE to be a low operational overhead system is it's limitations and boundaries. To get the full value of GAE and not cause scale and performance issues it's important to learn the good design patterns for GAE. As well as learning the gotchas to avoid. We hope to turn this into a series of posts that walk through the good and bad patterns on GAE.




While Google has a decent amount of documentation for Google App Engine and the standard getting started guides and tutorials there isn't much material out there on setting up a proper, production ready GAE project. This post is a walk-through of laying out how we structure our Python based Google App Engine - Standard projects. This includes packaging dependencies for deployment as well as ensuring libraries are accessible in the local environment and tests. 

A note this guide focus on Python 2.7 on the GAE standard environment. In future posts we hope to show how to use other languages on the Flexible environment.

We're going to start with the same steps as the [Google provided Quickstart](https://cloud.google.com/appengine/docs/standard/python/quickstart). So go ahead and walk through that guide for the hello world as the first step. While it's not a requirement for you to have a deep understanding of GAE we do recommend understanding some of the basics. So we recommend stepping through the rest of the guide to develop a flask app. This will help you understand the basic structure and capabilities of GAE. We'll also be creating a Flask project so much of the material will translate.

For the first step of this guide we're going to start from the [hello world example provided by Google](https://github.com/GoogleCloudPlatform/python-docs-samples/tree/master/appengine/standard/hello_world). You can either clone the full examples repo and go to that directory or since they are only 3 files you could just copy them down. Once done you should end up with a single directory that holds 3 files: `app.yaml`, `main.py` and `main_test.py`.

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
