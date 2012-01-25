VERSION=0.3
PWD=$(shell pwd)
P=lum-${VERSION}
DESTDIR?=
PREFIX?=/usr
D=${DESTDIR}/${PREFIX}

all:

clean:

dist:
	rm -rf ${P}
	git clone . ${P}
	rm -rf ${P}/.git*
	tar czvf ${P}.tar.gz ${P}
	rm -rf ${P}

install:
	mkdir -p ${D}/bin
	mkdir -p ${D}/share/lum/modules
	cp -f lum ${D}/share/lum/
	cp -rf modules/lumit ${D}/share/lum/modules
	cd ${D}/bin ; ln -fs ${D}/share/lum/lum

symstall:
	cd ${D}/bin ; ln -fs ${PWD}/lum

deinstall uninstall:
	rm -rf ${D}/share/lum
	rm -f ${D}/bin/lum
