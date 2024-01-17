# X protocol Emacs Lisp Binding

XELB (X protocol Emacs Lisp Binding) is a pure Elisp implementation of X11
protocol based on the XML description files from XCB project.
It features an object-oriented API and permits a certain degree of concurrency.
It should enable you to implement some low-level X11 applications.
Please refer to [xelb.el](https://github.com/emacs-exwm/xelb/blob/master/xelb.el)
for more details.

## Regenerating XCB Bindings

Most (although not all) bindings in this library are auto-generated from [xcb-proto][]. To regenerate them:

1. Install your distro's `xcb-proto` package (`apt install xcb-proto`, `pacman -S xcb-proto`, etc.).
2. Run `make`.

Alternatively:

1. Download the latest `xcb-proto` [release][xcb-proto-releases].
2. Extract it.
3. Run `make PROTO_PATH=/path/to/xcb-proto/src`

[xcb-proto]: https://gitlab.freedesktop.org/xorg/proto/xcbproto
[xcb-proto-releases]: (https://gitlab.freedesktop.org/xorg/proto/xcbproto/-/tags)
