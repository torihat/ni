;;; -*- Mode: Lisp; Package: EDITOR -*-
;;;
;;; This file is not part of xyzzy.
;;;
; $Id: apps.l 734 2006-09-05 01:49:02Z torihat $
;
; ni/apps.l
;
; by HATTORI Masashi

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "ni/defs")
  (require "ni/macro"))
(require "ni/lib")

(provide "ni/apps")

(in-package "netinst")

(unless *apps-map*
  (setq *apps-map* (make-sparse-keymap))
  (define-key *apps-map* #\RET 'app-mark-toggle)
  (define-key *apps-map* #\U 'app-mark-updated)
  (define-key *apps-map* #\a 'app-mark-all)
  (define-key *apps-map* #\A 'app-unmark-all)
  (define-key *apps-map* #\i 'app-install-current)
  (define-key *apps-map* #\I 'app-install-marked)
  (define-key *apps-map* #\d 'app-uninstall-current)
  (define-key *apps-map* #\D 'app-uninstall-marked)
  (define-key *apps-map* #\SPC 'app-detail-open)
  (define-key *apps-map* #\n 'apps-show-next)
  (define-key *apps-map* #\p 'apps-show-prev)
  (define-key *apps-map* #\t 'apps-toggle)
  (define-key *apps-map* #\q 'apps-close)
)

(defun apps-open (apps)
  (interactive)
  (apps-show apps))

(defun apps-close ()
  (interactive)
  (set-window *window-site*)
  (delete-other-windows))

(defun apps-show (apps)
  (set-buffer-apps)
  (apps-mode)
  (apps-print apps)
  (run-hooks '*ni-apps-show-hook*))

(defvar *app-window-columns* 0)

(defun apps-show-next (&optional (lines 1))
  (interactive)
  (or (forward-line lines) (return-from apps-show-next))
  (app-detail-open))

(defun apps-show-prev ()
  (interactive)
  (apps-show-next -1))

(defun apps-mode ()
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
			  *window-flag-ruler* nil)
  (set-local-window-flags (selected-buffer)
			  *window-flag-just-inverse* t)
  (set-buffer-fold-width nil)
  (make-local-variable 'mode-line-format)
  (make-local-variable 'title-bar-format)
  (make-local-variable 'app-data)
  (apps-mode-line)
  (use-keymap *apps-map*)
  (run-hooks '*ni-apps-mode-hook*)
  )

(defun set-buffer-apps ()
  (set-buffer (get-buffer-create *buffer-apps*)))

(defun apps-mode-line ()
  (setq mode-line-format (format nil "%b"))
  (setq title-bar-format (format nil "%b")))

(defun apps-mode-line-update ()
  (save-excursion
    (set-buffer-apps)
    (apps-mode-line)))

(defun app-newer-p (a b)
  (> (app-time a)
     (app-time b)))

(defun apps-toggle ()
  (interactive)
  (apps-filter-toggle)
  (apps-print app-data))

(defun apps-filter-current-number ()
  (let ((num *apps-filter-none*)
	(all (length *apps-filter-func*)))
    (dotimes (i all)
      (let ((filter (assoc *apps-filter-current* *apps-filter-func*)))
	(when (eq *apps-filter-current* (car (nth i *apps-filter-func*)))
	  (setq num (car (nth (mod (1+ i) all) *apps-filter-func*)))
	  (return))))
    num))

(defun apps-filter-toggle ()
  (let ((num (apps-filter-current-number)))
    (setq *apps-filter-current* num)))

(defun apps-filter-installed (apps)
  (let (show-apps)
    (dolist (app apps)
      (when (app-installed-p app)
	(push app show-apps)))
    (nreverse show-apps)))

(defun apps-filter-not-installed (apps)
  (let (show-apps)
    (dolist (app apps)
      (unless (app-installed-p app)
	(push app show-apps)))
    (nreverse show-apps)))

(defun apps-filter-func (current)
  (cdr (assoc current *apps-filter-func*)))

(defun apps-filter (apps)
  (let ((func (apps-filter-func *apps-filter-current*)))
    (if (fboundp func)
	(funcall func apps)
      apps)))

(defun apps-print (apps)
  (let ((cur (current-line-number))
	(show-apps (apps-filter apps)))
    (app-cols-calc apps)
    (modify-read-only-buffer
     (erase-buffer (selected-buffer))
     (clear-all-text-attributes)
     ;(app-insert-head)
     (dolist (app show-apps)
       (apps-print-line app))
     (goto-line cur)
     (setq app-data apps)))
  (run-hooks '*ni-apps-print-hook*))

(defun app-cols-name (key)
  (cdr (assoc key *app-cols-name* :test #'equal)))

(defmacro app-cols-get (key)
  `(cdr (assoc ,key *app-cols* :test #'equal)))

(defmacro app-cols-set (key val)
  `(setf (app-cols-get ,key) ,val))

(defun app-cols-init ()
  (let ((tlen (string-length (format-date-string *app-time-fmt*))))
    (setq *app-cols*
	  (list (cons "name" (string-length (app-cols-name "name")))
		(cons "version" (string-length (app-cols-name "version")))
		(cons "time" tlen)
		(cons "current-time" tlen)
		(cons "current-version" (string-length (app-cols-name "current-version")))
		))
    ))

(defun app-cols-update (app)
  (let ((name (app-name app))
	(version (app-version app)))
    (when (< (app-cols-get "name")
	     (string-length name))
      (app-cols-set "name" (if *app-cols-name-max*
			       (min *app-cols-name-max* (string-length name))
			     (string-length name))))
    (when (< (app-cols-get "version")
	     (string-length version))
      (app-cols-set "version" (string-length version)))
    ))

(defun app-current-cols-update (app)
  (let ((version (app-version app)))
    (when (< (app-cols-get "current-version")
	     (string-length version))
      (app-cols-set "current-version" (string-length version)))
    ))

(defun app-cols-calc (apps)
  (app-cols-init)
  (dolist (app apps)
    (app-cols-update app))
  (dolist (app *install-data*)
    (app-current-cols-update app))
  )

(defun insert-in-col (str col)
  (let ((cur (current-column))
	(indent-tabs-mode nil))
    (declare (special indent-tabs-mode))
    (insert (abbreviate-string-column str col))
    (indent-to (+ cur col))))

(defun app-installed-p (app)
  (find-if #'(lambda (x)
	       (app-equal-p x app))
	   *install-data*))

(defun app-updated-p (cur new)
  (< (app-time cur)
     (app-time new)))

(defun app-state (app)
  (let ((cur (app-installed-p app)))
    (if cur
	(if (app-updated-p cur app)
	    *app-state-updated*
	  *app-state-installed*)
      *app-state-none*)))

(defun app-state-attribute (state)
  (cond ((eq state *app-state-none*)
	 nil)
	((eq state *app-state-installed*)
	 *attribute-app-installed*)
	((eq state *app-state-updated*)
	 *attribute-app-updated*)
	(t
	 nil)))

(defun app-equal-p (a b)
  (and (equal (app-name a)
	      (app-name b))
       (equal (app-site a)
	      (app-site b))))

(defun app-marked-p (app)
  (find-if #'(lambda (x)
	       (app-equal-p x app))
	   *app-mark-list*))

(defun app-mark-on (app)
  (unless (app-marked-p app)
    (push app *app-mark-list*)))

(defun app-mark-off (app)
  (when (app-marked-p app)
    (setq *app-mark-list* (remove-if #'(lambda (x)
					 (app-equal-p x app))
				     *app-mark-list*))))

(defun app-mark-clear ()
  (setq *app-mark-list* nil))

#|
(defun app-insert-head ()
  (insert "+---+---+")
  (insert "-" (app-cols-get "name"))
  (insert "+")
  (insert "-" (app-cols-get "version"))
  (insert "+")
  (insert "-" (app-cols-get "time"))
  (insert "+")
  (insert "-" (app-cols-get "current-version"))
  (insert "+")
  (insert "\n")
  )
|#

(defun apps-print-line (app)
  (let* ((cur (app-installed-p app))
	 (state (app-state app))
	 (attr (app-state-attribute state)))
    (insert "  ")
    (insert "[")
    (apply #'set-text-attribute
	   (point)
	   (progn
	     (insert (if (app-marked-p app)
			 *app-mark-char*
		       *app-nomark-char*))
	     (point))
	   'app-mark
	   *attribute-app-marked*)
    (insert "]")
    (insert (format nil "[~C]" state))
    (insert "  ")
    (apply #'set-text-attribute
	   (point)
	   (progn
	     (insert-in-col (app-name app)
			    (app-cols-get "name"))
	     (insert "  ")
	     (insert-in-col (app-version app)
			    (app-cols-get "version"))
	     (insert "  ")
	     (insert-in-col (format-date-string *app-time-fmt* (app-time app))
			    (app-cols-get "time"))
	     (point))
	   'app-newer
	   attr)
    (insert "  | ")
    (apply #'set-text-attribute
	   (point)
	   (progn
	     (insert-in-col (if cur
				(app-version cur)
			      "")
			    (app-cols-get "current-version"))
	     (insert "  ")
	     (insert-in-col (if cur
				(format-date-string *app-time-fmt* (app-time cur))
			      "")
			    (app-cols-get "current-time"))
	     (point))
	   'app-detail
	   (and cur *attribute-app-installed*))
    (insert "\n")
    ))

(defun apps-line-to-number (line-number)
  (- line-number 1))

(defun apps-number-to-line (pos)
  (+ pos 1))

(defun app-current ()
  (nth (apps-line-to-number (current-line-number)) (apps-filter app-data)))

(defun app-src-file (app)
  (merge-pathnames (app-file app) *src-directory*))

(defun app-mark-toggle ()
  (interactive)
  (let ((app (app-current)))
    (when app
      (if (app-marked-p app)
	  (app-mark-off app)
	(app-mark-on app))
      ;(msgbox "~{~S~%~}" *app-mark-list*)
      (apps-print app-data))))

(defun app-mark-all ()
  (interactive)
  (dolist (app app-data)
    (app-mark-on app))
  (apps-print app-data))

(defun app-unmark-all ()
  (interactive)
  (dolist (app app-data)
    (app-mark-off app))
  (apps-print app-data))

(defun app-mark-updated ()
  (interactive)
  (dolist (app app-data)
    (when (eq (app-state app) *app-state-updated*)
      (app-mark-on app)))
  (apps-print app-data))

(defun app-install-current ()
  (interactive)
  (let ((app (app-current)))
    (unless app
      (return-from app-install-current))
    (unless (yes-or-no-p "インストールしますか？: ~A"
			 (app-name app))
      (return-from app-install-current))
    (when (install-app app)
      (apps-print app-data)
      (ni-msgbox "インストール完了: ~A" (app-name app)))))

(defun app-uninstall-current ()
  (interactive)
  (let ((app (app-current)))
    (unless app
      (return-from app-uninstall-current))
    (unless (app-installed-p app)
      (ni-error "インストールされていません: ~A" (app-name app)))
    (unless (yes-or-no-p "アンインストールしますか？ : ~A"
			 (app-name app))
      (return-from app-uninstall-current))
    (when (uninstall-app app)
      (apps-print app-data)
      (ni-msgbox "アンインストール完了: ~A" (app-name app)))))

(defun app-select-line ()
  (reverse-region (progn (goto-bol) (point))
		  (+ (point) 2)))

(defun app-marked-apps ()
  (let (apps)
    (when *app-mark-list*
      (setq apps (mapcar #'(lambda(x)
			     (app-name x))
			 (reverse *app-mark-list*)))
      (format nil " ~A~{~% ~A~}" (car apps) (cdr apps)))))

(defun app-install-marked-check (&optional reverse)
  (let ((names (app-marked-apps)))
    (if names
	(yes-or-no-p "~Aインストールしますか~%~%~A"
		     (if reverse "アン" "")
		     names)
      nil)))

(defun app-uninstall-marked-check ()
  (app-install-marked-check t))

(defun app-install-marked ()
  (interactive)
  (let (installed
	not-installed
	(cnt 0))
    (unless *app-mark-list*
      (return-from app-install-marked))
    (unless (app-install-marked-check)
      (return-from app-install-marked))
    (save-excursion
      (dolist (app app-data)
	(when (app-marked-p app)
	  (goto-line (apps-number-to-line cnt))
	  (app-select-line)
	  (refresh-screen)
	  (if (install-app app)
	      (progn
		(push (app-name app) installed)
		(app-mark-off app))
	    (push (app-name app) not-installed)))
	(incf cnt)))
    (clear-reverse-region)
    (apps-print app-data)
    (when (or installed
	      not-installed)
      (let ((str ""))
	(when installed
	  (setq str (concat str
			    (format nil "インストール完了~%~%~{ ~A~%~}"
				    (reverse installed)))))
	(when not-installed
	  (setq str (concat str
			    (format nil "~%インストール未完了~%~%~{ ~A~%~}"
				    (reverse not-installed)))))
	(ni-msgbox str)))))

(defun app-uninstall-marked ()
  (interactive)
  (let (uninstalled
	not-uninstalled
	(cnt 0))
    (unless *app-mark-list*
      (return-from app-uninstall-marked))
    (unless (app-uninstall-marked-check)
      (return-from app-uninstall-marked))
    (save-excursion
      (dolist (app app-data)
	(when (app-marked-p app)
	  (goto-line (apps-number-to-line cnt))
	  (app-select-line)
	  (refresh-screen)
	  (if (uninstall-app app)
	      (progn
		(push (app-name app) uninstalled)
		(app-mark-off app))
	    (push (app-name app) not-uninstalled)))
	(incf cnt)))
    (clear-reverse-region)
    (apps-print app-data)
    (when (or uninstalled
	      not-uninstalled)
      (let ((str ""))
	(when uninstalled
	  (setq str (concat str
			    (format nil "アンインストール完了~%~%~{ ~A~%~}"
				    uninstalled))))
	(when not-uninstalled
	  (setq str (concat str
			    (format nil "~%アンインストール未完了~%~%~{ ~A~%~}"
				    not-uninstalled))))
	(ni-msgbox str)))))

(defun app-notice-show (app)
  (let ((notice (app-notice app)))
    (when (and (stringp notice)
	       (string-match "[^ \t\n　]" notice))
      (ni-msgbox "~A ~A~%~%~A"
		 (app-name app)
		 (app-version app)
		 notice))))

(unless *app-detail-map*
  (setq *app-detail-map* (make-sparse-keymap))
  (define-key *app-detail-map* #\RET 'app-detail-close)
  (define-key *app-detail-map* #\SPC 'app-detail-next-page-or-close)
  (define-key *app-detail-map* #\f 'app-detail-open-file)
  (define-key *app-detail-map* #\q 'app-detail-close)
  (define-key *app-detail-map* #\n 'app-detail-show-next)
  (define-key *app-detail-map* #\p 'app-detail-show-prev)
  )

(defun apps-window-split ()
  (apps-close)
  (window-split)
  (set-buffer-apps)
  (refresh-screen)
  (setq *app-window-columns* (window-columns))
  ;(split-window *apps-window-height*)
  (split-window (if (< (1- (window-height)) *app-detail-window-height*)
		    (floor (/ (window-height) 2))
		  (- (window-height) *app-detail-window-height*)))
  (other-window 1))

(defun app-detail-open ()
  (interactive)
  (let ((app (app-current)))
    (when app
      (app-select-line)
      (apps-window-split)
      (app-detail-show app))))

(defun app-detail-show (app)
  (set-buffer-app-detail)
  (app-detail-mode)
  (modify-read-only-buffer
   (app-detail-print app))
  (run-hooks '*ni-app-detail-show-hook*))

(defun app-detail-close ()
  (interactive)
  (apps-close)
  (window-split)
  (set-buffer-apps)
  (clear-reverse-region))

(defun app-detail-next-page-or-close ()
  (interactive)
  (if (pos-visible-in-window-p (point-max))
      (app-detail-close)
    (next-page)))

(defun app-detail-mode ()
  (clear-reverse-region)
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
			  *window-flag-ruler* nil)
  (set-local-window-flags (selected-buffer)
			  *window-flag-just-inverse* t)
  (set-buffer-fold-width nil)
  (make-local-variable 'mode-line-format)
  (make-local-variable 'title-bar-format)
  (app-detail-mode-line)
  (use-keymap *app-detail-map*)
  (run-hooks '*ni-app-detail-mode-hook*)
  )

(defun set-buffer-app-detail ()
  (set-buffer (get-buffer-create *buffer-app-detail*)))

(defun app-detail-mode-line ()
  (setq mode-line-format (format nil "%b"))
  (setq title-bar-format (format nil "%b")))

(defun app-detail-mode-line-update ()
  (save-excursion
    (set-buffer-app-detail)
    (app-detail-mode-line)))

(defvar *app-detail-show-list*
  '(("name"        . "名称      ")
    ("version"     . "バージョン")
    ("site"        . "サイト名  ")
    ("author"      . "作者      ")
    ("src"         . "置場所    ")
    ("time"        . "更新日時  ")
    ("md5"         . "md5sum    ")
    ("category"    . "カテゴリー")
    ("depends"     . "依存      ")
    ("description" . "説明      ")
    ("changes"     . "変更点    ")
    ("notice"      . "注意      ")
    ))

(defun app-detail-print (app)
  (erase-buffer (selected-buffer))
  (dolist (tmp *app-detail-show-list*)
    (let ((key (car tmp))
	  (val (cdr tmp)))
      (insert (format nil "~A: ~A~%"
		      val
		      (cond ((equal key "time")
			     (format-date-string *app-time-fmt* (app-value key app)))
			    ((or (equal key "depends")
				 (equal key "category"))
			     (or (string-join (app-value key app)) " "))
			    ((or (equal key "description")
				 (equal key "changes")
				 (equal key "notice"))
			     (if (app-value key app)
				 (let ((lines (split-string (app-value key app) "\n" t))
				       (len (+ 2 (string-length val))))
				   (if lines
				       (string-join lines (concat "\n" (format nil "~VA" len " ")))
				     ""))
			       ""))
			    (t
			     (app-value key app)))))))
  (when (app-installed-p app)
    (let ((files (read-installed-files app)))
      (when files
	(app-horizontal-line)
	(insert *app-detail-installed-file-title*)
	(insert "\n")
	(dolist (file files)
	  (let ((path (install-path file)))
	    (unless (file-directory-p path)
	      (insert (format nil " ~A~%" file))))))))
  (goto-char (point-min)))

(defun app-horizontal-line ()
  ;(refresh-screen)
  ;(insert "-" (window-columns))
  (insert "-" *app-window-columns*)
  (insert "\n"))

(defun app-detail-show-next ()
  (interactive)
  (app-detail-close)
  (apps-show-next))

(defun app-detail-show-prev ()
  (interactive)
  (app-detail-close)
  (apps-show-prev))

(defvar *app-detail-installed-file-title*
  "インストール済みファイル")

(defun app-detail-open-file ()
  (interactive)
  (let ((pos (point))
	file
	path)
    (goto-bol)
    (unless (scan-buffer *app-detail-installed-file-title*
			 :reverse t)
      (return-from app-detail-open-file))
    (goto-char pos)
    (goto-bol)
    (unless (looking-at " *\\([^\n]+\\)$")
      (return-from app-detail-open-file))
    (setq file (match-string 1))
    (setq path (install-path file))
    (unless (file-exist-p path)
      (ni-error "File does not exist: ~A" path))
    (find-file path)
    (app-detail-view-mode)))

(defun app-detail-view-mode ()
  (kill-all-local-variables)
  (set-local-window-flags (selected-buffer)
			  *window-flag-line-number* nil)
  (set-local-window-flags (selected-buffer)
			  *window-flag-newline* nil)
  (set-local-window-flags (selected-buffer)
			  *window-flag-eof* nil)
  (set-local-window-flags (selected-buffer)
			  *window-flag-ruler* nil)
  (set-local-window-flags (selected-buffer)
			  *window-flag-just-inverse* t)
  (use-keymap *app-detail-view-map*)
  (setq buffer-mode 'app-detail-view-mode)
  (setq mode-name "NetInstaller: View")
  (setq buffer-read-only t)
  (run-hooks '*ni-app-detail-view-mode-hook*)
  )

(unless *app-detail-view-map*
  (setq *app-detail-view-map* (make-sparse-keymap))
  (define-key *app-detail-view-map* #\RET 'app-detail-view-close)
  (define-key *app-detail-view-map* #\SPC 'next-page)
  (define-key *app-detail-view-map* #\C-h 'previous-page)
  (define-key *app-detail-view-map* #\q 'app-detail-view-close)
  )

(defun app-detail-view-close ()
  (interactive)
  (delete-buffer (selected-buffer))
  (set-buffer-app-detail))
