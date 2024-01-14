;;; xelb-test.el --- Unit tests for XELB -*- lexical-binding: t -*-
;; Copyright (C) 2024 Free Software Foundation, Inc.

;; Author: Steven Allen <steven@stebalien.com>

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

;; This module contains unit tests for testing XELB.

;;; Code:

(require 'ert)
(require 'xcb-types)

;; https://en.wikipedia.org/wiki/Single-precision_floating-point_format#Notable_single-precision_cases
(defconst xelb-test-binary32-cases
  '((#x00000001 . 1.401298464324817e-45)
    (#x007fffff . 1.1754942106924411e-38)
    (#x00800000 . 1.1754943508222875e-38)
    (#x7f7fffff . 3.4028234663852886e38)
    (#x3f7fffff . 0.999999940395355225)
    (#x3f800000 . 1.0)
    (#x3f800001 . 1.00000011920928955)
    (#xc0000000 . -2.0)
    (#x00000000 . 0.0)
    (#x80000000 . -0.0)
    (#x7f800000 . 1e+INF)
    (#xff800000 . -1e+INF)
    (#x40490fdb . 3.14159274101257324)
    (#x3eaaaaab . 0.333333343267440796)))

;; https://en.wikipedia.org/wiki/Double-precision_floating-point_format#Double-precision_examples
(defconst xelb-test-binary64-cases
  `((#x3ff0000000000000 . 1.0)
    (#x3ff0000000000001 . 1.0000000000000002)
    (#x3ff0000000000002 . 1.0000000000000004)
    (#x4000000000000000 . 2.0)
    (#xc000000000000000 . -2.0)
    (#x4008000000000000 . 3.0)
    (#x4010000000000000 . 4.0)
    (#x4014000000000000 . 5.0)
    (#x4018000000000000 . 6.0)
    (#x4037000000000000 . 23.0)
    (#x3f88000000000000 . 0.01171875)
    (#x0000000000000001 . 4.9406564584124654e-324)
    (#x000fffffffffffff . 2.2250738585072009e-308)
    (#x0010000000000000 . 2.2250738585072014e-308)
    (#x7fefffffffffffff . 1.7976931348623157e308)
    (#x0000000000000000 . +0.0)
    (#x8000000000000000 . -0.0)
    (#x7ff0000000000000 . +1e+INF)
    (#xfff0000000000000 . -1e+INF)
    (#x3fd5555555555555 . ,(/ 1.0 3.0))
    (#x400921fb54442d18 . ,float-pi)))

(defun xelb-test--test-conversion (a-to-b b-to-a cases)
  "Test the bidirectional conversion functions A-TO-B and B-TO-A against CASES.
CASES is an alist of (A . B) pairs."
  (pcase-dolist (`(,a . ,b) cases)
    (let* ((act-a (funcall b-to-a b))
           (act-b (funcall a-to-b a))
           (round-trip-a (funcall b-to-a act-b))
           (round-trip-b (funcall a-to-b act-a)))
      (should (= b act-b round-trip-b))
      (should (= a act-a round-trip-a)))))

(ert-deftest xelb-test-binary32 ()
  (xelb-test--test-conversion
   #'xcb:-binary32-to-f32
   #'xcb:-f32-to-binary32
   xelb-test-binary32-cases))

(ert-deftest xelb-test-binary64 ()
  (xelb-test--test-conversion
   #'xcb:-binary64-to-f64
   #'xcb:-f64-to-binary64
   xelb-test-binary64-cases))

(provide 'xelb-test)

;;; xelb-test.el ends here
