;;; -*- Mode: Lisp; Package: EDITOR -*-
;;;
;;; This file is not part of xyzzy.
;;;
; $Id: install.l 734 2006-09-05 01:49:02Z torihat $
;
; ni/install.l
;
; by HATTORI Masashi

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "ni/defs")
  (require "ni/macro"))
(require "ni/lib")
(require "ni/apps")

(provide "ni/install")

(in-package "netinst")

(defun install-path (file)
  (merge-pathnames file *install-directory*))

(defun load-install-data ()
  (unless *install-data*
    (when (file-exist-p *install-data-file*)
      (setq *install-data*
	    (data-read-from-file *install-data-file*)))))

(defun save-install-data ()
  (data-write-to-file *install-data-file* *install-data*))

(defun read-installed-files (app)
  (let ((file (app-file-installed app)))
    (when (file-exist-p file)
      (data-read-from-file file))))

(defun write-installed-files (app files)
  (let ((file (app-file-installed app)))
    (data-write-to-file file files)))

(defun modify-installed-site-name (old new)
  (let ((old-name (site-name old))
	(new-name (site-name new))
	(updated nil))
    (dolist (app *install-data*)
      (when (equal old-name (app-site app))
	(setf (app-site app) new-name)
	(setq updated t)))
    (when updated
      (save-install-data))))

(defun add-installed-files (files)
  (app-add-installed-files *app-current* files))

(defun app-add-installed-files (app files)
  (let ((olds (read-installed-files app)))
    (dolist (file files)
      (unless (member file olds :test #'equalp)
	(setq olds (append olds (list file)))))
    (write-installed-files app olds)))

(defun delete-installed-file (app)
  (let ((file (app-file-installed app)))
    (delete-file file :if-does-not-exist :skip)))

(defun app-file-installed (app)
  (merge-pathnames (format nil "~A.files" (app-name app))
		   *src-directory*))

(defun install-app-do (app)
  (let ((cur (app-installed-p app))
	cur-files)
    (log-output "going to install ~A" (app-name app))
    (setq *app-current* app)
    (when cur
      (setq cur-files (read-installed-files cur))
      (uninstall-app cur t))
    (unless (install-overwrite-check app)
      (when cur
	(uninstall-app-restore cur))
      (return-from install-app-do (values nil "中止されました。")))
    (handler-case
	(install-app-extract app)
      (error (c)
	(when cur
	  (uninstall-app-restore cur))
	(return-from install-app-do (values nil (si:*condition-string c))))
      (quit (c)
	(when cur
	  (uninstall-app-restore cur))
	(return-from install-app-do (values nil (si:*condition-string c)))))
    (install-register app)
    (save-install-data)
    (when cur
      (uninstall-app-preserve-delete cur))
    (load-after-install app)
    (log-output "install ~A completed." (app-name app))
    t))

(defun load-app-file (path)
  (handler-case
      (load path)
    (error (c)
      (ni-msgbox "~S" (si:*condition-string c)))
    (quit (c)
      (ni-msgbox "~S" (si:*condition-string c)))))

(defun load-after-install (app)
  (let ((file (app-load-after-install app))
	path)
    (when (and (stringp file)
	       (not (equal file ""))
	       (setq path (merge-pathnames file (si:system-root)))
	       (file-exist-p path))
      (load-app-file path))))

(defun load-before-uninstall (app)
  (let ((file (app-load-before-uninstall app))
	path)
    (when (and (stringp file)
	       (not (equal file ""))
	       (setq path (merge-pathnames file (si:system-root)))
	       (file-exist-p path))
      (load-app-file path))))

(defun install-register (app)
  (let ((files (install-src-files app)))
    (log-output "register ~S" app)
    (write-installed-files app files)
    (push app *install-data*)))

(defun install-unregister (app)
  (log-output "unregister ~S" app)
  (delete-installed-file app)
  (setq *install-data* (remove-if #'(lambda (x)
				      (app-equal-p x app))
				  *install-data*)))

