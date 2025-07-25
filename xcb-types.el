;;; xcb-types.el --- Type definitions for XCB  -*- lexical-binding: t -*-

;; Copyright (C) 2015-2025 Free Software Foundation, Inc.

;; Author: Chris Feng <chris.w.feng@gmail.com>

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
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This library defines various data types frequently used in XELB.  Simple
;; types are defined with `cl-deftype' while others are defined as classes.
;; Basically, data types are used for converting objects to/from byte arrays
;; rather than for validation purpose.  Classes defined elsewhere should also
;; support `xcb:marshal' and `xcb:unmarshal' methods in order to be considered
;; a type.  Most classes defined here are direct or indirect subclasses of
;; `xcb:-struct', which has implemented the fundamental marshalling and
;; unmarshalling methods.  These classes again act as the superclasses for more
;; concrete ones.  You may use `eieio-browse' to easily get an overview of the
;; inheritance hierarchies of all classes defined.

;; Please pay special attention to the byte order adopted in your application.
;; The global variable `xcb:lsb' specifies the byte order at the time of
;; instantiating a class (e.g. via `make-instance').  You may let-bind it to
;; temporarily change the byte order locally.

;; Todo:
;; + The current implementation of `eieio-default-eval-maybe' only `eval's a
;;   certain type of forms.  If this is changed in the future, we will have to
;;   adapt our codes accordingly.
;; + <paramref> for `xcb:-marshal-field'?

;; References:
;; + X protocol (https://www.x.org/releases/X11R7.7/doc/xproto/x11protocol.txt)

;;; Code:

(require 'compat)
(require 'cl-lib) ; cl-coerce
(require 'cl-generic)
(require 'eieio)
(require 'xcb-debug)

;; We can't require `xcb-xkb' because it requires us.
(eieio-declare-slots xkbType)
;; We can't require `xcb-preset' because it requires us.
(eieio-declare-slots extension) ;; xcb:preset:Generic
;; We can't require `xcb-present' because it requires us.
(eieio-declare-slots ~sequence evtype) ;xcb:present:Generic

