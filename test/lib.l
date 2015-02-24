; $Id: lib.l,v 1.1 2003/04/02 21:52:45 torihat Exp $
;
; test-lib.l
;

(require "ni/lib")

(in-package "ni")

(defun test-md5sum ()
  (utm-assert-equal "7509834b50e75915aab28038c7a1903a"
		    (md5sum (merge-pathnames "site-lisp/ni/test/lib-md5sum.dat"
					     (si:system-root)))))

(utm-add-test 'test-md5sum)

(defun test-url-http-p ()
  (utm-assert (url-http-p "http://www.yahoo.co.jp/"))
  (utm-assert (not (url-http-p "C:/xyzzy/xyzzy.exe")))
  )

(utm-add-test 'test-url-http-p)

(defun test-url-local-p ()
  (utm-assert (not (url-local-p "http://www.yahoo.co.jp/")))
  (utm-assert (url-local-p "C:/xyzzy/xyzzy.exe"))
  )

(utm-add-test 'test-url-local-p)

(defun test-url-to-filename ()
  (utm-assert-equal "http%3A%2F%2Fwww.yahoo.co.jp%2F"
		    (url-to-filename "http://www.yahoo.co.jp/"))
  (utm-assert-equal "C:/xyzzy/xyzzy.exe"
		    (url-to-filename "C:/xyzzy/xyzzy.exe"))
  )

(utm-add-test 'test-url-to-filename)
