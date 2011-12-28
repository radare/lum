LUM
===
Lum is the Luvit Module utility for installing dependencies for your projects.

This tool is implemented in a module named 'lumit'. The commandline tool is named 'lum'

Repositories
------------
A repository is just an URL pointing to a JSON file containing the packages information.
	echo REPOS=http://lolcathost.org/lum/pancake >> ~/.lum/config

	lum -S       # fetch repositories into ~/.lum/db
	lum -s sdb   # search for 'sdb' into the database

Packages
--------

Type of packages
----------------
Tarball (xz, gz, bz2) -- add support for releases
Repository (git, hg, svn) + optional revision

Compilation of modules
----------------------
Depends on make and gcc
Sets special environment depending on OS/arch
