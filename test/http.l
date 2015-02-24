; $Id: http.l,v 1.2 2003/04/02 22:01:19 torihat Exp $
;
; http.l
;

(require "ni/http")

(in-package "ni")

(defun test-http-url-study ()
  (multiple-value-bind (proto host path anchor port url)
      (http-url-study "http://www.mirai.ne.jp/~gyo/xyzzy/index.html#hogehoge")
    (utm-assert-equal "http" proto)
    (utm-assert-equal "www.mirai.ne.jp" host)
    (utm-assert-equal "~gyo/xyzzy/index.html" path)
    (utm-assert-equal "hogehoge" anchor)
    (utm-assert-equal nil port)
    (utm-assert-equal "http://www.mirai.ne.jp/~gyo/xyzzy/index.html" url))
  )

(utm-add-test 'test-http-url-study)

(defun test-http-auth-encode-account ()
  (utm-assert-equal "eHl6enk6aG9nZWhvZ2U="
		    (http-auth-encode-account "xyzzy" "hogehoge"))
  )

(utm-add-test 'test-http-auth-encode-account)

(defun test-parse-header-date ()
  (utm-assert-equal 3258006864 (parse-header-date "Sun, 30 Mar 2003 09:54:24 GMT"))
  )

(utm-add-test 'test-parse-header-date)

(defun test-format-header-date ()
  (utm-assert-equal "Sun, 30 Mar 2003 09:54:24 GMT" (format-header-date 3258006864))
  )

(utm-add-test 'test-format-header-date)
