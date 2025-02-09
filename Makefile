VERSION = 5.86
PN = anything-sync-daemon

PREFIX ?= /usr
CONFDIR = /etc
CRONDIR = /etc/cron.hourly
ALPINE_CRONDIR = /etc/periodic/hourly
INITDIR_SYSTEMD = /usr/lib/systemd/system
INITDIR_UPSTART = /etc/init.d
BINDIR = $(PREFIX)/bin
DOCDIR = $(PREFIX)/share/doc/$(PN)
MANDIR = $(PREFIX)/share/man/man1
ZSHDIR = $(PREFIX)/share/zsh/site-functions
BSHDIR = $(PREFIX)/share/bash-completion/completions

# set to anything except 0 to enable manpage compression
COMPRESS_MAN = 1

RM = rm
SED = sed
INSTALL = install -p
INSTALL_PROGRAM = $(INSTALL) -m755
INSTALL_SCRIPT = $(INSTALL) -m755
INSTALL_DATA = $(INSTALL) -m644
INSTALL_DIR = $(INSTALL) -d

Q = @

UNAME := $(shell uname -v)

common/$(PN): common/$(PN).in
	$(Q)echo -e '\033[1;32mSetting version\033[0m'
	$(Q)$(SED) 's/@VERSION@/'$(VERSION)'/' common/$(PN).in > common/$(PN)

help: install

install-bin: common/$(PN)
	$(Q)echo -e '\033[1;32mInstalling main script...\033[0m'
	$(INSTALL_DIR) "$(DESTDIR)$(BINDIR)"
	$(INSTALL_PROGRAM) common/$(PN) "$(DESTDIR)$(BINDIR)/$(PN)"
	ln -sf $(PN) "$(DESTDIR)$(BINDIR)/asd"
	cp -n common/asd.conf "$(DESTDIR)$(CONFDIR)/asd.conf"
	$(INSTALL_DIR) "$(DESTDIR)$(ZSHDIR)"
	$(INSTALL_DATA) common/zsh-completion "$(DESTDIR)/$(ZSHDIR)/_asd"
	$(INSTALL_DIR) "$(DESTDIR)$(BSHDIR)"
	$(INSTALL_DATA) common/bash-completion "$(DESTDIR)/$(BSHDIR)/asd"

install-man:
	$(Q)echo -e '\033[1;32mInstalling manpage...\033[0m'
	$(INSTALL_DIR) "$(DESTDIR)$(MANDIR)"
	$(INSTALL_DATA) doc/asd.1 "$(DESTDIR)$(MANDIR)/asd.1"
ifneq ($(COMPRESS_MAN),0)
	gzip -9 "$(DESTDIR)$(MANDIR)/asd.1"
	ln -sf asd.1.gz "$(DESTDIR)$(MANDIR)/$(PN).1.gz"
else
	ln -sf asd.1 "$(DESTDIR)$(MANDIR)/$(PN).1"
endif

install-cron:
	$(Q)echo -e '\033[1;32mInstalling cronjob...\033[0m'
ifneq ($(filter %Alpine, $(UNAME)),)
	$(INSTALL_DIR) "$(DESTDIR)$(ALPINE_CRONDIR)"
	$(INSTALL_SCRIPT) common/asd.cron.hourly "$(DESTDIR)$(ALPINE_CRONDIR)/asd-update"
else
	$(INSTALL_DIR) "$(DESTDIR)$(CRONDIR)"
	$(INSTALL_SCRIPT) common/asd.cron.hourly "$(DESTDIR)$(CRONDIR)/asd-update"
endif

install-systemd:
	$(Q)echo -e '\033[1;32mInstalling systemd files...\033[0m'
	$(INSTALL_DIR) "$(DESTDIR)$(CONFDIR)"
	$(INSTALL_DIR) "$(DESTDIR)$(INITDIR_SYSTEMD)"
	$(INSTALL_DATA) init/asd.service "$(DESTDIR)$(INITDIR_SYSTEMD)/asd.service"
	$(INSTALL_DATA) init/asd-resync.service "$(DESTDIR)$(INITDIR_SYSTEMD)/asd-resync.service"
	$(INSTALL_DATA) init/asd-resync.timer "$(DESTDIR)$(INITDIR_SYSTEMD)/asd-resync.timer"

