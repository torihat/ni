;;; -*- Mode: Lisp; Package: EDITOR -*-
;;;
;;; This file is not part of xyzzy.
;;;
; $Id: setup.l 734 2006-09-05 01:49:02Z torihat $
;
; ni/setup.l
;
; by HATTORI Masashi

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "ni/defs")
  (require "ni/macro"))
(require "ni/lib")
(require "ni/log")
(require "ni/http")
(require "ni/site")
(require "ni/category")
(require "ni/apps")
(require "ni/install")
(require "ni/local")

(provide "ni/setup")

(in-package "netinst")

(defun init()
  (unless (file-exist-p *base-directory*)
    (create-directory *base-directory*))
  (unless (file-exist-p *data-directory*)
    (create-directory *data-directory*))
  (unless (file-exist-p *src-directory*)
    (create-directory *src-directory*))
  (unless (file-exist-p *log-directory*)
    (create-directory *log-directory*))
  (unless (file-exist-p *tmp-directory*)
    (create-directory *tmp-directory*))
  (log-init)
  (uninstall-app-clean)
  (load-install-data)
  (load-site-data)
  (run-hooks '*ni-init-hook*)
  )

(defun load-config ()
  (let ((lc (concat *config-file* "c")))
    (if (file-exist-p lc)
	(load lc)
      (when (file-exist-p *config-file*)
	(load *config-file*)))))

(defun frame-set ()
  (setq *pframe-old* (ed::pseudo-frame-name (selected-pseudo-frame)))
  (new-pseudo-frame *pframe-name*))

(defun frame-get ()
  (find-pseudo-frame *pframe-name*))

(defun hide ()
  (interactive)
  (let ((old (find-pseudo-frame *pframe-old*)))
    (when old
      (select-pseudo-frame old))))

(defun restore ()
  (interactive)
  (let ((frame (frame-get)))
    (if frame
	(progn
	  (select-pseudo-frame frame)
	  (when (and (not (string-match *buffer-prefix* (buffer-name (selected-buffer))))
		     (find-buffer *buffer-site*))
	    (site-window-only)))
      (user::setup))))

(defun finish ()
  (interactive)
  (let ((frame (frame-get)))
    (site-window-only)
    (save-site-data)
    (uninstall-app-clean)
    (log-close)
    (dolist (buf (buffer-list))
      (let ((bufname (buffer-name buf)))
	(when (string-match (concat "^" *buffer-prefix*) bufname)
	  (delete-buffer buf))))
    (when frame
      (delete-pseudo-frame frame)))
  (run-hooks '*ni-finish-hook*))

(defun user::ni-autoload ()
  (interactive)
  (unless (and (file-exist-p *autoload-directory*)
	       (file-directory-p *autoload-directory*))
    (return-from user::ni-autoload))
  (dolist (f (directory *autoload-directory*
			:wild "*.l"
			:absolute t
			:file-only t
			:recursive t))
    (let ((lc (concat f "c")))
      (if (file-exist-p lc)
	  (load lc)
	(load f)))))

(defun user::ni-toggle ()
  (interactive)
  (if (equal *pframe-name*
	     (ed::pseudo-frame-name (selected-pseudo-frame)))
      (hide)
    (restore)))

(defun user::netinstaller ()
  (interactive)
  (load-config)
  (when (frame-get)
    (restore)
    (return-from user::netinstaller))
  (frame-set)
  (init)
  (site-window-only)
  (site-mode)
  (site-print)
  (run-hooks '*ni-start-hook*)
  )
