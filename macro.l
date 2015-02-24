;;; -*- Mode: Lisp; Package: EDITOR -*-
;;;
;;; This file is not part of xyzzy.
;;;
; $Id: macro.l 734 2006-09-05 01:49:02Z torihat $
;
; ni/macro.l
;
; by HATTORI Masashi

(require "ni/defs")

(provide "ni/macro")

(in-package "netinst")

(defmacro site-value (key site)
  `(cdr (assoc ,key ,site :test #'equal)))

(defmacro site-name (site)
  `(site-value "name" ,site))
(defmacro site-author (site)
  `(site-value "author" ,site))
(defmacro site-src (site)
  `(site-value "src" ,site))
(defmacro site-url (site)
  `(site-value "url" ,site))
(defmacro site-description (site)
  `(site-value "description" ,site))
(defmacro site-apps (site)
  `(site-value "packages" ,site))

(defmacro app-value (key app)
  `(cdr (assoc ,key ,app :test #'equal)))

(defmacro app-name (app)
  `(app-value "name" ,app))
(defmacro app-version (app)
  `(app-value "version" ,app))
(defmacro app-description (app)
  `(app-value "description" ,app))
(defmacro app-file (app)
  `(app-value "file" ,app))
(defmacro app-src (app)
  `(app-value "src" ,app))
(defmacro app-md5 (app)
  `(app-value "md5" ,app))
(defmacro app-time (app)
  `(app-value "time" ,app))
(defmacro app-site (app)
  `(app-value "site" ,app))
(defmacro app-author (app)
  `(app-value "author" ,app))
(defmacro app-depends (app)
  `(app-value "depends" ,app))
(defmacro app-changes (app)
  `(app-value "changes" ,app))
(defmacro app-notice (app)
  `(app-value "notice" ,app))
(defmacro app-load-after-install (app)
  `(app-value "load-after-install" ,app))
(defmacro app-load-before-uninstall (app)
  `(app-value "load-before-uninstall" ,app))
(defmacro app-category (app)
  `(app-value "category" ,app))

(defmacro category-data-name (c)
  `(car ,c))
(defmacro category-data-apps (c)
  `(cdr ,c))

(defmacro modify-read-only-buffer (&body body)
  `(let ((buffer-read-only nil))
     (declare (special buffer-read-only))
     ,@body))

(setf (get 'modify-read-only-buffer 'lisp-indent-hook) 1)
