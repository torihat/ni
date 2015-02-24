;;; -*- Mode: Lisp; Package: EDITOR -*-
;;;
;;; This file is not part of xyzzy.
;;;
; $Id: makefile.l 734 2006-09-05 01:49:02Z torihat $
;
; ni/makefile.l
;
; by HATTORI Masashi

(provide "ni/makefile")

(defvar *make-file-list* '("setup.l"
			   "defs.l"
			   "http.l"
			   "macro.l"
			   "lib.l"
			   "site.l"
			   "apps.l"
			   "log.l"
			   "local.l"
			   "install.l"
			   "category.l"
			   ))

(defvar *make-root-directory*
  (merge-pathnames "site-lisp/ni" (si:system-root)))

(defvar *make-buffer-make* "*NetInstall: MAKE")

(defun ni-make ()
  (interactive)
  (let ((files *make-file-list*)
	(path *make-root-directory*))
    (dolist (f files)
      (let ((file (merge-pathnames f path))
	    (filec))
	(setq filec (concat file "c"))
	(if (file-newer-than-file-p file filec)
	    (byte-compile-file file)
	  (message "skipping file: ~A" file))))))

(defun ni-make-tags-file ()
  (interactive)
  (let ((old (default-directory))
	(path *make-root-directory*))
    (set-default-directory path)
    (make-tags-file path 0)
    (set-default-directory old)))

(defun ni-make-all ()
  (interactive)
  (ni-make)
  (ni-make-tags-file))

(defun ni-make-clean ()
  (interactive)
  (let ((path *make-root-directory*))
    (dolist (f (directory path
			  :absolute t
			  :recursive t))
      (when (or (string-match "~$" f)
		(string-match "\.lc" f)
		(string-matchp "xtags" f))
	(delete-file f)
	(message "File deleted: ~A" f)))))
