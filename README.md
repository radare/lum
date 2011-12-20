LUM
===
Lum is the Luvit Module utility for installing dependencies for your projects.

This tool is implemented in a module named 'lumit'. The commandline tool is named 'lum'

	$ lum -h
	lum - luvit modules

	 Actions:
	    -d, deps             fetch, build and install all dependencies
	    -b, build            compile module
	    -c, clean            clean module
	    -D, deploy [path]    install current package into destination
	    -i, install [pkg]    install given package
	    -r, remove [pkg]     alias for 'lum rm' (uninstall package)
	    -I, info             pretty print ./package.lua
	    -l, ls, list         alias for 'ls'. list all installed packages

	 Package repository:
	    -s, search [str]     search in pkg database
	    -j, json             create json from current package
	    -p, push [json]      push json file to remove repository
	    -u, update           update local database from remote repositories

	 Environment and ~/.lum/config:
	    CC, CFLAGS, LDFLAGS, LUA_DIR, LUVIT_DIR, USER, REPOS

Repositories
------------
WIP: The plan is to make pkg.luvit.io the default repository for luvit modules.

Type of packages
----------------
Tarball (xz, gz, bz2) -- add support for releases
Repository (git, hg, svn) + optional revision

Compilation of modules
----------------------
Depends on make and gcc
Sets special environment depending on OS/arch