(defun uninstall-app (app &optional preserve)
  (let ((files (read-installed-files app)))
    (setq *install-status* (if preserve
			       *install-status-update*
			     *install-status-uninstall*))
    (load-before-uninstall app)
    (when preserve
      (uninstall-app-preserve app files))
    (log-output "deleting installed files ~S" app)
    (mapc #'(lambda (x)
	      (let ((path (install-path x)))
		(unless (file-directory-p path)
		  (delete-file path
			       :if-does-not-exist :skip
			       :if-access-denied :skip)))
	      (log-output "delete ~A" x))
	  files)
    (install-unregister app)
    (save-install-data)
    (setq *install-status* *install-status-none*)
    t))

(defun uninstall-app-restore (app)
  (let ((path (uninstall-preserve-file app)))
    (if (file-exist-p path)
	(progn
	  (log-output "restore preserved files: ~A" path)
	  (extract-archive path *install-directory*))
      (progn
	(log-output "preserved archive does not exist: ~A" path)
	(ni-msgbox "一時保存ファイルがありません: ~A" path)))))

(defun uninstall-app-clean ()
  (when (and (file-exist-p *tmp-directory*)
	     (file-directory-p *tmp-directory*))
    (dolist (file (directory *tmp-directory*
			     :absolute t
			     :file-only t))
      (log-output "clean up preserved file: ~A" file)
      (delete-file file :if-access-denied :skip))))

(defun uninstall-preserve-file (app)
  (merge-pathnames (app-file app) *tmp-directory*))

(defun uninstall-app-preserve (app files)
  (let ((path (uninstall-preserve-file app))
	(pfiles))
    (uninstall-app-preserve-delete app)
    (mapc #'(lambda (x)
	      (let ((f (install-path x)))
		(when (and (file-exist-p f)
			   (not (file-directory-p f)))
		  (push f pfiles))))
	  files)
    (log-output "create preserve archive: ~A ~S" path (reverse pfiles))
    (create-archive path (reverse pfiles) *install-directory*)))

(defun uninstall-app-preserve-delete (app)
  (let ((path (uninstall-preserve-file app)))
    (when (file-exist-p path)
      (log-output "delete preserved file: ~A" path)
      (unless (delete-file path :if-access-denied :skip)
	(ni-error "一時保存ファイルを削除することができません: ~A" path)))))

(defun install-app-extract (app)
  (let ((file (app-src-file app)))
    (log-output "extract install files from ~S" file)
    (extract-archive file *install-directory*)))

(defun install-src-files (app)
  (let ((file (app-src-file app)))
    (when (file-exist-p file)
      (log-output "listup files in ~A" file)
      (mapcar #'car (list-archive file)))))

(defun install-overwrite-check (app)
  (let (files
	exists)
    (handler-case
	(setq files (install-src-files app))
      (error (c)
	(ni-msgbox "エラーが発生しました: ~A" (si:*condition-string c))
	(return-from install-overwrite-check nil))
      (quit (c)
	(return-from install-overwrite-check nil)))
    (dolist (f files)
      (let ((path (install-path f)))
	(when (and (file-exist-p path)
		   (not (file-directory-p path)))
	  (push path exists))))
    (if exists
	(yes-or-no-p "以下のファイルが上書きされます。続行しますか？~%~%~{ ~A~%~}" (reverse exists))
      t)))

(defun install-app-fetch (app)
  (let ((src (app-src app))
	(file (app-src-file app)))
    (log-output "going to fetch ~A" src)
    (when (app-src-md5sum-check app)
      (return-from install-app-fetch t))
    (cond ((url-http-p src)
	   (http-get-to-file src file))
	  ((url-local-p src)
	   (unless (not (path-equal src file))
	     (copy-file src file :if-exists :overwrite)))
	  (t
	   (ni-error "取得できません: ~S" src)))
    (if (app-src-md5sum-check app)
	t
      (progn
	(ni-msgbox "md5sumが一致しません")
	nil))))

(defun app-src-md5sum-check (app)
  (let ((file (app-src-file app))
	(md5 (app-md5 app)))
    (unless (file-exist-p file)
      (return-from app-src-md5sum-check))
    (equal md5 (md5sum file))))

(defun install-app (app)
  (unless (install-app-fetch app)
    (return-from install-app))
  (multiple-value-bind (res msg)
      (install-app-do app)
    (if res
	(progn
	  (app-notice-show app)
	  t)
      (progn
	(when msg
	  (ni-msgbox msg))
	(log-output "install ~A not completed: ~S" (app-name app) msg)
	nil))))
