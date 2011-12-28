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

How to create your repository
-----------------------------
lum -j     # show json from packages in current directory
lum -p ..  # push all repos found in ..

Modules
-------


TODO
----
support for ./init.lua
support for ... 