install-upstart:
	$(Q)echo -e '\033[1;32mInstalling upstart files...\033[0m'
	$(INSTALL_DIR) "$(DESTDIR)$(CONFDIR)"
	$(INSTALL_DIR) "$(DESTDIR)$(INITDIR_UPSTART)"
	$(INSTALL_SCRIPT) init/asd.upstart "$(DESTDIR)$(INITDIR_UPSTART)/asd"

install-openrc:
	$(Q)echo -e '\033[1;32mInstalling OpenRC files...\033[0m'
	$(INSTALL_DIR) "$(DESTDIR)$(CONFDIR)"
	$(INSTALL_DIR) "$(DESTDIR)$(INITDIR_UPSTART)"
	$(INSTALL_SCRIPT) init/asd.openrc "$(DESTDIR)$(INITDIR_UPSTART)/asd"

install-systemd-all: install-bin install-man install-systemd

install-upstart-all: install-bin install-man install-cron install-upstart

install:
	$(Q)echo "run one of the following:"
	$(Q)echo "  make install-systemd-all (systemd based systems)"
	$(Q)echo "  make install-upstart-all (upstart based systems)"
	$(Q)echo
	$(Q)echo "or check out the Makefile for specific rules"

uninstall-bin:
	$(RM) "$(DESTDIR)$(BINDIR)/$(PN)"
	$(RM) "$(DESTDIR)$(BINDIR)/asd"
	$(RM) "$(DESTDIR)/$(ZSHDIR)/_asd"
	$(RM) "$(DESTDIR)/$(BSHDIR)/asd"

uninstall-man:
	$(RM) -f "$(DESTDIR)$(MANDIR)/$(PN).1.gz"
	$(RM) -f "$(DESTDIR)$(MANDIR)/asd.1.gz"
	$(RM) -f "$(DESTDIR)$(MANDIR)/$(PN).1"
	$(RM) -f "$(DESTDIR)$(MANDIR)/asd.1"

uninstall-cron:
ifneq ($(filter %Alpine, $(UNAME)),)
	$(RM) "$(DESTDIR)$(ALPINE_CRONDIR)/asd-update"
else
	$(RM) "$(DESTDIR)$(CRONDIR)/asd-update"
endif

uninstall-systemd:
	$(RM) "$(DESTDIR)$(CONFDIR)/asd.conf"
	$(RM) "$(DESTDIR)$(INITDIR_SYSTEMD)/asd.service"
	$(RM) "$(DESTDIR)$(INITDIR_SYSTEMD)/asd-resync.service"
	$(RM) "$(DESTDIR)$(INITDIR_SYSTEMD)/asd-resync.timer"

uninstall-upstart:
	$(RM) "$(DESTDIR)$(CONFDIR)/asd.conf"
	$(RM) "$(DESTDIR)$(INITDIR_UPSTART)/asd"

uninstall-openrc:
	$(RM) "$(DESTDIR)$(CONFDIR)/asd.conf"
	$(RM) "$(DESTDIR)$(INITDIR_UPSTART)/asd"

uninstall-systemd-all: uninstall-bin uninstall-man uninstall-systemd

uninstall-upstart-all: uninstall-bin uninstall-man uninstall-cron uninstall-upstart

uninstall:
	$(Q)echo "run one of the following:"
	$(Q)echo "  make uninstall-systemd-all (systemd based systems)"
	$(Q)echo "  make uninstall-upstart-all (upstart based systems)"
	$(Q)echo
	$(Q)echo "or check out the Makefile for specific rules"

clean:
	$(RM) -f common/$(PN)

.PHONY: help install-bin install-man install-cron install-systemd install-upstart install-openrc install-systemd-all install-upstart-all install uninstall-bin uninstall-man uninstall-cron uninstall-systemd uninstall-upstart uninstall-openrc uninstall-systemd-all uninstall clean
