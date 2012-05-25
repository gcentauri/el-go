;;; sgf-gtp.el --- GTP backend for sgf-trans

;; Copyright (C) 2008 2012 Eric Schulte <eric.schulte@gmx.com>

;; Author: Eric Schulte <eric.schulte@gmx.com>
;; Created: 2012-05-15
;; Version: 0.1
;; Keywords: game go sgf gtp gnugo

;; This file is not (yet) part of GNU Emacs.
;; However, it is distributed under the same license.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;; Commentary:

;; This file should be useful for translating between sgf and the GO
;; text protocol (GTP) see http://www.lysator.liu.se/~gunnar/gtp/.
;; The GMP command set may be implemented as an extension.

;; Code:
(require 'sgf-util)
(require 'sgf-trans)

(defun sgf-gtp-char-to-num (char)
  (flet ((err () (error "sgf-gtp: invalid char %s" char)))
    (cond
     ((< char ?A)  (err))
     ((< char ?I)  (- char ?A))
     ((<= char ?T) (1- (- char ?A)))
     ((< char ?a)  (err))
     ((< char ?i)  (- char ?a))
     ((<= char ?t) (1- (- char ?a)))
     (t (err)))))

(defun sgf-gtp-num-to-char (num)
  (flet ((err () (error "sgf: invalid num %s" num)))
    (cond
     ((< num 1) (err))
     ((< num 9) (+ ?A (1- num)))
     (t         (+ ?A num)))))

(defun sgf-pos-to-gtp (pos)
  (format "%c%d" (num-to-char (1+ (car pos))) (1+ (cdr pos))))

(defun sgf-gtp-to-pos (color gtp)
  (cons color (cons :pos (cons (sgf-gtp-char-to-num (aref gtp 0))
                               (1- (parse-integer (substring gtp 1)))))))

(defun sgf-to-gtp-command (element)
  "Convert an sgf ELEMENT to a gtp command."
  (let ((key (car element))
	(val (cdr element)))
    (case key
      (:B       (format "black %s" (sgf-pos-to-gtp (aget (list val) :pos))))
      (:W       (format "white %s" (sgf-pos-to-gtp (aget (list val) :pos))))
      ((:SZ :S) (format "boardsize %s" val))
      (:KM      (format "komi %s" val))
      (t        nil))))


;;; Class and interface
(defclass gtp nil nil "Class for the GTP SGF GO back end.")

(defgeneric gtp-command (back-end command)
  "Send gtp COMMAND to OBJECT and return any output.")

(defmethod sgf->move ((gtp gtp) move)
  (gtp-command gtp (sgf-to-gtp-command move)))

(defmethod sgf<-size ((gtp gtp))
  (parse-integer (gtp-command gtp "query_boardsize")))

(defmethod sgf<-name ((gtp gtp))
  (gtp-command gtp "name"))

(defmethod sgf<-comment ((gtp gtp)) nil)

(defmethod sgf<-move ((gtp gtp) color)
  (sgf-gtp-to-pos color
                  (case color
                    (:B (gtp-command gtp "genmove_black"))
                    (:W (gtp-command gtp "genmove_white")))))

(defmethod sgf<-turn ((gtp gtp) color) (list (sgf<-move gtp color)))

(defmethod sgf->reset ((gtp gtp))
  (gtp-command gtp "clear_board"))

(provide 'sgf-gtp)
;;; sgf-gtp.el ends here
