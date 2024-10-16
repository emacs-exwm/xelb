PROTO_PATH := /usr/share/xcb

ifeq ($(shell ! test -d $(PROTO_PATH) && echo ok),ok)
  $(warning Please set `PROTO_PATH` to the path to the XCB protocol definitions):
  $(warning make $(MFLAGS) $(MAKEOVERRIDES) $(MAKECMDGOALS) `PROTO_PATH=/opt/X11/...`)
  $(error Could not find directory `$(PROTO_PATH)`)
endif

EXTENSIONS := bigreq composite damage dbe dpms dri2 dri3 ge glx present randr \
record render res screensaver shape shm sync xc_misc xevie xf86dri \
xf86vidmode xfixes xinerama xinput xkb xprint xselinux xtest xvmc xv

ELXS = $(addprefix xcb-,$(addsuffix .el,$(EXTENSIONS)))
ELGS = xcb-xproto.el $(ELXS)
ELLS = xcb-cursor.el xcb-debug.el xcb-ewmh.el xcb-icccm.el xcb-keysyms.el \
       xcb-renderutil.el xcb-systemtray.el xcb-types.el xcb-xembed.el xcb-xim.el \
       xcb-xlib.el xcb-xsettings.el xcb.el xelb.el
ELS = $(ELLS) $(ELGS)
ELCS = $(ELS:.el=.elc) xelb-gen.elc

.PHONY: all
all: compile generate

xcb-%.el: $(PROTO_PATH)/%.xml
	@printf '%s\n' 'Generating $@...'
	@./xelb-gen $< > $@

# Generate an intermediate `.el` file from the xelb-gen script so that
# byte-compiling rules below apply.  This file will be deleted after the `.elc`
# is created.
.INTERMEDIATE: xelb-gen.el
xelb-gen.el: xelb-gen
	cp $< $@

# Dependencies needed for generating.
# We generate makefile fragments by grepping the `<import>`s in the `.xml`
# protocol definitions.
# See https://www.gnu.org/software/make/manual/html_node/Automatic-Prerequisites.html .
ELGDS=$(ELGS:.el=.el.d)
$(ELGDS): xcb-%.el.d: $(PROTO_PATH)/%.xml
	@printf "Inferring dependencies for $<\n"
	@{ IMPORTS=$$(grep '<import>' $< | sed -E -e 's,^[[:space:]]*<import>([^<]+)</import>,xcb-\1,' | tr '\n' ' '); \
	   test -n "$$IMPORTS" && printf '%s' 'xcb-$*.el:' && printf ' %s.el' $$IMPORTS && printf '\n'; \
	   test -n "$$IMPORTS" && printf '%s' 'xcb-$*.elc:' && printf ' %s.elc' $$IMPORTS && printf '\n'; \
	   true; \
	} >$@
# All generated `.el` files require `xcb-types.el`.
$(ELGS): xcb-types.el
$(ELGS:.el=.elc): xcb-types.elc

# Dependencies needed for byte-compiling.
# We grep the `require`s in non-generated `.el` files.
ELLDS=$(ELLS:.el=.el.d)
$(ELLDS): %.el.d: %.el
	@printf "Inferring dependencies for $<\n"
	@{ printf '%s' '$*.elc: '; \
	   grep "require 'xcb" $< | \
	   sed -E -e "s,.*\(require '([^)]+)\).*,\1.elc," | \
	   tr '\n' ' '; \
	   printf '\n'; \
	} >$@

# This is a small crutch: we want to avoid generating the `.el.d`s (which means
# parsing the XML and generating the corresponding `.el`s) in order to clean.
ifneq ($(MAKECMDGOALS),clean)
include $(ELLDS)
include $(ELGDS)
endif

%.elc: %.el
	@printf "Compiling $<\n"
	@emacs --batch -Q -L . -f batch-byte-compile $<

.PHONY: compile
compile: $(ELCS)

.PHONY: generate
generate: $(ELGS)

.PHONY: clean
clean:
	@rm -vf $(ELGS) $(ELLDS) $(ELCS) $(ELGDS)
