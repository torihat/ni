;;; -*- Mode: Lisp; Package: EDITOR -*-
;;;
;;; This file is not part of xyzzy.
;;;
; $Id: log.l 734 2006-09-05 01:49:02Z torihat $
;
; ni/log.l
;
; by HATTORI Masashi

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "ni/defs")
  (require "ni/macro"))
(require "ni/lib")

(provide "ni/log")

(in-package "netinst")

(defun log-init ()
  (save-excursion
    (set-buffer (get-buffer-create *buffer-log*))
    (erase-buffer (selected-buffer))
    (setq need-not-save t)
    (setq *log-stream* (make-buffer-stream (selected-buffer)))
    (log-output "start at ~A" (format-date-string "%Y/%m/%d %H:%M:%S"))))

(defun log-filename ()
  (merge-pathnames (format nil "~A.log"
			   (format-date-string "%Y-%m-%d"))
		   *log-directory*))

(defun log-close ()
  (when (buffer-stream-p *log-stream*)
    (log-output "end at ~A" (format-date-string "%Y/%m/%d %H:%M:%S"))
    (close *log-stream*))
  (save-excursion
    (set-buffer (get-buffer-create *buffer-log*))
    (write-region (point-min)
		  (point-max)
		  (log-filename)
		  t)))

(defun log-output (fmt &rest args)
  (apply #'ni-message fmt args)
  (apply #'format *log-stream* (concat *prog-name* ": " fmt "~%") args))