;; Require subr-x on Emacs < 29 for when-let*, it has since been moved to
;; subr (autoloaded).
(eval-when-compile (when (< emacs-major-version 29) (require 'subr-x)))

(define-minor-mode xcb:debug
  "Debug-logging enabled if non-nil."
  :group 'debug
  :global t)

(defmacro xcb:-log (&optional format-string &rest objects)
  "Emit a message prepending the name of the function being executed.

FORMAT-STRING is a string specifying the message to output, as in
`format'.  The OBJECTS arguments specify the substitutions."
  (unless format-string (setq format-string ""))
  `(when xcb:debug
     (xcb-debug:message ,(concat "%s%s:\t" format-string "\n")
                        (if xcb-debug:log-time-function
                            (funcall xcb-debug:log-time-function)
                          "")
                        (xcb-debug:compile-time-function-name)
                        ,@objects)
     nil))

;;;; Utility functions

(defsubst xcb:-pack-u1 (value)
  "1 byte unsigned integer => byte array."
  (vector value))

(defsubst xcb:-pack-i1 (value)
  "1 byte signed integer => byte array."
  (xcb:-pack-u1 (if (>= value 0) value
                  (1+ (logand #xFF (lognot (- value)))))))

(defsubst xcb:-pack-u2 (value)
  "2 bytes unsigned integer => byte array (MSB first)."
  (vector (logand (ash value -8) #xFF) (logand value #xFF)))

(defsubst xcb:-pack-u2-lsb (value)
  "2 bytes unsigned integer => byte array (LSB first)."
  (vector (logand value #xFF) (logand (ash value -8) #xFF)))

(defsubst xcb:-pack-i2 (value)
  "2 bytes signed integer => byte array (MSB first)."
  (xcb:-pack-u2 (if (>= value 0) value
                  (1+ (logand #xFFFF (lognot (- value)))))))

(defsubst xcb:-pack-i2-lsb (value)
  "2 bytes signed integer => byte array (LSB first)."
  (xcb:-pack-u2-lsb (if (>= value 0) value
                      (1+ (logand #xFFFF (lognot (- value)))))))

;; Due to loss of significance of floating-point numbers, `xcb:-pack-u8' and
;; `xcb:-pack-u8-lsb' may return approximate results.
(eval-and-compile
  (if (/= 0 (ash 1 32))
      ;; 64 bit
      (progn
        (defsubst xcb:-pack-u4 (value)
          "4 bytes unsigned integer => byte array (MSB first, 64-bit)."
          (vector (logand (ash value -24) #xFF) (logand (ash value -16) #xFF)
                  (logand (ash value -8) #xFF) (logand value #xFF)))
        (defsubst xcb:-pack-u4-lsb (value)
          "4 byte unsigned integer => byte array (LSB first, 64-bit)."
          (vector (logand value #xFF)
                  (logand (ash value -8) #xFF)
                  (logand (ash value -16) #xFF)
                  (logand (ash value -24) #xFF)))
        (defsubst xcb:-pack-u8 (value)
          "8 bytes unsigned integer => byte array (MSB first)."
          (if (integerp value)
              (vector (logand (ash value -56) #xFF)
                      (logand (ash value -48) #xFF)
                      (logand (ash value -40) #xFF)
                      (logand (ash value -32) #xFF)
                      (logand (ash value -24) #xFF)
                      (logand (ash value -16) #xFF)
                      (logand (ash value -8) #xFF)
                      (logand value #xFF))
            (let* ((msdw (min 4294967295. (truncate value 4294967296.)))
                   (lsdw (min 4294967295.
                              (truncate (- value (* msdw 4294967296.0))))))
              (vector (logand (ash msdw -24) #xFF) (logand (ash msdw -16) #xFF)
                      (logand (ash msdw -8) #xFF) (logand msdw #xFF)
                      (logand (ash lsdw -24) #xFF) (logand (ash lsdw -16) #xFF)
                      (logand (ash lsdw -8) #xFF) (logand lsdw #xFF)))))
        (defsubst xcb:-pack-u8-lsb (value)
          "8 bytes unsigned integer => byte array (LSB first)."
          (if (integerp value)
              (vector (logand value #xFF)
                      (logand (ash value -8) #xFF)
                      (logand (ash value -16) #xFF)
                      (logand (ash value -24) #xFF)
                      (logand (ash value -32) #xFF)
                      (logand (ash value -40) #xFF)
                      (logand (ash value -48) #xFF)
                      (logand (ash value -56) #xFF))
            (let* ((msdw (min 4294967295. (truncate value 4294967296.)))
                   (lsdw (min 4294967295.
                              (truncate (- value (* msdw 4294967296.0))))))
              (vector (logand lsdw #xFF) (logand (ash lsdw -8) #xFF)
                      (logand (ash lsdw -16) #xFF) (logand (ash lsdw -24) #xFF)
                      (logand msdw #xFF)
                      (logand (ash msdw -8) #xFF)
                      (logand (ash msdw -16) #xFF)
                      (logand (ash msdw -24) #xFF))))))
    ;; 32 bit (30-bit actually; large numbers are represented as float type)
    (defsubst xcb:-pack-u4 (value)
      "4 bytes unsigned integer => byte array (MSB first, 32-bit)."
      (if (integerp value)
          (vector (logand (ash value -24) #xFF) (logand (ash value -16) #xFF)
                  (logand (ash value -8) #xFF) (logand value #xFF))
        (let* ((msw (truncate value #x10000))
               (lsw (truncate (- value (* msw 65536.0)))))
          (vector (logand (ash msw -8) #xFF) (logand msw #xFF)
                  (logand (ash lsw -8) #xFF) (logand lsw #xFF)))))
    (defsubst xcb:-pack-u4-lsb (value)
      "4 bytes unsigned integer => byte array (LSB first, 32-bit)."
      (if (integerp value)
          (vector (logand value #xFF) (logand (ash value -8) #xFF)
                  (logand (ash value -16) #xFF) (logand (ash value -24) #xFF))
        (let* ((msw (truncate value #x10000))
               (lsw (truncate (- value (* msw 65536.0)))))
          (vector (logand lsw #xFF) (logand (ash lsw -8) #xFF)
                  (logand msw #xFF) (logand (ash msw -8) #xFF)))))
    (defsubst xcb:-pack-u8 (value)
      "8 bytes unsigned integer => byte array (MSB first, 32-bit)."
      (if (integerp value)
          (vector 0 0 0 0
                  (logand (ash value -24) #xFF) (logand (ash value -16) #xFF)
                  (logand (ash value -8) #xFF) (logand value #xFF))
        (let* ((msw (min #xFFFF (truncate value 281474976710656.)))
               (w1 (min #xFFFF
                        (truncate (setq value
                                        (- value (* msw 281474976710656.0)))
                                  4294967296.)))
               (w2 (min #xFFFF
                        (truncate (setq value (- value (* w1 4294967296.0)))
                                  #x10000)))
               (lsw (min #xFFFF (truncate (- value (* w2 65536.0))))))
          (vector (logand (ash msw -8) #xFF) (logand msw #xFF)
                  (logand (ash w1 -8) #xFF) (logand w1 #xFF)
                  (logand (ash w2 -8) #xFF) (logand w2 #xFF)
                  (logand (ash lsw -8) #xFF) (logand lsw #xFF)))))
    (defsubst xcb:-pack-u8-lsb (value)
      "8 bytes unsigned integer => byte array (LSB first, 32-bit)."
      (if (integerp value)
          (vector (logand value #xFF) (logand (ash value -8) #xFF)
                  (logand (ash value -16) #xFF) (logand (ash value -24) #xFF)
                  0 0 0 0)
        (let* ((msw (min #xFFFF (truncate value 281474976710656.)))
               (w1 (min #xFFFF
                        (truncate (setq value
                                        (- value (* msw 281474976710656.0)))
                                  4294967296.)))
               (w2 (min #xFFFF
                        (truncate (setq value (- value (* w1 4294967296.0)))
                                  #x10000)))
               (lsw (min #xFFFF (truncate (- value (* w2 65536.0))))))
          (vector (logand lsw #xFF) (logand (ash lsw -8) #xFF)
                  (logand w2 #xFF) (logand (ash w2 -8) #xFF)
                  (logand w1 #xFF) (logand (ash w1 -8) #xFF)
                  (logand msw #xFF) (logand (ash msw -8) #xFF)))))))

(defsubst xcb:-pack-i4 (value)
  "4 bytes signed integer => byte array (MSB first)."
  (xcb:-pack-u4 (if (>= value 0)
                    value
                  (+ value 4294967296.)))) ;treated as float for 32-bit

(defsubst xcb:-pack-i4-lsb (value)
  "4 bytes signed integer => byte array (LSB first)."
  (xcb:-pack-u4-lsb (if (>= value 0)
                        value
                      (+ value 4294967296.)))) ;treated as float for 32-bit

(defsubst xcb:-unpack-u1 (data offset)
  "Byte array => 1 byte unsigned integer."
  (aref data offset))

(defsubst xcb:-unpack-i1 (data offset)
  "Byte array => 1 byte signed integer."
  (let ((value (xcb:-unpack-u1 data offset)))
    (if (= 0 (logand #x80 value))
        value
      (- (logand #xFF (lognot (1- value)))))))

(defsubst xcb:-unpack-u2 (data offset)
  "Byte array => 2 bytes unsigned integer (MSB first)."
  (logior (ash (aref data offset) 8) (aref data (1+ offset))))

(defsubst xcb:-unpack-u2-lsb (data offset)
  "Byte array => 2 bytes unsigned integer (LSB first)."
  (logior (aref data offset) (ash (aref data (1+ offset)) 8)))

(defsubst xcb:-unpack-i2 (data offset)
  "Byte array => 2 bytes signed integer (MSB first)."
  (let ((value (xcb:-unpack-u2 data offset)))
    (if (= 0 (logand #x8000 value))
        value
      (- (logand #xFFFF (lognot (1- value)))))))

(defsubst xcb:-unpack-i2-lsb (data offset)
  "Byte array => 2 bytes signed integer (LSB first)."
  (let ((value (xcb:-unpack-u2-lsb data offset)))
    (if (= 0 (logand #x8000 value))
        value
      (- (logand #xFFFF (lognot (1- value)))))))

;; Due to loss of significance of floating-point numbers, `xcb:-unpack-u8' and
;; `xcb:-unpack-u8-lsb' may return approximate results.
(eval-and-compile
  (if (/= 0 (ash 1 32))
      ;; 64-bit
      (progn
        (defsubst xcb:-unpack-u4 (data offset)
          "Byte array => 4 bytes unsigned integer (MSB first, 64-bit)."
          (logior (ash (aref data offset) 24) (ash (aref data (1+ offset)) 16)
                  (ash (aref data (+ offset 2)) 8) (aref data (+ offset 3))))
        (defsubst xcb:-unpack-u4-lsb (data offset)
          "Byte array => 4 bytes unsigned integer (LSB first, 64-bit)."
          (logior (aref data offset) (ash (aref data (1+ offset)) 8)
                  (ash (aref data (+ offset 2)) 16)
                  (ash (aref data (+ offset 3)) 24)))
        (defsubst xcb:-unpack-u8 (data offset)
          "Byte array => 8 bytes unsigned integer (MSB first)."
          (let ((msb (aref data offset)))
            (+ (if (> msb 31) (* msb 72057594037927936.0) (ash msb 56))
               (logior (ash (aref data (1+ offset)) 48)
                       (ash (aref data (+ offset 2)) 40)
                       (ash (aref data (+ offset 3)) 32)
                       (ash (aref data (+ offset 4)) 24)
                       (ash (aref data (+ offset 5)) 16)
                       (ash (aref data (+ offset 6)) 8)
                       (aref data (+ offset 7))))))
        (defsubst xcb:-unpack-u8-lsb (data offset)
          "Byte array => 8 bytes unsigned integer (LSB first)."
          (let ((msb (aref data (+ offset 7))))
            (+ (if (> msb 31) (* msb 72057594037927936.0) (ash msb 56))
               (logior (ash (aref data (+ offset 6)) 48)
                       (ash (aref data (+ offset 5)) 40)
                       (ash (aref data (+ offset 4)) 32)
                       (ash (aref data (+ offset 3)) 24)
                       (ash (aref data (+ offset 2)) 16)
                       (ash (aref data (1+ offset)) 8)
                       (aref data offset))))))
    ;; 32-bit (30-bit actually; large numbers are represented as float type)
    (defsubst xcb:-unpack-u4 (data offset)
      "Byte array => 4 bytes unsigned integer (MSB first, 32-bit)."
      (let ((msb (aref data offset)))
        (+ (if (> msb 31) (* msb 16777216.0) (ash msb 24))
           (logior (ash (aref data (1+ offset)) 16)
                   (ash (aref data (+ offset 2)) 8)
                   (aref data (+ offset 3))))))
    (defsubst xcb:-unpack-u4-lsb (data offset)
      "Byte array => 4 bytes unsigned integer (LSB first, 32-bit)."
      (let ((msb (aref data (+ offset 3))))
        (+ (if (> msb 31) (* msb 16777216.0) (ash msb 24))
           (logior (aref data offset)
                   (ash (aref data (1+ offset)) 8)
                   (ash (aref data (+ offset 2)) 16)))))
    (defsubst xcb:-unpack-u8 (data offset)
      "Byte array => 8 bytes unsigned integer (MSB first, 32-bit)."
      (+ (* (aref data offset) 72057594037927936.0)
         (* (aref data (1+ offset)) 281474976710656.0)
         (* (aref data (+ offset 2)) 1099511627776.0)
         (* (aref data (+ offset 3)) 4294967296.0)
         (* (aref data (+ offset 4)) 16777216.0)
         (logior (ash (aref data (+ offset 5)) 16)
                 (ash (aref data (+ offset 6)) 8)
                 (aref data (+ offset 7)))))
    (defsubst xcb:-unpack-u8-lsb (data offset)
      "Byte array => 8 bytes unsigned integer (LSB first, 32-bit)."
      (+ (* (aref data (+ offset 7)) 72057594037927936.0)
         (* (aref data (+ offset 6)) 281474976710656.0)
         (* (aref data (+ offset 5)) 1099511627776.0)
         (* (aref data (+ offset 4)) 4294967296.0)
         (* (aref data (+ offset 3)) 16777216.0)
         (logior (ash (aref data (+ offset 2)) 16)
                 (ash (aref data (1+ offset)) 8)
                 (aref data offset))))))

(defsubst xcb:-unpack-i4 (data offset)
  "Byte array => 4 bytes signed integer (MSB first)."
  (let ((value (xcb:-unpack-u4 data offset)))
    (if (< value 2147483648.)           ;treated as float for 32-bit
        value
      (- value 4294967296.))))          ;treated as float for 32-bit

(defsubst xcb:-unpack-i4-lsb (data offset)
  "Byte array => 4 bytes signed integer (LSB first)."
  (let ((value (xcb:-unpack-u4-lsb data offset)))
    (if (< value 2147483648.)           ;treated as float for 32-bit
        value
      (- value 4294967296.))))          ;treated as float for 32-bit

(defsubst xcb:-f64-to-binary64 (value)
  "Encode a 64-bit float VALUE as a binary64 (IEEE 754)."
  (let* ((sigexp (frexp value))
         (exp (+ (cdr sigexp) 1022))
         (frac (abs (car sigexp)))
         (isneg (< (copysign 1.0 (car sigexp)) 0)) ; use `copysign' to detect -0.0
         (signmask (if isneg #x8000000000000000 0)))
    (+ (cond ((zerop frac) 0)                                          ; 0
             ((isnan frac) #xff0000000000001)                          ; NaN
             ((or (>= exp 2047) (= frac 1e+INF)) #x7ff0000000000000)   ; Inf
             ((<= exp 0) (ash (round (ldexp frac 52)) exp))            ; Subnormal
             (t (+ (ash exp 52) (logand #xfffffffffffff
                                        (round (ldexp frac 53))))))    ; Normal
       signmask)))

(defsubst xcb:-f32-to-binary32 (value)
  "Encode a 32-bit float VALUE as a binary32 (IEEE 754)."
  (let* ((sigexp (frexp value))
         (exp (+ (cdr sigexp) 126))
         (frac (abs (car sigexp)))
         (isneg (< (copysign 1.0 (car sigexp)) 0)) ; use `copysign' to detect -0.0
         (signmask (if isneg #x80000000 0)))
    (+ (cond ((zerop frac) 0)                                                ; 0
             ((isnan frac) #x7f800001)                                       ; NaN
             ((or (>= exp 255) (= frac 1e+INF)) #x7f800000)                  ; Inf
             ((<= exp 0) (ash (round (ldexp frac 23)) exp))                  ; Subnormal
             (t (+ (ash exp 23) (logand #x7fffff (round (ldexp frac 24)))))) ; Normal
       signmask)))

(defsubst xcb:-binary64-to-f64 (value)
  "Decode binary64 VALUE into a float."
  (let ((sign (pcase (ash value -63)
                (0 +0.0)
                (1 -0.0)
                (_ (error "[XCB] Value too large for a float64: %d" value))))
        (exp (logand 2047 (ash value -52)))
        (frac (logand #xfffffffffffff value)))
    (copysign ; Use copysign, not multiplication, to deal with +/- NAN.
     (pcase exp
       (2047 (if (zerop frac) 1e+INF 1e+NaN))                 ; INF/NAN
       (0    (ldexp frac -1074))                              ; Subnormal
       (_    (ldexp (+ #x10000000000000 frac) (- exp 1075)))) ; Normal
     sign)))

(defsubst xcb:-binary32-to-f32 (value)
  "Decode binary32 VALUE into a float."
  (let ((sign (pcase (ash value -31)
                (0 +0.0)
                (1 -0.0)
                (_ (error "[XCB] Value too large for a float32: %d" value))))
        (exp (logand 255 (ash value -23)))
        (frac (logand #x7fffff value)))
    (copysign ; Use copysign, not multiplication, to deal with +/- NAN.
     (pcase exp
       (255 (if (zerop frac) 1e+INF 1e+NaN))        ; INF/NAN
       (0   (ldexp frac -149))                      ; Subnormal
       (_   (ldexp (+ #x800000 frac) (- exp 150)))) ; Normal
     sign)))

(defmacro xcb:-fieldref (field)
  "Evaluate a <fieldref> field."
  `(slot-value obj ,field))

(defmacro xcb:-paramref (field)
  "Evaluate a <paramref> field."
  `(slot-value ctx ,field))

(defsubst xcb:-request-class->reply-class (request)
  "Return the reply class corresponding to the request class REQUEST."
  (intern-soft (concat (symbol-name request) "~reply")))

;;;; Basic types

;; typedef in C
(defmacro xcb:deftypealias (new-type old-type)
  "Define NEW-TYPE as an alias of type OLD-TYPE.

Also the fundamental type is stored in the `xcb--typealias'
variable property (for internal use only)."
  `(progn
     ;; FIXME: `new-type' should probably just not be eval'd at all,
     ;; but that requires changing all callers not to quote their arg.
     (cl-deftype ,(eval new-type t) nil ,old-type)
     (put ,new-type 'xcb--typealias
          (or (get ,old-type 'xcb--typealias) ,old-type))))

;; 1/2/4 B signed/unsigned integer
(cl-deftype xcb:-i1 () t)
(cl-deftype xcb:-i2 () t)
(cl-deftype xcb:-i4 () t)
(cl-deftype xcb:-u1 () t)
(cl-deftype xcb:-u2 () t)
(cl-deftype xcb:-u4 () t)
;; 8 B unsigned integer
(cl-deftype xcb:-u8 () t)
;; floats & doubles
(cl-deftype xcb:-f32 () t)
(cl-deftype xcb:-f64 () t)
;; <pad>
(cl-deftype xcb:-pad () t)
;; <pad> with align attribute
(cl-deftype xcb:-pad-align () t)
;; <fd>
(xcb:deftypealias 'xcb:fd 'xcb:-i4)
;; <list>
(cl-deftype xcb:-list () t)
;; <switch>
(cl-deftype xcb:-switch () t)
;; This type of data is not involved in marshalling/unmarshalling
(cl-deftype xcb:-ignore () t)
;; C types and types missing in XCB
(cl-deftype xcb:void () t)
(xcb:deftypealias 'xcb:char 'xcb:-u1)
(xcb:deftypealias 'xcb:BYTE 'xcb:-u1)
(xcb:deftypealias 'xcb:INT8 'xcb:-i1)
(xcb:deftypealias 'xcb:INT16 'xcb:-i2)
(xcb:deftypealias 'xcb:INT32 'xcb:-i4)
(xcb:deftypealias 'xcb:CARD8 'xcb:-u1)
(xcb:deftypealias 'xcb:CARD16 'xcb:-u2)
(xcb:deftypealias 'xcb:CARD32 'xcb:-u4)
(xcb:deftypealias 'xcb:CARD64 'xcb:-u8)
(xcb:deftypealias 'xcb:BOOL 'xcb:-u1)
(xcb:deftypealias 'xcb:float 'xcb:-f32)
(xcb:deftypealias 'xcb:double 'xcb:-f64)

;;;; Struct type

(eval-and-compile
  (defvar xcb:lsb t
    "Non-nil for LSB first (i.e., little-endian), nil otherwise.

Consider let-bind it rather than change its global value."))

(defclass xcb:--struct ()
  nil)

(cl-defmethod slot-unbound ((object xcb:--struct) class slot-name fn)
  (unless (eq fn #'oref-default)
    (xcb:-log "unbound-slot: %s" (list (eieio-class-name class)
                                       (eieio-object-name object)
                                       slot-name fn))))

(defclass xcb:-struct (xcb:--struct)
  ((~lsb :initarg :~lsb
         :initform (symbol-value 'xcb:lsb) ;see `eieio-default-eval-maybe'
         :type xcb:-ignore)
   (~size :initform nil :type xcb:-ignore))
  :documentation "Struct type.")

(cl-defmethod xcb:marshal ((obj xcb:-struct))
  "Return the byte-array representation of struct OBJ."
  (let ((slots (eieio-class-slots (eieio-object-class obj)))
        result name type value)
    (catch 'break
      (dolist (slot slots)
        (setq type (cl--slot-descriptor-type slot))
        (unless (eq type 'xcb:-ignore)
          (setq name (eieio-slot-descriptor-name slot))
          (setq value (slot-value obj name))
          (when (symbolp value)        ;see `eieio-default-eval-maybe'
            (setq value (symbol-value value)))
          (setq result
                (vconcat result (xcb:-marshal-field obj type value
                                                    (length result))))
          (when (eq type 'xcb:-switch) ;xcb:-switch always finishes a struct
            (throw 'break 'nil)))))
    ;; If we specify a size, verify that it matches the actual size.
    (when-let* ((size-exp (slot-value obj '~size))
                (size (eval size-exp `((obj . ,obj)))))
      (unless (length= result size)
        (error "[XCB] Unexpected size for type %s: got %d, expected %d"
               (type-of obj)
               (length result)
               size)))
    result))

(cl-defmethod xcb:-marshal-field ((obj xcb:-struct) type value &optional pos)
  "Return the byte-array representation of a field in struct OBJ of type TYPE
and value VALUE.

The optional POS argument indicates current byte index of the field (used by
`xcb:-pad-align' type)."
  (pcase (or (get type 'xcb--typealias) type)
    (`xcb:-u1 (xcb:-pack-u1 value))
    (`xcb:-i1 (xcb:-pack-i1 value))
    (`xcb:-u2
     (if (slot-value obj '~lsb) (xcb:-pack-u2-lsb value) (xcb:-pack-u2 value)))
    (`xcb:-i2
     (if (slot-value obj '~lsb) (xcb:-pack-i2-lsb value) (xcb:-pack-i2 value)))
    (`xcb:-u4
     (if (slot-value obj '~lsb) (xcb:-pack-u4-lsb value) (xcb:-pack-u4 value)))
    (`xcb:-i4
     (if (slot-value obj '~lsb) (xcb:-pack-i4-lsb value) (xcb:-pack-i4 value)))
    (`xcb:-u8
     (if (slot-value obj '~lsb) (xcb:-pack-u8-lsb value) (xcb:-pack-u8 value)))
    (`xcb:-f32
     (let ((value (xcb:-f32-to-binary32 value)))
       (if (slot-value obj '~lsb) (xcb:-pack-u4-lsb value) (xcb:-pack-u4 value))))
    (`xcb:-f64
     (let ((value (xcb:-f64-to-binary64 value)))
       (if (slot-value obj '~lsb) (xcb:-pack-u8-lsb value) (xcb:-pack-u8 value))))
    (`xcb:void (vector value))
    (`xcb:-pad
     (unless (integerp value)
       (setq value (eval value `((obj . ,obj)))))
     (make-vector value 0))
    (`xcb:-pad-align
     ;; The length slot in xcb:-request is left out
     (let ((len (if (object-of-class-p obj 'xcb:-request) (+ pos 2) pos)))
       (when (vectorp value)
         ;; Alignment with offset.
         (setq len (- len (aref value 1))
               value (aref value 0)))
       (unless (integerp value)
         (setq value (eval value `((obj . ,obj)))))
       (make-vector (% (- value (% len value)) value) 0)))
    (`xcb:-list
     (let* ((list-name (plist-get value 'name))
            (list-type (plist-get value 'type))
            (list-size (plist-get value 'size))
            (data (slot-value obj list-name)))
       (unless (integerp list-size)
         (setq list-size (eval list-size `((obj . ,obj))))
         (unless list-size
           (setq list-size (length data)))) ;list-size can be nil
       (cl-assert (= list-size (length data)))
       ;; The data may be large, and if it's a string that's supposed
       ;; to be converted to a vector of bytes, then the transform can
       ;; be done trivially and much faster by just coercing.
       (if (and (eq list-type 'xcb:BYTE)
                (eq (type-of data) 'string))
           (cl-coerce data 'vector)
         (mapconcat (lambda (i) (xcb:-marshal-field obj list-type i))
                    data []))))
    (`xcb:-switch
     (let ((slots (eieio-class-slots (eieio-object-class obj)))
           (expression (plist-get value 'expression))
           (cases (plist-get value 'cases))
           result condition name-list flag slot-type)
       (unless (integerp expression)
         (setq expression (eval expression `((obj . ,obj)))))
       (cl-assert (integerp expression))
       (dolist (i cases)
         (setq condition (car i))
         (setq name-list (cdr i))
         (setq flag nil)
         (cl-assert (or (integerp condition) (listp condition)))
         (if (integerp condition)
             (setq flag (/= 0 (logand expression condition)))
           (if (eq 'logior (car condition))
               (setq flag (/= 0 (logand expression
                                        (apply #'logior (cdr condition)))))
             (setq flag (memq expression condition))))
         (when flag
           (dolist (name name-list)
             (catch 'break
               (dolist (slot slots) ;better way to find the slot type?
                 (when (eq name (eieio-slot-descriptor-name slot))
                   (setq slot-type (cl--slot-descriptor-type slot))
                   (throw 'break nil))))
             (unless (eq slot-type 'xcb:-ignore)
               (setq result
                     (vconcat result
                              (xcb:-marshal-field obj slot-type
                                                  (slot-value obj name)
                                                  (+ pos
                                                     (length result)))))))))
       result))
    ((guard (child-of-class-p type 'xcb:-struct))
     (xcb:marshal value))
    (x (error "[XCB] Unsupported type for marshalling: %s" x))))

(cl-defmethod xcb:unmarshal ((obj xcb:-struct) byte-array &optional ctx
                             total-length)
  "Fill in fields of struct OBJ according to its byte-array representation.

The optional argument CTX is for <paramref>."
  (unless total-length
    (setq total-length (length byte-array)))
  (let ((slots (eieio-class-slots (eieio-object-class obj)))
        (result 0)
        slot-name tmp type)
    (catch 'break
      (dolist (slot slots)
        (setq type (cl--slot-descriptor-type slot))
        (unless (eq type 'xcb:-ignore)
          (setq slot-name (eieio-slot-descriptor-name slot)
                tmp (xcb:-unmarshal-field obj type byte-array result
                                          (eieio-oref-default obj slot-name)
                                          ctx total-length))
          (setf (slot-value obj slot-name) (car tmp))
          (setq result (+ result (cadr tmp)))
          (when (eq type 'xcb:-switch) ;xcb:-switch always finishes a struct
            (throw 'break 'nil)))))
    ;; Let the struct compute it's size if a length field is specified. This lets us skip unknown
    ;; fields.
    (when-let* ((size-exp (slot-value obj '~size))
                (size (eval size-exp `((obj . ,obj)))))
      ;; Make sure the stated size is reasonable.
      (cond
       ((< size result)
        (error "[XCB] Object of type `%s' specified a size (%d) less than the number of bytes read (%d)"
               (type-of obj) size result))
       ((length< byte-array (- size result))
        (error "[XCB] Object of type `%s' specified a size (%d) greater than the size of the input (%d)"
               (type-of obj) size (+ result (length byte-array)))))
      ;; Skip any additional bytes.
      (setq result size))
    result))

(cl-defmethod xcb:-unmarshal-field ((obj xcb:-struct) type data offset
                                    initform &optional ctx total-length)
  "Return the value of a field in struct OBJ of type TYPE, byte-array
representation DATA, and default value INITFORM.

The optional argument CTX is for <paramref>.

This method returns a list of two components, with the first being the result
and the second the consumed length."
  (pcase (or (get type 'xcb--typealias) type)
    (`xcb:-u1 (list (aref data offset) 1))
    (`xcb:-i1 (let ((result (aref data offset)))
                (list (if (< result 128) result (- result 255)) 1)))
    (`xcb:-u2 (list (if (slot-value obj '~lsb)
                        (xcb:-unpack-u2-lsb data offset)
                      (xcb:-unpack-u2 data offset))
                    2))
    (`xcb:-i2 (list (if (slot-value obj '~lsb)
                        (xcb:-unpack-i2-lsb data offset)
                      (xcb:-unpack-i2 data offset))
                    2))
    (`xcb:-u4 (list (if (slot-value obj '~lsb)
                        (xcb:-unpack-u4-lsb data offset)
                      (xcb:-unpack-u4 data offset))
                    4))
    (`xcb:-i4 (list (if (slot-value obj '~lsb)
                        (xcb:-unpack-i4-lsb data offset)
                      (xcb:-unpack-i4 data offset))
                    4))
    (`xcb:-u8 (list (if (slot-value obj '~lsb)
                        (xcb:-unpack-u8-lsb data offset)
                      (xcb:-unpack-u8 data offset))
                    8))
    (`xcb:-f32 (list (xcb:-binary32-to-f32
                      (if (slot-value obj '~lsb)
                          (xcb:-unpack-u4-lsb data offset)
                        (xcb:-unpack-u4 data offset)))
                      4))
    (`xcb:-f64 (list (xcb:-binary64-to-f64
                      (if (slot-value obj '~lsb)
                          (xcb:-unpack-u8-lsb data offset)
                        (xcb:-unpack-u8 data offset)))
                      8))
    (`xcb:void (list (aref data offset) 1))
    (`xcb:-pad
     (unless (integerp initform)
       (when (eq 'quote (car initform))
         (setq initform (cadr initform)))
       (setq initform (eval initform `((obj . ,obj) (ctx . ,ctx)))))
     (list initform initform))
    (`xcb:-pad-align
     (let ((len (- total-length (- (length data) offset))))
       (if (vectorp initform)
           ;; Alignment with offset.
           (setq len (- len (aref initform 1))
                 initform (aref initform 0))
         (unless (integerp initform)
           (when (eq 'quote (car initform))
             (setq initform (cadr initform)))
           (setq initform (eval initform `((obj . ,obj) (ctx . ,ctx))))))
       (list initform (% (- initform (% len initform)) initform))))
    (`xcb:-list
     (when (eq 'quote (car initform))   ;unquote the form
       (setq initform (cadr initform)))
     (let ((list-name (plist-get initform 'name))
           (list-type (plist-get initform 'type))
           (list-size (plist-get initform 'size)))
       (unless (integerp list-size)
         (setq list-size (eval list-size `((obj . ,obj) (ctx . ,ctx)))))
       (cl-assert (integerp list-size))
       (pcase list-type
         (`xcb:char                     ;as Latin-1 encoded string
          (setf (slot-value obj list-name)
                (decode-coding-string
                 (apply #'unibyte-string
                        (append (substring data offset
                                           (+ offset list-size))
                                nil))
                 'iso-latin-1)))
         (`xcb:void                     ;for further unmarshalling
          (setf (slot-value obj list-name)
                (substring data offset (+ offset list-size))))
         (x
          (let ((count 0)
                result tmp)
            (dotimes (_ list-size)
              (setq tmp (xcb:-unmarshal-field obj x data (+ offset count) nil
                                              nil total-length))
              (setq result (nconc result (list (car tmp))))
              (setq count (+ count (cadr tmp))))
            (setf (slot-value obj list-name) result)
            (setq list-size count))))   ;to byte length
       (list initform list-size)))
    (`xcb:-switch
     (let ((slots (eieio-class-slots (eieio-object-class obj)))
           (expression (plist-get initform 'expression))
           (cases (plist-get initform 'cases))
           (count 0)
           condition name-list flag slot-type tmp)
       (unless (integerp expression)
         (setq expression (eval expression `((obj . ,obj) (ctx . ,ctx)))))
       (cl-assert (integerp expression))
       (dolist (i cases)
         (setq condition (car i))
         (setq name-list (cdr i))
         (setq flag nil)
         (cl-assert (or (integerp condition) (listp condition)))
         (if (integerp condition)
             (setq flag (/= 0 (logand expression condition)))
           (if (eq 'logior (car condition))
               (setq flag (/= 0 (logand expression
                                        (apply #'logior (cdr condition)))))
             (setq flag (memq expression condition))))
         (when flag
           (dolist (name name-list)
             (catch 'break
               (dolist (slot slots) ;better way to find the slot type?
                 (when (eq name (eieio-slot-descriptor-name slot))
                   (setq slot-type (cl--slot-descriptor-type slot))
                   (throw 'break nil))))
             (unless (eq slot-type 'xcb:-ignore)
               (setq tmp (xcb:-unmarshal-field obj slot-type data (+ offset count)
                                               (eieio-oref-default obj name)
                                               nil total-length))
               (setf (slot-value obj name) (car tmp))
               (setq count (+ count (cadr tmp)))))))
       (list initform count)))
    ((and x (guard (child-of-class-p x 'xcb:-struct)))
     (let* ((struct-obj (make-instance x))
            (tmp (xcb:unmarshal struct-obj (substring data offset) obj
                                total-length)))
       (list struct-obj tmp)))
    (x (error "[XCB] Unsupported type for unmarshalling: %s" x))))

;;;; Types derived directly from `xcb:-struct'

(defclass xcb:-request (xcb:-struct)
  nil
  :documentation "X request type.")

(defclass xcb:-reply (xcb:-struct)
  ((~reply :initform 1 :type xcb:-u1))
  :documentation "X reply type.")

(defclass xcb:-event (xcb:-struct)
  ((~code :type xcb:-u1))
  :documentation "Event type.")
;; Implemented in 'xcb.el'
(cl-defgeneric xcb:-error-or-event-class->number (obj class))
;;
(cl-defmethod xcb:marshal ((obj xcb:-event) connection &optional sequence)
  "Return the byte-array representation of event OBJ.

This method is mainly designed for `xcb:SendEvent', where it's used to
generate synthetic events.  The CONNECTION argument is used to retrieve
the event number of extensions.  If SEQUENCE is non-nil, it is used as
the sequence number of the synthetic event (if the event uses sequence
number); otherwise, 0 is assumed.

This method auto-pads short results to 32 bytes."
  (let ((event-number
         (xcb:-error-or-event-class->number connection
                                            (eieio-object-class obj)))
        result)
    (when (consp event-number)
      (setq event-number (cdr event-number))
      (if (= 1 (length event-number))
          ;; XKB event.
          (setf (slot-value obj 'xkbType) (aref event-number 0))
        ;; Generic event.
        (setf (slot-value obj 'extension) (aref event-number 0)
              (slot-value obj 'evtype) (aref event-number 1))))
    (when (slot-exists-p obj '~sequence)
      (setf (slot-value obj '~sequence) (or sequence 0)))
    (setq result (cl-call-next-method obj))
    (when (> 32 (length result))
      (setq result (vconcat result (make-vector (- 32 (length result)) 0))))
    result))

(defclass xcb:-generic-event (xcb:-event)
  ((~code :initform 35)
   (~extension :type xcb:CARD8)
   (~sequence :type xcb:CARD16)
   (~length :type xcb:CARD32)
   (~evtype :type xcb:CARD16))
  :documentation "Generic event type.")

(defclass xcb:-error (xcb:-struct)
  ((~error :initform 0 :type xcb:-u1)
   (~code :type xcb:-u1)
   (~sequence :type xcb:CARD16))
  :documentation "X error type.")

(defclass xcb:-union (xcb:-struct)
  ((~size :initarg :~size :type xcb:-ignore)) ;Size of the largest member.
  :documentation "Union type.")
;;
(cl-defmethod slot-unbound ((_object xcb:-union) _class _slot-name _fn)
  nil)
;;
(cl-defmethod xcb:marshal ((obj xcb:-union))
  "Return the byte-array representation of union OBJ.

This result is converted from the first bounded slot."
  (let ((slots (eieio-class-slots (eieio-object-class obj)))
        (size (slot-value obj '~size))
        result slot type name tmp)
    (while (and (not result) slots (> size (length result)))
      (setq slot (pop slots))
      (setq type (cl--slot-descriptor-type slot)
            name (eieio-slot-descriptor-name slot))
      (unless (or (not (slot-value obj name))
                  (eq type 'xcb:-ignore)
                  ;; Dealing with `xcb:-list' type
                  (and (eq type 'xcb:-list)
                       (not (slot-value obj (plist-get (slot-value obj name)
                                                       'name)))))
        (setq tmp (xcb:-marshal-field obj (cl--slot-descriptor-type slot)
                                      (slot-value obj name)))
        (when (> (length tmp) (length result))
          (setq result tmp))))
    (cond
     ((length< result size)
      (setq result (vconcat result (make-vector (- size (length result)) 0))))
     ((length> result size)
      (error "[XCB] Marshaled enum `%s' is larger than its declared size (%d > %d)"
             (type-of obj) (length result) size)))
    result))
;;
(cl-defmethod xcb:unmarshal ((obj xcb:-union) byte-array &optional ctx
                             total-length)
  "Fill in every field in union OBJ, according to BYTE-ARRAY.

The optional argument CTX is for <paramref>."
  (unless total-length
    (setq total-length (length byte-array)))
  (let ((slots (eieio-class-slots (eieio-object-class obj)))
        slot-name tmp type)
    (dolist (slot slots)
      (setq type (cl--slot-descriptor-type slot))
      (unless (eq type 'xcb:-ignore)
        (setq slot-name (eieio-slot-descriptor-name slot)
              tmp (xcb:-unmarshal-field obj type byte-array 0
                                        (eieio-oref-default obj slot-name)
                                        ctx total-length))
        (setf (slot-value obj (eieio-slot-descriptor-name slot)) (car tmp))))
    (slot-value obj '~size)))



(provide 'xcb-types)

;;; xcb-types.el ends here
