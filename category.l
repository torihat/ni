;;; -*- Mode: Lisp; Package: EDITOR -*-
;;;
;;; This file is not part of xyzzy.
;;;
; $Id: category.l 734 2006-09-05 01:49:02Z torihat $
;
; ni/category.l
;
; by HATTORI Masashi

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "ni/defs")
  (require "ni/macro"))
(require "ni/lib")
(require "ni/local")
(require "ni/apps")

(provide "ni/category")

(in-package "netinst")

(unless *category-map*
  (setq *category-map* (make-sparse-keymap))
  (define-key *category-map* #\RET 'category-apps-open)
  (define-key *category-map* #\SPC 'category-apps-open)
  (define-key *category-map* #\Right 'category-apps-open)
  (define-key *category-map* #\q 'category-close)
  )

(defun category-mode ()
  (setq need-not-save t)
  (setq buffer-read-only t)
  (setq kept-undo-information nil)
  (setq auto-save nil)
  (set-local-window-flags (selected-buffer)
			  *window-flag-line-number* nil)
  (set-local-window-flags (selected-buffer)
			  *window-flag-newline* nil)
  (set-local-window-flags (selected-buffer)
			  *window-flag-eof* nil)
  (set-local-window-flags (selected-buffer)
			  *window-flag-cursor-line* t)
  (set-local-window-flags (selected-buffer)
			  *window-flag-vscroll-bar* nil)
  (set-local-window-flags (selected-buffer)
			  *window-flag-ruler* nil)
  (set-local-window-flags (selected-buffer)
			  *window-flag-just-inverse* t)
  (set-buffer-fold-width nil)
  (make-local-variable 'mode-line-format)
  (make-local-variable 'title-bar-format)
  (category-mode-line-update)
  (use-keymap *category-map*)
  (run-hooks '*ni-category-mode-hook*)
  )

(defun category-window-split ()
  (category-window-only)
  (split-window-vertically *site-window-width*)
  (setq *window-site* (selected-window))
  (other-window 1)
  (setq *window-apps* (selected-window))
  )

(defun category-window-only ()
  (interactive)
  (set-buffer-category)
  (delete-other-windows))

(defun category-close ()
  (interactive)
  (set-buffer-site))

(defun category-show ()
  (interactive)
  (set-buffer-category)
  (category-mode)
  (category-print))

(defun set-buffer-category ()
  (set-buffer (get-buffer-create *buffer-category*)))

(defun category-mode-line-update ()
  (save-excursion
    (set-buffer-category)
    (site-mode-line)))

(defun category-print ()
  (modify-read-only-buffer
   (erase-buffer (selected-buffer))
   (clear-all-text-attributes)
   (apply #'set-text-attribute
	  (point)
	  (progn
	    (insert "Categories\n")
	    (point))
	  'category
	  *attribute-category-all*)
   (dolist (c *category-data*)
     (let ((name (category-data-name c))
	   (apps (category-data-apps c)))
       (apply #'set-text-attribute
	      (point)
	      (progn
		(insert (format nil " ~A (~D)~%" name (length apps)))
		(point))
	      'category
	      *attribute-category*)))
   (goto-char (point-min)))
  (run-hooks '*ni-category-print-hook*))

(defvar *category-line-diff* 2)

(defun category-line-to-number (line-number)
  (- line-number *category-line-diff*))

(defun category-number-to-line (pos)
  (+ pos *category-line-diff*))

(defun category-current ()
  (let ((num (current-line-number)))
    (cond ((< 1 num)
	   (nth (category-line-to-number num) *category-data*))
	  (t
	   nil))))

(defun category-apps-open ()
  (interactive)
  (let* ((category (category-current))
	 (apps (if category
		   (apps-of-category category)
		 *app-data*)))
    (category-window-split)
    (apps-open apps)
    (goto-line 1))
  (run-hooks '*ni-category-apps-open-hook*))

(defun category-apps (category)
  (category-data-apps (assoc category *category-data* :test #'equal)))

(defun apps-of-category (category)
  (sort (category-data-apps category)
	#'app-newer-p))

(defun category-apps-list (category)
  (let (apps)
    (mapc #'(lambda (x)
	      (when (member category (app-category x) :test #'equal)
		(push x apps)))
	  *app-data*)
    (nreverse apps)))

(defun category-parse ()
  (let (data)
    (dolist (c *category-list*)
      (push (cons c (category-apps-list c)) data))
    (setq *category-data* (nreverse data))))
