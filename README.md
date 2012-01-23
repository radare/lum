LUM
===
Lum is the Luvit Module utility for installing dependencies for your projects.

This tool is implemented in a module named 'lumit'. The commandline tool is named 'lum'

Lum helps you to find, install and maintain luvit modules for your projects.


Modules
-------
Modules in luvit are the extensions for the language.

Those can be luvit or native code and are accessible via the require()
function and located inside the modules/ directory.

A package.lua file describes the module: name, version, dependencies,
description and other fields.


Configuration
-------------
	$ cat ~/.lum/config
	MAKE=make
	#CC=clang
	REPOS=http://lolcathost.org/lum/pancake
	PUSH=scp $0 user@host.org:/srv/http/lum

Installing packages
-------------------
install luvit 'irc' module in modules/. this package is looked up in the repository (see -s and -S for more information)
	$ lum -i irc

install a luvit dist package:
	$ lum -i irc-0.1.zip

Lum packages
------------
Use 'lum dist' to create a package

Dependencies
------------
Lum uses ./package.lua and looks to satisfy the dependencies for it. Running 'lum' without arguments is an alias for the 'build' (-b) action which install dependencies and builds the package running make if a Makefile is found.

Repositories
------------
A repository is just an URL pointing to a JSON file containing the packages information.
	echo REPOS=http://lolcathost.org/lum/pancake >> ~/.lum/config

	lum -S       # fetch repositories into ~/.lum/db
	lum -s sdb   # search for 'sdb' into the database
	lum -i sdb   # install sdb module

How to create your repository
-----------------------------
	lum -j     # show json from packages in current directory
	lum -p ..  # push all repos found in ..
Usage
-----
	$ lum -h
	lum - luvit module manager

	 Package:
	    -b, build            compile module
	    -c, clean ([pkg])    clean module
	    -D, deploy [path]    install current package into destination
	    -d, deps             fetch, build and install all dependencies
	    -i, install [pkg]    install given package (pkg@repo to force repo)
	    -u, upgrade [pkg]    reinstall given package (")
	    -I, info ([pkg])     pretty print ./package.lua or in modules/pkg
	    -l, ls, list         alias for 'ls'. list all installed packages
	    -r, remove [pkg]     alias for 'lum rm' (uninstall package)

	 Repository:
	    -j, json             create json from current package
	    -p, dist             create distribution distribution package
	    -P, push [path]      push json from file or directory to REPOS
	    -s, search [str]     search in pkg database
	    -S, sync             synchronize local database from remote repositories
	    -v, version          show version

	 Environment and ~/.lum/config:
	    CC, CFLAGS, LDFLAGS, LUA_DIR, LUVIT_DIR, USER, PUSH, REPOS
	    REPOS=http://lolcathost.org/lum/pancake
	    PUSH=scp $0 yourhost:/srv/http/www/lum
