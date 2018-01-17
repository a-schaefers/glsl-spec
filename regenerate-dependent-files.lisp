(ql:quickload '(:cl-json :alexandria :split-sequence))

(in-package :glsl-spec)

;;------------------------------
;; JSON Files

(defun export-data-to-json (data file-name)
  (with-open-file (x (asdf:system-relative-pathname :glsl-spec file-name)
                     :direction :output :if-exists :supersede)
    (let ((data
           (mapcar (lambda (x)
                     (assert (eq :lisp-name (first x)))
                     (cddr x))
                   data)))
      (format x "[~{~a~^,~%~}]"
              (mapcar #'cl-json:encode-json-plist-to-string
                      data)))))

(defun regen-json-files ()
  (export-data-to-json glsl-spec:*functions* "functions.json")
  (export-data-to-json glsl-spec:*variables* "variables.json"))

;;------------------------------
;; GLSL-Symbols Package

(defun regen-lisp-package ()
  (let* ((lines (split-sequence:split-sequence
                 #\newline
                 (alexandria:read-file-into-string
                  (asdf:system-relative-pathname
                   :glsl-spec "./symbols/glsl-types-lisp-names.txt"))))
         (lines (remove-if #'alexandria:emptyp lines))
         (types (mapcar (lambda (x) (intern x :keyword)) lines))
         (vars (remove-duplicates
                (mapcar (lambda (x)
                          (destructuring-bind
                                (&key lisp-name &allow-other-keys) x
                            (if lisp-name
                                (intern lisp-name :keyword)
                                (error "bummer"))))
                        glsl-spec:*variables*)))
         (funcs (remove-duplicates
                 (mapcar (lambda (x)
                           (destructuring-bind (&key lisp-name &allow-other-keys) x
                             (if lisp-name
                                 (intern lisp-name :keyword)
                                 (error "bummer"))))
                         glsl-spec:*functions*)))
         (pkgs `((uiop:define-package #:glsl-symbols.types
                     (:use #:cl)
                   (:export ,@(sort types #'string<)))
                 (uiop:define-package #:glsl-symbols.variables
                     (:use #:cl)
                   (:export ,@(sort vars #'string<)))
                 (uiop:define-package #:glsl-symbols.functions
                     (:use #:cl)
                   (:export ,@(sort funcs #'string<)))
                 (uiop:define-package #:glsl-symbols
                     (:use #:cl
                           #:glsl-symbols.types
                           #:glsl-symbols.variables
                           #:glsl-symbols.functions)
                   (:reexport #:glsl-symbols.types
                              #:glsl-symbols.variables
                              #:glsl-symbols.functions)))))
    (with-open-file (x (asdf:system-relative-pathname
                        :glsl-spec "./symbols/package.lisp")
                       :direction :output :if-exists :supersede)
      (format x ";; glsl-symbols~{~%~%~s~}" pkgs))))

;;------------------------------

(defun regenerate-files ()
  (regen-json-files)
  (regen-lisp-package))


(regenerate-files)
