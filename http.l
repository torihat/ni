;;; -*- Mode: Lisp; Package: EDITOR -*-
;;;
;;; This file is not part of xyzzy.
;;;
; $Id: http.l 734 2006-09-05 01:49:02Z torihat $
;
; ni/http.l
;
; by HATTORI Masashi

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "ni/defs")
  (require "ni/macro"))
(require "ni/lib")

(provide "ni/http")

(in-package "netinst")

(defvar *http-debug* nil)

(setf (get 'http-interval-message 'lisp-indent-hook) 1)

(defmacro http-interval-message ((interval) &body body)
  `(let ((#1=#:last-tick (+ (get-internal-real-time) ,interval))
	 (#2=#:tick))
     (flet ((message (&rest args)
	      (setq #2# (get-internal-real-time))
	      (when (> #2# #1#)
		(setq #1# (+ #2# ,interval))
		(apply #'message args))))
       ,@body)))

(defun http-get (host file &key port head no-cache referer post auth other)
  (interactive)
  (let (line status header s proxy-p host-orig port-orig request response)
    ;;;
    ;;; 亀井さんが送って下さったPROXY対応
    ;;;
    (when (and *http-proxy-host* *http-proxy-port*
	       (not (find-if #'(lambda (x)
				 (string-matchp (cond ((string-match "^\\([0-9]+\\.\\)+$" x)
						       (concat "^" (regexp-quote x)))
						      ((string-match "^[0-9]+\\(\\.[0-9]+\\)*" x)
						       (concat "^" (regexp-quote x) "\\($\\|\\.\\)"))
						      (t
						       (concat "\\(^\\|\\.\\)" (regexp-quote x) "$")))
						host))
			     *http-direct-connect-list*)))
      (setq file (concat "http://" host (and port (format ":~a" port)) file))
      (setq host-orig host)
      (setq host *http-proxy-host*)
      (setq port-orig port)
      (setq port *http-proxy-port*)
      (setq proxy-p t))
    (ni-message "connecting to ~A ..." host)
    (setq s (connect host (or port *http-port*)))
    (setq request
	  (with-output-to-string (req)
	    (cond (post
		   (let ((clength (length post)))
		     (format req "POST ~A HTTP/~A~%" file *http-version*)
		     (format req "Content-type: application/x-www-form-urlencoded~%")
		     (format req "Content-length: ~D~%" clength)
		     ))
		  (head
		   (format req "HEAD ~A HTTP/~A~%" file *http-version*))
		  (t
		   (format req "GET ~A HTTP/~A~%" file *http-version*))
		  )
	    (format req "Host: ~A~%" (or host-orig host))
	    (when no-cache
	      (format req "Pragma: no-cache~%"))
	    (when (stringp referer)
	      (format req "Referer: ~A~%" referer))
	    (when (stringp auth)
	      (format req "Authorization: basic ~A~%" auth))
	    (when (and *http-proxy-user*
		       *http-proxy-pass*)
	      (format req "Proxy-Authorization: basic ~A~%"
		      (http-auth-encode-account *http-proxy-user*
						*http-proxy-pass*)))
	    (when other
	      (let (other-header)
		(dolist (other-header other)
		  (let ((key (car other-header))
			(val (cdr other-header)))
		    (format req "~A: ~A~%" key val)))))
	    (unless (assoc "accept-language" other :test #'equalp)
	      (format req "Accept-Language: ~A~%" *http-accept-language*))
	    (format req "User-Agent: ~A~%" *http-user-agent*)
	    (format req "X-Yzzy-Version: xyzzy-~A~%" (software-version))
	    (format req "~%")
	    (when post
	      (format req "~A~%" post))))
    ;    (when *http-debug*
    ;      (msgbox "~S" request))
    (format s "~A" request)
    (ni-message "waiting for reply ...")
    (unless (setq line (read-line s nil))
      (ni-error "connection closed."))
    (if (string-match "^HTTP/\\([0-9.]+\\)[ \t]+\\([0-9]+\\)[ \t]*\\(.*\\)$" line)
	(progn
	  (message "~A" line)
	  (push line response)
	  (setq status (substring line (match-beginning 2) (match-end 2)))
	  )
      (ni-error "not status: ~A" line)
      )
    (unless (setq line (read-line s nil))
      (ni-error "connection closed."))
    (loop
      (push line response)
      (cond ((string= line "")
	     (return))
	    ((string-match "^\\([-a-zA-Z0-9_]+\\)[ \t]*:[ \t]*\\(.*\\)" line)
	     (let (key val)
	       (message "~A" line)
	       (setq key (nstring-downcase (substring line (match-beginning 1) (match-end 1))))
	       (setq val (substring line (match-beginning 2) (match-end 2)))
	       (if (setq line (read-line s nil))
		   (while (string-match "^[ \t]+\\(.*\\)" line)
		     (setq val (concat val line))
		     (unless (setq line (read-line s nil))
		       (return))
		     )
		 (return)
		 )
	       (push (list (nstring-downcase key) val) header)
	       ))
	    (t
	     (setq line (read-line s nil))
	     )
	    )
      )
    (when *http-debug*
      (msgbox "~S~%~%~{~S~%~}" request (reverse response)))
    (values s status header request)
    ))

(defun http-get-data-to-stream (is os &optional size)
  (set-stream-encoding is :binary)
  (set-stream-encoding os :binary)
  (let ((data (make-vector *http-recv-vector-size* :element-type 'character :fill-pointer 0))
	(bytes 0))
    (ni-message "getting data ...")
    (http-interval-message (300)
      (while (read-into data is nil)
	(format os "~A" data)
	(when *http-show-status-message*
	  (incf bytes (length data))
	  (if size
	      (ni-message "getting ~3d% of ~d bytes"
		       (truncate (/ (* 100 bytes) size)) size)
	    (ni-message "getting ~d bytes" bytes)))))
    ))

(defun http-get-header-value (key header)
  (car (cdr (assoc key header :test #'equal))))

(defun http-get-url (url &key no-cache referer post head auth other)
  (interactive)
  (let (proto
	host
	port
	file
	anchor
	)
    (multiple-value-setq (proto host file anchor port)
      (http-url-study url))
    (unless (string= proto "http")
      (ni-error "http protocol unmatch: ~A" url))
    (setq file (concat "/" file))
    (http-get host
	      file
	      :port port
	      :no-cache no-cache
	      :referer referer
	      :post post
	      :head head
	      :auth auth
	      :other other)
    ))

(defun http-url-study (url)
  (let (res
	port
	(proto "")
	(host "")
	(path "")
	anchor)
    (when (string-match "\\([^#]*\\)#\\(.*\\)" url)
      (setq anchor (substring url (match-beginning 2) (match-end 2)))
      (setq url (substring url (match-beginning 1) (match-end 1)))
    )
    (cond ((string-match "^file://\\(.*\\)$" url)
	   (progn
	     (setq proto "file")
	     (setq path (substring url
				    (match-beginning 1)
				   (match-end 1)))))
	  ((string-match "^mailto:" url)
	   (setq proto "mailto"))
	  ((string-match "^\\([^:]+\\)://\\([^:/]+\\):\\([0-9]+\\)/\\(.*\\)$" url)
	   (progn
	     (setq proto (substring url
				    (match-beginning 1)
				    (match-end 1)))
	     (setq host (substring url
				     (match-beginning 2)
				     (match-end 2)))
	     (setq port (parse-integer (substring url
						  (match-beginning 3)
						  (match-end 3))))
	     (setq path (substring url
				   (match-beginning 4)
				   (match-end 4)))
	   ))
	  ((string-match "^\\([^:]+\\)://\\([^/]+\\)/\\(.*\\)$" url)
	   (progn
	     (setq proto (substring url
				    (match-beginning 1)
				    (match-end 1)))
	     (setq host (substring url
				     (match-beginning 2)
				     (match-end 2)))
	     (setq path (substring url
				   (match-beginning 3)
				   (match-end 3)))))
	  ((string-match "^\\([^:]+\\)://\\([^/]+\\)$" url)
	   (progn
	     (setq proto (substring url
				    (match-beginning 1)
				    (match-end 1)))
	     (setq host (substring url
				     (match-beginning 2)
				     (match-end 2)))))
    )
    (values proto host path anchor port url)
  ))

(defun http-auth-encode-account (user pass)
  (substitute-string (si:base64-encode (concat user ":" pass)) "\n" ""))

(defun http-data-to-file (is file &optional size &key append)
  (with-open-file (os file
		      :direction :output
		      :if-exists (if append
				     :append
				   :supersede)
		      :if-does-not-exist :create)
    (http-get-data-to-stream is os size))
  (close is))

(defvar *rfc822-date-time-regexp*
  (compile-regexp
   "^[ \t]*\\([A-Za-z]+[ \t]*,[ \t]*\\)?\\([0-9]+\\)[ \t]+\\([A-Za-z]+\\)[ \t]+\\([0-9]+\\)[ \t]+\\\([0-9]+\\):\\([0-9]+\\)\\(:\\([0-9]+\\)\\)?\\([ \t]+\\([-+][0-9]+\\|[A-Za-z]+\\)\\)?"))

(defvar *month-name-hash*
  (let ((hash (make-hash-table :test #'equalp)))
    (dotimes (i 12)
      (setf (gethash (svref #("Jan" "Feb" "Mar" "Apr" "May" "Jun"
			      "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")
			    i)
		     hash)
	    (+ i 1)))
    hash))
 
(defvar *timezone-hash-table*
  (let ((hash (make-hash-table :test #'equal)))
    (mapc #'(lambda (x)
	      (setf (gethash (car x) hash) (cdr x)))
	  '(("A" . "-0100") ("B" . "-0200") ("C" . "-0300") ("D" . "-0400")
	    ("E" . "-0500") ("F" . "-0600") ("G" . "-0700") ("H" . "-0800")
	    ("I" . "-0900") ("K" . "-1000") ("L" . "-1100") ("M" . "-1200")
	    ("N" . "+0100") ("O" . "+0200") ("P" . "+0300") ("Q" . "+0400")
	    ("R" . "+0500") ("S" . "+0600") ("T" . "+0700") ("U" . "+0800")
	    ("V" . "+0900") ("W" . "+1000") ("X" . "+1100") ("Y" . "+1200")
	    ("Z" . "+0000")
	    ("IDLW" . "-1200") ("NT" . "-1100") ("AHST" . "-1000") ("CAT" . "-1000")
	    ("HST" . "-1000") ("YST" . "-0900") ("PST" . "-0800") ("MST" . "-0700")
	    ("CST" . "-0600") ("EST" . "-0500") ("AST" . "-0400") ("AT" . "-0200")
	    ("WAT" . "-0100") ("GMT" . "+0000") ("UT" . "+0000") ("UTC" . "+0000")
	    ("WET" . "+0000") ("CET" . "+0100") ("FWT" . "+0100") ("MET" . "+0100")
	    ("MEWT" . "+0100") ("SWT" . "+0100") ("EET" . "+0200") ("BT" . "+0300")
	    ("ZP4" . "+0400") ("ZP5" . "+0500") ("ZP6" . "+0600") ("WAST" . "+0700")
	    ("CCT" . "+0800") ("HKT" . "+0800") ("JST" . "+0900") ("EAST" . "+1000")
	    ("GST" . "+1000") ("IDLE" . "+1200") ("NZST" . "+1200") ("NZT" . "+1200")
	    ("HDT" . "-0900") ("YDT" . "-0800") ("PDT" . "-0700") ("MDT" . "-0600")
	    ("CDT" . "-0500") ("EDT" . "-0400") ("ADT" . "-0400") ("BST" . "+0100")
	    ("MEST" . "+0200") ("MESZ" . "+0200") ("SST" . "+0200") ("FST" . "+0200")
	    ("WADT" . "+0800") ("EADT" . "+1100") ("NZDT" . "+1300")))
    hash))
   
(defun parse-header-date (date)
  (when date
    (while (let (f)
	     (multiple-value-setq (date f)
	       (substitute-string date "([^()]*)" " "))
	     (and f (plusp f))))
    (when (string-match *rfc822-date-time-regexp* date)
      (encode-universal-time (if (match-beginning 8)
				 (parse-integer (subseq date (match-beginning 8) (match-end 8)))
			       0)
			     (parse-integer (subseq date (match-beginning 6) (match-end 6)))
			     (parse-integer (subseq date (match-beginning 5) (match-end 5)))
			     (parse-integer (subseq date (match-beginning 2) (match-end 2)))
			     (gethash (subseq date (match-beginning 3) (match-end 3))
				      *month-name-hash* 1)
			     (parse-integer (subseq date (match-beginning 4) (match-end 4)))
			     (if (match-beginning 9)
				 (let ((zone (subseq date (match-beginning 9) (match-end 9))))
				   (setq zone (string-left-trim " \t" zone))
				   (when (string-match "^[a-zA-Z]+$" zone)
				     (setq zone (gethash zone *timezone-hash-table* zone)))
				   (if (string-match "^[-+][0-9][0-9][0-9][0-9]$" zone)
				       (- (truncate (parse-integer zone) 100))
				     0))
			       0)))))

(defun format-header-date (&optional time)
  "Dateヘッダー書式化して返す。(ex.Date: Sun, 12 Sep 1999 13:18:13 GMT"
  (setq time (- (or time (get-universal-time)) (* 9 60 60)))
  (format-date-string "%a, %d %b %Y %H:%M:%S GMT" time))

(defun http-get-to-file (url file &optional force)
  (interactive)
  (let (sock
	status
	header
	dir
	size
	wtime
	other
	result)
    ; ローカルディレクトリがなければ作成
    (setq dir (directory-namestring file))
    (unless (file-exist-p dir)
      (create-directory dir))
    ; 既にファイルがある場合
    (when (file-exist-p file)
      (setq size (file-length file))
      (setq wtime (file-write-time file))
      (unless force
	; If-Modified-Since: 更新されていれば取得
	(push (cons "If-Modified-Since" (format-header-date wtime)) other)))
    (push (cons "Accept" "*/*") other)
    (push (cons "Accept-Language" "ja,en") other)
    ; HTTP GET
    (handler-case
	(multiple-value-setq (sock status header)
	  (http-get-url url :other other))
      (socket-error (c)
	(when (socket-stream-p sock)
	  (close sock))
	(error "Socket error: ~A" (si:*condition-string c)))
      (quit (c)
	(when (socket-stream-p sock)
	  (close sock))
	(error "Interrupted: ~A" (si:*condition-string c)))
      )
    (unless (stringp status)
      (error "~S~%~S" status header))
    ; 更新されていない
    (when (string-match "^304" status)
      (message "~A" status)
      (return-from http-get-to-file))
    ; Redirect
    (when (string-match "^302" status)
      (let ((location (http-get-header-value "location" header)))
	(when location
	  (return-from http-get-to-file
	    (http-get-to-file location file force)))))
    ; エラーステータス
    (unless (and (string-match "^2[0-9][0-9]" status)
		 header)
      (error "~S~%~S~%~S" url status header))
    (let (length last stime)
      ; 更新日時の取得
      (when (setq last (http-get-header-value "last-modified" header))
	(setq stime (parse-header-date last)))
      ; 受信バイト数の取得
      (setq length (http-get-header-value "content-length" header))
      (when (and (stringp length)
		 (string-match "^[0-9]+$" length))
	(setq length (parse-integer length)))
      ; 受信
      (long-operation
	(http-data-to-file sock
			   file
			   length)
	(when stime
	  (set-file-write-time file stime))
	(message "saved:  ~A" file)))
    t))
