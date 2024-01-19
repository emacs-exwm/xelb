PROTO_PATH := /usr/share/xcb

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
all: $(ELCS)

xcb-%.el: $(PROTO_PATH)/%.xml
	@echo -n "\n"Generating $@...
	@./xelb-gen $< > $@

# Dependencies needed for generating.
$(ELXS): xcb-xproto.el
xcb-composite.el: xcb-xfixes.el
xcb-cursor.el: xcb-render.el
xcb-damage.el: xcb-xfixes.el
xcb-present.el: xcb-randr.el xcb-xfixes.el xcb-sync.el
xcb-randr.el: xcb-render.el
xcb-xfixes.el: xcb-render.el xcb-shape.el
xcb-xinput.el: xcb-xfixes.el
xcb-xv.el: xcb-shm.el
xcb-xvmc.el: xcb-xv.el

# Generate an intermediate .el file from the xelb-gen script so that
# byte-compiling rules below apply.  This file will be deleted after the .elc is
# created.
.INTERMEDIATE: xelb-gen.el
xelb-gen.el: xelb-gen
	cp $< $@

# Dependencies needed for byte-compiling.
xcb-cursor.elc: xcb-render.elc xcb.elc
xcb-ewmh.elc: xcb.elc xcb-icccm.elc xcb.elc
xcb-icccm.elc: xcb.elc
xcb-keysyms.elc: xcb.elc xcb-xkb.elc
xcb-renderutil.elc: xcb.elc xcb-render.elc
xcb-systemtray.elc: xcb-ewmh.elc xcb.elc
xcb-types.elc: xcb-debug.elc
xcb-xembed.elc: xcb-icccm.elc
xcb-xim.elc: xcb-types.elc xcb-xlib.elc
xcb-xsettings.elc: xcb-icccm.elc xcb-types.elc
xcb.elc: xcb-xproto.elc xcb-xkb.elc
xelb.elc: xcb.elc
$(ELXS:.el=.elc): xcb-xproto.elc xcb-types.elc
xcb-composite.elc: xcb-xfixes.elc
xcb-damage.elc: xcb-xfixes.elc
xcb-present.elc: xcb-randr.elc xcb-xfixes.elc xcb-sync.elc
xcb-randr.elc: xcb-render.elc
xcb-xfixes.elc: xcb-render.elc xcb-shape.elc
xcb-xinput.elc: xcb-xfixes.elc
xcb-xv.elc: xcb-shm.elc
xcb-xvmc.elc: xcb-xv.elc
xelb-gen.elc: xcb-types.elc

%.elc: %.el
	@printf "Compiling $<\n"
	emacs --batch -Q -L . -f batch-byte-compile $<

.PHONY: clean
clean:
	@rm -vf $(ELGS) $(ELCS)
