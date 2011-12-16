LUM
===
Lum is the Luvit Module utility

Repositories
------------
Anybody can publish his own packages on pkg.luvit.org

packages are named in this way: user/name like in github

A repository is just a JSON array with all package.lua and extra information

  {
    { "package": { author, version, description... }, "dist": { md5, url, type="git" } },
    { ... },
  }

Local and global installation
-----------------------------
 lum install -g  # check package.lua for deps and install system-wide
 lum install -g modname # install module system-wide
 lum install modname # install in modules/
 lum install  # install package.lua deps

Actions
-------
 clean    - clean current module
 build    - compile current module
 install  - install current module system wide
 deps     - fetch build and install dependencies

TrustLevel is based on popularity
each user has its own list of packages

Type of packages
----------------
Tarball (xz, gz, bz2) -- add support for releases
Repository (git, hg, svn) + optional revision

Compilation of modules
----------------------
Depends on make and gcc

Sets special environment depending on OS/arch
