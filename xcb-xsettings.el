;;; xcb-xsettings.el --- XSETTINGS protocol  -*- lexical-binding: t -*-

;; Copyright (C) 2024 Free Software Foundation, Inc.

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

;; This file is written by hand.  If possible we should auto-generate it
;; from an XML protocol specification.  The XSETTINGS protocol is
;; specified at: https://specifications.freedesktop.org/xsettings-spec/

;;; Code:

(require 'xcb-types)
(require 'xcb-icccm)

(defconst xcb:xsettings:-Type:Integer 0)
(defconst xcb:xsettings:-Type:String 1)
(defconst xcb:xsettings:-Type:Color 2)

(defclass xcb:xsettings:-Settings
  (xcb:-struct)
  ((byte-order :initarg :byte-order :type xcb:CARD8)
   (pad~0 :initform 3 :type xcb:-pad)
   (serial :initarg :serial :type xcb:CARD32)
   (settings-len :initarg :settings-len :type xcb:CARD32)
   (settings~ :initform
     '(name settings type xcb:xsettings:-SETTING size
            (xcb:-fieldref 'settings-len))
     :type xcb:-list)
   (settings :initarg :settings :type xcb:-ignore)))

(defclass xcb:xsettings:-SETTING
  (xcb:-struct)
  ((type :initarg :type :type xcb:CARD8)
   (pad~0 :initform 1 :type xcb:-pad)
   (name-len :initarg :name-len :type xcb:CARD16)
   (name~ :initform
     '(name name type xcb:char size
            (xcb:-fieldref 'name-len))
     :type xcb:-list)
   (name :initarg :name :type xcb:-ignore)
   (pad~1 :initform 4 :type xcb:-pad-align)
   (last-change-serial :initarg :last-change-serial :type xcb:CARD32)))

(defclass xcb:xsettings:-SETTING_INTEGER
  (xcb:xsettings:-SETTING)
  ((type :initform 'xcb:xsettings:-Type:Integer)
   (value :initarg :value :type xcb:INT32)))

(defclass xcb:xsettings:-SETTING_STRING
  (xcb:xsettings:-SETTING)
  ((type :initform 'xcb:xsettings:-Type:String)
   (value-len :initarg :value-len :type xcb:CARD32)
   (value~ :initform
     '(name value type xcb:char size
            (xcb:-fieldref 'value-len))
     :type xcb:-list)
   (value :initarg :value :type xcb:-ignore)
   (pad~2 :initform 4 :type xcb:-pad-align)))

(defclass xcb:xsettings:-SETTING_COLOR
  (xcb:xsettings:-SETTING)
  ((type :initform 'xcb:xsettings:-Type:Color)
   (red :initarg :red :type xcb:CARD16)
   (green :initarg :green :type xcb:CARD16)
   (blue :initarg :blue :type xcb:CARD16)
   (alpha :initarg :alpha :initform #xffff :type xcb:CARD16)))



(provide 'xcb-xsettings)

;;; xcb-xsettings.el ends here
