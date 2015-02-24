;;; -*- Mode: Lisp; Package: EDITOR -*-
;;;
;;; This file is not part of xyzzy.
;;;
; $Id: defs.l 752 2007-11-20 12:40:08Z torihat $
;
; ni/defs.l
;
; by HATTORI Masashi

(defpackage "netinst"
  (:use "lisp" "editor")
  (:nicknames "ni"))

(provide "ni/defs")

(in-package "netinst")

(defvar *version* "0.0.1.1-5")
(defvar *prog-name* "NetInstaller")
(defvar *pframe-name* "NetInst")

(defvar *buffer-prefix*
  (format nil "*~A " *prog-name*))

(defvar *buffer-site*
  (concat *buffer-prefix* "Site*"))
(defvar *buffer-apps*
  (concat *buffer-prefix* "Apps*"))
(defvar *buffer-app-detail*
  (concat *buffer-prefix* "Detail*"))
(defvar *buffer-temp*
  (concat *buffer-prefix* "Temp*"))
(defvar *buffer-log*
  (concat *buffer-prefix* "Log*"))
(defvar *buffer-category*
  (concat *buffer-prefix* "Category*"))

(defvar *log-stream* nil)

(defvar *window-site* nil)
(defvar *window-apps* nil)

(defvar *site-window-width* 20)
(defvar *app-detail-window-height* 20)

(defvar *base-directory*
  (merge-pathnames ".netinst" (si:system-root)))

(defvar *install-directory* (si:system-root))

(defconstant *install-status-none*      0)
(defconstant *install-status-install*   1)
(defconstant *install-status-update*    2)
(defconstant *install-status-uninstall* 3)

(defvar *install-status* 0)

(defvar *src-directory*
  (merge-pathnames "src" *base-directory*))
(defvar *data-directory*
  (merge-pathnames "dat" *base-directory*))
(defvar *log-directory*
  (merge-pathnames "log" *base-directory*))
(defvar *tmp-directory*
  (merge-pathnames "tmp" *base-directory*))

(defvar *autoload-directory*
  (merge-pathnames "site-lisp/ni-autoload" (si:system-root)))

(defvar *config-file*
  (merge-pathnames "config.l" *base-directory*))

(defvar *install-data-file*
  (merge-pathnames "installed.l" *base-directory*))
(defvar *install-site-file*
  (merge-pathnames "sites.l" *base-directory*))

(defvar *local-data-file*
  (merge-pathnames "packages.l" *base-directory*))

(defvar *site-data* nil)
(defvar *app-data* nil)
(defvar *install-data* nil)
(defvar *local-data* nil)
(defvar *app-current* nil)

(defvar *http-recv-vector-size* 2048)
(defvar *http-version* "1.0")
(defvar *http-port* 80)
(defvar *http-accept-language* "ja,en")

(defvar *http-user-agent*
  (format nil "~A for xyzzy Ver-~A" *prog-name* *version*))

(defvar *http-show-status-message* t)

(defvar *http-proxy-host* nil)          ; PROXY のホスト
(defvar *http-proxy-port* nil)          ; PROXY のポート
(defvar *http-direct-connect-list* nil) ; PROXY を経由しないホストのリスト
(defvar *http-proxy-user* nil)
(defvar *http-proxy-pass* nil)

(defvar *app-cols* nil)
(defvar *app-cols-name* '(("name" . "Name")
			  ("version" . "Version")
			  ("time" . "Time")
			  ("current-version" . "Current")
			  ("current-time" . "Time")
			  ))

(defvar *app-time-fmt* "%Y/%m/%d %H:%M")

(defvar *app-state-none* #\SPC)
(defvar *app-state-installed* #\I)
(defvar *app-state-updated* #\U)

(defvar *app-mark-char* "*")
(defvar *app-nomark-char* " ")

(defvar *attribute-site* nil)
(defvar *attribute-site-all* nil)

(defvar *attribute-app-marked* '(:foreground 1))
(defvar *attribute-app-installed* '(:foreground 10))
(defvar *attribute-app-updated* '(:foreground 13))

(defvar *attribute-category-all* nil)
(defvar *attribute-category* nil)

(defvar *app-mark-list* nil)

(defvar *site-map* nil)
(defvar *apps-map* nil)
(defvar *app-detail-map* nil)
(defvar *app-detail-view-map* nil)
(defvar *category-map* nil)

(defvar *ni-init-hook* nil)
(defvar *ni-start-hook* nil)
(defvar *ni-finish-hook* nil)
(defvar *ni-site-mode-hook* nil)
(defvar *ni-site-print-hook* nil)
(defvar *ni-site-apps-open-hook* nil)
(defvar *ni-apps-mode-hook* nil)
(defvar *ni-apps-show-hook* nil)
(defvar *ni-apps-print-hook* nil)
(defvar *ni-app-detail-mode-hook* nil)
(defvar *ni-app-detail-show-hook* nil)
(defvar *ni-app-detail-view-mode-hook* nil)
(defvar *ni-category-mode-hook* nil)
(defvar *ni-category-print-hook* nil)
(defvar *ni-category-apps-open-hook* nil)

(defvar *site-clipboard* nil)

(defvar *apps-filter-none* 0)
(defvar *apps-filter-installed* 1)
(defvar *apps-filter-not-installed* 2)
(defvar *apps-filter-func* (list (cons *apps-filter-none* nil)
				 (cons *apps-filter-installed* 'apps-filter-installed)
				 (cons *apps-filter-not-installed* 'apps-filter-not-installed)))
(defvar *apps-filter-current* *apps-filter-none*)

(defvar *app-cols-name-max* nil)

(defvar *category-list* nil)
(defvar *category-data* nil)

(setq *category-list* '("Administration"
			"Development"
			"Documentation"
			"Editing"
			"File Systems"
			"Formatting"
			"Games"
			"Graphics/Sound"
			"Libraries"
			"Lisp"
			"Miscellaneous"
			"Network"
			"Resource"
			"Shells"
			"TeX"
			"Text Processing"
			"Utilities"
			))
