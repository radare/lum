PWD=$(shell pwd)

all:

clean:

install:
	cd /usr/bin ; ln -fs ${PWD}/lum
