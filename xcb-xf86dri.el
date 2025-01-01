;;; xcb-xf86dri.el --- X11 XF86Dri extension  -*- lexical-binding: t -*-

;; Copyright (C) 2015-2024 Free Software Foundation, Inc.

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This file was generated by 'xelb-gen' from 'xf86dri.xml',
;; which you can retrieve from <git://anongit.freedesktop.org/xcb/proto>.

;;; Code:

(require 'xcb-types)

(defconst xcb:xf86dri:-extension-xname "XFree86-DRI")
(defconst xcb:xf86dri:-extension-name "XF86Dri")
(defconst xcb:xf86dri:-major-version 4)
(defconst xcb:xf86dri:-minor-version 1)

(defclass xcb:xf86dri:DrmClipRect
  (xcb:-struct)
  ((x1 :initarg :x1 :type xcb:INT16)
   (y1 :initarg :y1 :type xcb:INT16)
   (x2 :initarg :x2 :type xcb:INT16)
   (x3 :initarg :x3 :type xcb:INT16)))

(defclass xcb:xf86dri:QueryVersion
  (xcb:-request)
  ((~opcode :initform 0 :type xcb:-u1)))
(defclass xcb:xf86dri:QueryVersion~reply
  (xcb:-reply)
  ((pad~0 :initform 1 :type xcb:-pad)
   (~sequence :type xcb:CARD16)
   (length :type xcb:CARD32)
   (dri-major-version :initarg :dri-major-version :type xcb:CARD16)
   (dri-minor-version :initarg :dri-minor-version :type xcb:CARD16)
   (dri-minor-patch :initarg :dri-minor-patch :type xcb:CARD32)))

(defclass xcb:xf86dri:QueryDirectRenderingCapable
  (xcb:-request)
  ((~opcode :initform 1 :type xcb:-u1)
   (screen :initarg :screen :type xcb:CARD32)))
(defclass xcb:xf86dri:QueryDirectRenderingCapable~reply
  (xcb:-reply)
  ((pad~0 :initform 1 :type xcb:-pad)
   (~sequence :type xcb:CARD16)
   (length :type xcb:CARD32)
   (is-capable :initarg :is-capable :type xcb:BOOL)))

(defclass xcb:xf86dri:OpenConnection
  (xcb:-request)
  ((~opcode :initform 2 :type xcb:-u1)
   (screen :initarg :screen :type xcb:CARD32)))
(defclass xcb:xf86dri:OpenConnection~reply
  (xcb:-reply)
  ((pad~0 :initform 1 :type xcb:-pad)
   (~sequence :type xcb:CARD16)
   (length :type xcb:CARD32)
   (sarea-handle-low :initarg :sarea-handle-low :type xcb:CARD32)
   (sarea-handle-high :initarg :sarea-handle-high :type xcb:CARD32)
   (bus-id-len :initarg :bus-id-len :type xcb:CARD32)
   (pad~1 :initform 12 :type xcb:-pad)
   (bus-id~ :initform
            '(name bus-id type xcb:char size
                   (xcb:-fieldref 'bus-id-len))
            :type xcb:-list)
   (bus-id :initarg :bus-id :type xcb:-ignore)))

(defclass xcb:xf86dri:CloseConnection
  (xcb:-request)
  ((~opcode :initform 3 :type xcb:-u1)
   (screen :initarg :screen :type xcb:CARD32)))

(defclass xcb:xf86dri:GetClientDriverName
  (xcb:-request)
  ((~opcode :initform 4 :type xcb:-u1)
   (screen :initarg :screen :type xcb:CARD32)))
(defclass xcb:xf86dri:GetClientDriverName~reply
  (xcb:-reply)
  ((pad~0 :initform 1 :type xcb:-pad)
   (~sequence :type xcb:CARD16)
   (length :type xcb:CARD32)
   (client-driver-major-version :initarg :client-driver-major-version :type xcb:CARD32)
   (client-driver-minor-version :initarg :client-driver-minor-version :type xcb:CARD32)
   (client-driver-patch-version :initarg :client-driver-patch-version :type xcb:CARD32)
   (client-driver-name-len :initarg :client-driver-name-len :type xcb:CARD32)
   (pad~1 :initform 8 :type xcb:-pad)
   (client-driver-name~ :initform
                        '(name client-driver-name type xcb:char size
                               (xcb:-fieldref 'client-driver-name-len))
                        :type xcb:-list)
   (client-driver-name :initarg :client-driver-name :type xcb:-ignore)))

(defclass xcb:xf86dri:CreateContext
  (xcb:-request)
  ((~opcode :initform 5 :type xcb:-u1)
   (screen :initarg :screen :type xcb:CARD32)
   (visual :initarg :visual :type xcb:CARD32)
   (context :initarg :context :type xcb:CARD32)))
(defclass xcb:xf86dri:CreateContext~reply
  (xcb:-reply)
  ((pad~0 :initform 1 :type xcb:-pad)
   (~sequence :type xcb:CARD16)
   (length :type xcb:CARD32)
   (hw-context :initarg :hw-context :type xcb:CARD32)))

(defclass xcb:xf86dri:DestroyContext
  (xcb:-request)
  ((~opcode :initform 6 :type xcb:-u1)
   (screen :initarg :screen :type xcb:CARD32)
   (context :initarg :context :type xcb:CARD32)))

(defclass xcb:xf86dri:CreateDrawable
  (xcb:-request)
  ((~opcode :initform 7 :type xcb:-u1)
   (screen :initarg :screen :type xcb:CARD32)
   (drawable :initarg :drawable :type xcb:CARD32)))
(defclass xcb:xf86dri:CreateDrawable~reply
  (xcb:-reply)
  ((pad~0 :initform 1 :type xcb:-pad)
   (~sequence :type xcb:CARD16)
   (length :type xcb:CARD32)
   (hw-drawable-handle :initarg :hw-drawable-handle :type xcb:CARD32)))

(defclass xcb:xf86dri:DestroyDrawable
  (xcb:-request)
  ((~opcode :initform 8 :type xcb:-u1)
   (screen :initarg :screen :type xcb:CARD32)
   (drawable :initarg :drawable :type xcb:CARD32)))

(defclass xcb:xf86dri:GetDrawableInfo
  (xcb:-request)
  ((~opcode :initform 9 :type xcb:-u1)
   (screen :initarg :screen :type xcb:CARD32)
   (drawable :initarg :drawable :type xcb:CARD32)))
(defclass xcb:xf86dri:GetDrawableInfo~reply
  (xcb:-reply)
  ((pad~0 :initform 1 :type xcb:-pad)
   (~sequence :type xcb:CARD16)
   (length :type xcb:CARD32)
   (drawable-table-index :initarg :drawable-table-index :type xcb:CARD32)
   (drawable-table-stamp :initarg :drawable-table-stamp :type xcb:CARD32)
   (drawable-origin-X :initarg :drawable-origin-X :type xcb:INT16)
   (drawable-origin-Y :initarg :drawable-origin-Y :type xcb:INT16)
   (drawable-size-W :initarg :drawable-size-W :type xcb:INT16)
   (drawable-size-H :initarg :drawable-size-H :type xcb:INT16)
   (num-clip-rects :initarg :num-clip-rects :type xcb:CARD32)
   (back-x :initarg :back-x :type xcb:INT16)
   (back-y :initarg :back-y :type xcb:INT16)
   (num-back-clip-rects :initarg :num-back-clip-rects :type xcb:CARD32)
   (clip-rects~ :initform
                '(name clip-rects type xcb:xf86dri:DrmClipRect size
                       (xcb:-fieldref 'num-clip-rects))
                :type xcb:-list)
   (clip-rects :initarg :clip-rects :type xcb:-ignore)
   (back-clip-rects~ :initform
                     '(name back-clip-rects type xcb:xf86dri:DrmClipRect size
                            (xcb:-fieldref 'num-back-clip-rects))
                     :type xcb:-list)
   (back-clip-rects :initarg :back-clip-rects :type xcb:-ignore)))

(defclass xcb:xf86dri:GetDeviceInfo
  (xcb:-request)
  ((~opcode :initform 10 :type xcb:-u1)
   (screen :initarg :screen :type xcb:CARD32)))
(defclass xcb:xf86dri:GetDeviceInfo~reply
  (xcb:-reply)
  ((pad~0 :initform 1 :type xcb:-pad)
   (~sequence :type xcb:CARD16)
   (length :type xcb:CARD32)
   (framebuffer-handle-low :initarg :framebuffer-handle-low :type xcb:CARD32)
   (framebuffer-handle-high :initarg :framebuffer-handle-high :type xcb:CARD32)
   (framebuffer-origin-offset :initarg :framebuffer-origin-offset :type xcb:CARD32)
   (framebuffer-size :initarg :framebuffer-size :type xcb:CARD32)
   (framebuffer-stride :initarg :framebuffer-stride :type xcb:CARD32)
   (device-private-size :initarg :device-private-size :type xcb:CARD32)
   (device-private~ :initform
                    '(name device-private type xcb:CARD32 size
                           (xcb:-fieldref 'device-private-size))
                    :type xcb:-list)
   (device-private :initarg :device-private :type xcb:-ignore)))

(defclass xcb:xf86dri:AuthConnection
  (xcb:-request)
  ((~opcode :initform 11 :type xcb:-u1)
   (screen :initarg :screen :type xcb:CARD32)
   (magic :initarg :magic :type xcb:CARD32)))
(defclass xcb:xf86dri:AuthConnection~reply
  (xcb:-reply)
  ((pad~0 :initform 1 :type xcb:-pad)
   (~sequence :type xcb:CARD16)
   (length :type xcb:CARD32)
   (authenticated :initarg :authenticated :type xcb:CARD32)))



(provide 'xcb-xf86dri)

;;; xcb-xf86dri.el ends here
