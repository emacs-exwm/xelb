PROTO_PATH := /usr/share/xcb

EMACS_BIN := emacs -Q

EXTENSIONS := bigreq composite damage dpms dri2 dri3 ge glx present randr \
record render res screensaver shape shm sync xc_misc xevie xf86dri \
xf86vidmode xfixes xinerama xinput xkb xprint xselinux xtest xvmc xv

EXT_LIBS = $(addprefix lisp/xcb-,$(addsuffix .el,$(EXTENSIONS)))
LIBS = lisp/xcb-xproto.el $(EXT_LIBS)

all: clean $(LIBS)

lisp/xcb-%.el: $(PROTO_PATH)/%.xml
	@echo -n "\n"Generating $@...
	@$(EMACS_BIN) --script ./xelb_gen.el $< lisp/ > $@

$(EXT_LIBS): lisp/xcb-xproto.el

lisp/xcb-composite.el: lisp/xcb-xfixes.el
lisp/xcb-damage.el: lisp/xcb-xfixes.el
lisp/xcb-present.el: lisp/xcb-randr.el lisp/xcb-xfixes.el lisp/xcb-sync.el
lisp/xcb-randr.el: lisp/xcb-render.el
lisp/xcb-xfixes.el: lisp/xcb-render.el lisp/xcb-shape.el
lisp/xcb-xinput.el: lisp/xcb-xfixes.el
lisp/xcb-xvmc.el: lisp/xcb-xv.el
lisp/xcb-xv.el: lisp/xcb-shm.el

.PHONY: clean

clean:
	@rm -vf $(LIBS)
