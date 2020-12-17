# Make sure $PERL5LIB is defined and valid.

# Assumes default installation. Change as required.
STRAWBERRY_BIN=C:\Strawberry\c\bin
ZLIB=$(STRAWBERRY_BIN)\ZLIB1__.DLL
LIBCRYPTO=$(STRAWBERRY_BIN)\LIBCRYPTO-1_1-X64__.DLL
LIBSSL=$(STRAWBERRY_BIN)\LIBSSL-1_1-X64__.DLL

# Point to a valid config file so the script can execute and PAR can collect dependencies.
UNIX_CONFIG_FILE=config.ini
WINDOWS_CONFIG_FILE=windows.ini

# Mojo requires html_entities and Commands.pm
ENTITIES_FILE=$(PERL5LIB)/Mojo/resources/html_entities.txt
COMMANDS_FILE=$(PERL5LIB)/Mojolicious/Commands.pm

# Also need two folders, the Mojolicious public and templates folders.:
MOJO_PUBLIC=$(PERL5LIB)/Mojolicious/public
MOJO_TEMPLATES=$(PERL5LIB)/Mojolicious/templates

# Mojo::IOLoop needs its resources folder
IOLOOP_RESOURCES=$(PERL5LIB)/Mojo/IOLoop/resources

# Need the TLS.pm file - an unfortunate hack so that Cwd::realpath doesn't fail. Temporary?
IOLOOP_TLS_PM=$(PERL5LIB)/Mojo/IOLoop/TLS.pm

#CACERT File
CACERT=$(PERL5LIB)/Mozilla/CA/cacert.pem

# Kill timer tells update-checker.pl to stop executing after the specified number of seconds. We can use this for pp to gather dependencies.
KILL_TIMER=5

# Command Line Args
WINDOWS_ARGS="--config=$(WINDOWS_CONFIG_FILE) --kill_timer=$(KILL_TIMER)"
UNIX_ARGS="--config=$(UNIX_CONFIG_FILE) --kill_timer=$(KILL_TIMER)"

define PP_ARGS
		--execute \
		--cachedeps=depcache \
		--addfile="$(ENTITIES_FILE);lib/Mojo/resources/html_entities.txt" \
		--addfile="$(COMMANDS_FILE);lib/Mojolicious/Commands.pm" \
		--addfile="$(IOLOOP_RESOURCES);lib/Mojo/IOLoop/resources" \
		--addfile="$(CACERT);cacert.pem" \
		--module="Mojo::IOLoop::TLS" \
		--module="IO::Socket::SSL" \
		--module="Net::SSLeay" \
		--unicode 
endef

# File extension (Only used for Windows
EXT=
ifeq ($(OS),Windows_NT)
	OSTYPE=windows
	EXT=.exe
	PP_ARGS+=--link=$(ZLIB) 
	PP_ARGS+=--link=$(LIBCRYPTO) 
	PP_ARGS+=--link=$(LIBSSL) 
	PP_ARGS+=--xargs=$(WINDOWS_ARGS)
else
    UNAME_S:=$(shell uname -s)
    ifeq ($(UNAME_S),Linux)
        OSTYPE=linux
    endif
    ifeq ($(UNAME_S),Darwin)
        OSTYPE=macos
    endif
	PP_ARGS+=--xargs=$(UNIX_ARGS)
endif

PP_ARGS+=--output="dcs-update-checker-$(OSTYPE)$(EXT)"

default:
	@echo "Building DCS Update Checker for $(OSTYPE)"
	pp $(PP_ARGS) update-check.pl
	@echo "Wrote file: dcs-update-checker-$(OSTYPE)$(EXT)"

clean:
	rm depcache
	rm dcs-update-checker-*

cleanwin:
	del depcache
	del dcs-update-checker-windows.exe

