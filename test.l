; $Id: test.l,v 1.1 2003/04/02 21:51:55 torihat Exp $
;
; test.l
;

(require "unit-test-modoki")

(setq *utm-test-dir*
      (merge-pathnames
       "site-lisp/ni/test"
       (si:system-root)))

(defun utm-test-files ()
  (directory *utm-test-dir*
	     :wild "*.l"
	     :absolute t))

(defun dotest ()
  (interactive)
  (let ((files (utm-test-files)))
    (utm-clear-test)
    (dolist (file files)
      (load file))
    (utm-run-test)
    ))
