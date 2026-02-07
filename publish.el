;;; publish.el 

(require 'ox)
(require 'ox-publish)
(require 'ox-latex)
(require 'ox-html)
(require 'subr-x)

;; -----------------------------
;; User configuration
;; -----------------------------

(defvar book-title "My Book")
(defvar book-author "Author Name")
(defvar book-language "en")
(defvar book-main-file "book.org")
(defvar book-base-directory (file-name-directory (or load-file-name buffer-file-name)))
(defvar book-assets-directory (expand-file-name "assets/" book-base-directory))

;; Target directories map
(defvar book-targets
  '((pdf . "pdf/")
    (epub . "epub/")
    (html . "html/")))

(defun book-target-path (type &optional filename)
  "Return full path for TYPE (pdf, epub, html), optionally appending FILENAME."
  (let ((dir (expand-file-name (alist-get type book-targets) book-target-directory)))
    (if filename (expand-file-name filename dir) dir)))

(defvar book-target-directory (expand-file-name "target/" book-base-directory))

;; -----------------------------
;; Utility functions
;; -----------------------------

(defun book--all-org-files ()
  "Return list of all Org source files: main + chapters."
  (let ((main (expand-file-name book-main-file book-base-directory))
        (chapters (directory-files-recursively
                   (expand-file-name "chapters/" book-base-directory)
                   "\\.org$")))
    (cons main chapters)))

(defun book--file-newer-p (src dst)
  "Return t if SRC is newer than DST or DST does not exist."
  (or (not (file-exists-p dst))
      (> (float-time (file-attribute-modification-time (file-attributes src)))
         (float-time (file-attribute-modification-time (file-attributes dst))))))

(defun book--any-src-newer-p (dst)
  "Return t if any Org source is newer than DST."
  (seq-some (lambda (f) (book--file-newer-p f dst))
            (book--all-org-files)))

(defun book--ensure-dirs ()
  "Ensure all target directories exist."
  (dolist (dir (append (list book-target-directory)
                       (mapcar (lambda (x) (book-target-path x)) '(pdf epub html))
                       (list (expand-file-name "assets/" (book-target-path 'html)))))
    (unless (file-directory-p dir)
      (make-directory dir t))))

(defun book--clean-pdf-temp-files ()
  "Delete temporary LaTeX files from PDF folder."
  (dolist (f (directory-files (book-target-path 'pdf) t
                               "\\.tex\\|\\.aux\\|\\.log\\|\\.out\\|\\.toc\\|\\.fls\\|\\.fdb_latexmk$"))
    (delete-file f t)))

(defun book--build-if-newer (dst description build-fn)
  "Call BUILD-FN to build DESCRIPTION to DST if sources are newer."
  (if (book--any-src-newer-p dst)
      (progn
        (message "Building %s..." description)
        (funcall build-fn))
    (message "%s is up-to-date." description)))

;; -----------------------------
;; Org export settings
;; -----------------------------

(setq org-export-with-toc t
      org-export-with-section-numbers t
      org-latex-listings 'minted
      org-latex-packages-alist '(("" "minted"))
      org-latex-pdf-process
      '("pdflatex -shell-escape -interaction nonstopmode -output-directory %o %f"
        "pdflatex -shell-escape -interaction nonstopmode -output-directory %o %f"))

(add-to-list 'org-latex-classes
             '("book"
               "\\documentclass[11pt]{book}
[NO-DEFAULT-PACKAGES]
[PACKAGES]
[EXTRA]"
               ("\\chapter{%s}" . "\\chapter*{%s}")
               ("\\section{%s}" . "\\section*{%s}")
               ("\\subsection{%s}" . "\\subsection*{%s}")
               ("\\subsubsection{%s}" . "\\subsubsection*{%s}")))

;; -----------------------------
;; PDF builder
;; -----------------------------

(defun book-build-pdf-clean ()
  "Build PDF completely in target/pdf, silently except for high-level messages."
  (book--ensure-dirs)
  (let* ((tex-file-name "book.tex")
         (tex-file-temp (concat (file-name-sans-extension book-main-file) ".tex"))
         (tex-file-target (book-target-path 'pdf tex-file-name))
         (pdf-file (book-target-path 'pdf "book.pdf")))
    ;; Export Org to LaTeX
    (with-current-buffer (find-file-noselect book-main-file)
      (org-latex-export-to-latex))
    ;; Move .tex to PDF folder
    (rename-file tex-file-temp tex-file-target t)
    ;; Run pdflatex twice silently
    (let ((cmd (format "pdflatex -shell-escape -interaction nonstopmode -output-directory %s %s"
                       (book-target-path 'pdf) tex-file-target)))
      (unless (zerop (shell-command (concat cmd " > /dev/null 2>&1")))
        (error "PDF build failed: see %s" tex-file-target))
      (unless (zerop (shell-command (concat cmd " > /dev/null 2>&1")))
        (error "PDF build failed on second run: see %s" tex-file-target)))
    ;; Clean temp files
    (book--clean-pdf-temp-files)
    (message "PDF built cleanly at %s" pdf-file)))

;; -----------------------------
;; Org publishing projects (HTML + assets)
;; -----------------------------

(setq org-publish-project-alist
      `(
        ("book-html"
         :base-directory ,book-base-directory
         :base-extension "org"
         :publishing-directory ,(book-target-path 'html)
         :publishing-function org-html-publish-to-html
         :recursive t
         :exclude ".*"
         :include (,book-main-file)
         :with-author t
         :with-creator t
         :with-toc t
         :section-numbers t)

        ("book-html-assets"
         :base-directory ,book-assets-directory
         :base-extension "css\\|js\\|png\\|jpg\\|gif\\|svg\\|woff\\|woff2\\|ttf\\|eot"
         :publishing-directory ,(expand-file-name "assets/" (book-target-path 'html))
         :publishing-function org-publish-attachment
         :recursive t)

        ("book"
         :components ("book-html" "book-html-assets"))))

;; -----------------------------
;; EPUB via Pandoc
;; -----------------------------

(defun book-export-epub ()
  "Export EPUB to target/epub only if sources changed, quietly."
  (book--ensure-dirs)
  (let ((output (book-target-path 'epub (concat (file-name-base book-main-file) ".epub"))))
    (book--build-if-newer output "EPUB"
                          (lambda ()
                            (let ((cmd (format "pandoc %s -o %s --metadata title=\"%s\" --metadata author=\"%s\" --metadata lang=\"%s\""
                                               book-main-file output book-title book-author book-language)))
                              (unless (zerop (shell-command (concat cmd " > /dev/null 2>&1")))
                                (error "EPUB build failed"))
                              (message "EPUB exported to %s" output))))))

;; -----------------------------
;; Main incremental publish
;; -----------------------------

(defun book-publish-all ()
  "Incrementally build PDF, HTML (with assets), EPUB; fully clean and mostly silent."
  (interactive)
  (book--ensure-dirs)
  ;; PDF
  (book--build-if-newer (book-target-path 'pdf "book.pdf") "PDF" #'book-build-pdf-clean)
  ;; HTML
  (book--build-if-newer (book-target-path 'html "index.html") "HTML"
                         (lambda () (let ((inhibit-message t))
                                      (org-publish "book" t))))
  ;; EPUB
  (book-export-epub)
  (message "Publishing complete! Everything is inside target/"))

(provide 'publish)
;;; publish.el ends here

