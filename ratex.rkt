#lang racket

(require pollen/core
         pollen/setup
         racket/string
         racket/format
         pollen/template
         uuid)

(provide (all-defined-out))

(define (strings->string sts)
  (apply string-append sts))

;;; DOCUMENT FUNCTIONS

(define ($ #:name [name ""] #:force [force #f] #:preamble [preamble ""] . code)
  (apply
   latex
   #:type "inline"
   #:name name
   #:force force
   #:preamble preamble
   (list "\\scalebox{0.01}{\\color{neonpink}\\footnotesize.}" "$" (apply string-append code) "$")))

(define ($$ #:name [name ""] #:force [force #f] #:preamble [preamble ""] . code)
  (apply latex
         #:type "display"
         #:name name
         #:force force
         #:preamble preamble
         (list "\\[" (apply string-append code) "\\]")))

(define (tikz #:name [name ""] #:force [force #f] #:preamble [preamble ""] . code)
  (apply latex
         #:type "tikz"
         #:name name
         #:force force
         #:preamble (strings->string (list "\\usepackage{tikz}"
                                           "\\usetikzlibrary{decorations.pathreplacing}"
                                           "\\usetikzlibrary{calc}"
                                           "\\usepackage{pgfplots}"
                                           "\\usepgfplotslibrary{statistics}"
                                           preamble))
         (list "\\centering" (apply string-append code))))

(define (table format #:name [table-name ""] #:force [force #f] #:preamble [preamble ""] . code)
  (define split-by-lines (string-split (apply string-append code) "\n"))
  (define trimmed-by-lines
    (map (λ (line)
           (string-replace
            (regexp-replace*
             #rx"( +\\|)+$"
             (string-trim #:right? #f (regexp-replace* #rx"(?:\\|? -+ \\|?)+" line "[0.5em]") "|")
             (string-append "\\\\" "\\\\"))
            "|"
            "&"))
         split-by-lines))
  (latex #:type "table"
         #:name table-name
         #:force force
         #:preamble (strings->string (list "\\usepackage{dcolumn}"
                                           "\\newcolumntype{d}[1]{D{.}{.}{#1}}"
                                           "\\usepackage{booktabs}"
                                           "\\usepackage{multirow}"
                                           "\\usepackage{makecell}"
                                           "\\renewcommand\\theadfont{\\bfseries}"
                                           "\\usepackage{siunitx}"
                                           preamble))
         (string-append "\\centering"
                        "\\begin{tabular}{"
                        format
                        "}"
                        (strings->string trimmed-by-lines)
                        "\\end{tabular}")))

;;; HELPER FUNCTIONS

(define (latex->ref #:type [type ""] #:name [unique-name ""] #:preamble [preamble ""] . code)

  (define path (build-path "latex" (~a unique-name ".tex")))
  (define pdf-path (build-path "latex" (~a unique-name ".pdf")))
  (define img-path (build-path "latex" (~a unique-name ".svg")))
  (define code-contents (apply string-append code))
  (define tex-file-contents
    (strings->string (list "\\documentclass[preview, border=1pt]{standalone}"
                           "\\usepackage{amsmath, amssymb}"
                           "\\usepackage{xcolor}"
                           "\\usepackage{mathtools}"
                           "\\renewcommand{\\baselinestretch}{1.2}"
                           "\\definecolor{neonpink}{HTML}{FF0FF0}" ;needed for inline math
                           preamble
                           "\\begin{document}"
                           "\\raggedright "
                           code-contents
                           "\\end{document}")))

  (make-directory* "latex")
  (with-output-to-file path (lambda () (printf tex-file-contents)) #:exists 'replace)
  (define latex-cmd
    (string-append "xelatex " "-shell-escape " "-output-directory " "latex" " " (path->string path)))
  (define img-cmd
    (string-append
     "inkscape --pdf-poppler --pdf-page=1 --export-type=svg --export-text-to-path --export-area-drawing --export-filename"
     " "
     (path->string img-path)
     " "
     (path->string pdf-path)))

  ; * only build the PDF and convert it to SVG when it doesn't already exist OR when forcing with environment variable
  (system latex-cmd)
  (system img-cmd)

  ; (path->string img-path)
  )

(define (latex #:type [type "type"]
               #:name [name "name"]
               #:force [force #f]
               #:preamble [preamble ""]
               . code)
  (define unique-name
    (strings->string (list (if (non-empty-string? type) (string-append type "_") "")
                           (if (non-empty-string? name) (string-append name "_") "")
                           (number->string (equal-hash-code code)))))

  (define img-path (path->string (build-path "latex" (~a unique-name ".svg"))))

  ;;; (or force
  (when (or (not (file-exists? (string->path img-path))) (or force (equal? (getenv "POLLEN") "TEX")))
    (apply latex->ref #:type type #:name unique-name #:preamble preamble code))

  (define file-contents (port->string (open-input-file img-path)))

  (define raw-img-width
    (string->number
     (apply string-append (regexp-match* #rx"(?<=width=\")(.+?)(?=pt\"\n)" file-contents))))

  (define raw-img-height
    (string->number
     (apply string-append (regexp-match* #rx"(?<=height=\")(.+?)(?=pt\"\n)" file-contents))))

  (define dot-height-px-rel
    (if (eq? type "inline")
        (string->number (apply string-append
                               (regexp-match* (regexp "(?<=y=\").*?(?=\"\n)")
                                              (apply string-append
                                                     (regexp-match* (regexp "fill:#ff0cf0.*?</g>")
                                                                    file-contents)))))
        0))

  (define dot-shift-px
    (if (eq? type "inline")
        (string->number
         (apply string-append
                (regexp-match*
                 (regexp "(?<=,).+(?=\\))")
                 (apply string-append
                        (regexp-match* (regexp "translate\\(-*[0-9]*.[0-9]*,-*[0-9]*.[0-9]*\\)")
                                       file-contents)))))
        0))
  (define dot-height-px (- raw-img-height (+ dot-height-px-rel dot-shift-px)))

  (define img-height-em (/ raw-img-height 10))
  (define img-width-em (/ raw-img-width 10))
  (define dot-height-em (/ dot-height-px 10))

  ; (define vshift-percent (string-append (~a (* 100 (/ dot-height-px raw-img-height))) "%"))
  (define vshift-percent (string-append (~a (- (/ (- img-height-em 1) 2) dot-height-em)) "em"))
  (define vshift-container (string-append (~a (* -1 dot-height-em)) "em"))

  (define centering?
    (case type
      [("display") #t]
      [("table") #t]
      [("tikz") #t]
      [("inline") #f]
      [else #f]))

  (define css-class
    (case type
      [("display") "display"]
      [("table") "display"]
      [("tikz") "display"]
      [("inline") "inline"]
      [else ""]))

  (define spec-css-class
    (if (non-empty-string? css-class)
        `,(strings->string (list "latex" " " css-class (if centering? " centered" "")))
        `"latex"))

  (define unique-html-id (strings->string (list unique-name "_" (uuid-string))))

  (define inline-container-height img-height-em)

  (define img-caption
    (case (current-poly-target)
      [(html) (apply string-append code)]
      [else ""]))

  (case (current-poly-target)
    [(html)
     (if (eq? type "inline")
         `(@ (style ,(strings->string (list "img#"
                                            unique-html-id
                                            ".latex {"
                                            "    height: "
                                            (number->string img-height-em)
                                            "em; "
                                            "}")))
             (span ((class "inline-latex-container")
                    (style ,(strings->string (list "width: "
                                                   (number->string img-width-em)
                                                   "em;"
                                                   "height: "
                                                   (number->string inline-container-height)
                                                   "em;"
                                                   "margin-bottom: "
                                                   vshift-container
                                                   ";"))))
                   (img ((class ,spec-css-class) (id ,unique-html-id)
                                                 (src ,img-path)
                                                 (alt ,img-caption)))))

         `(@ (style ,(strings->string (list "img#"
                                            unique-html-id
                                            ".latex {"
                                            "    height: "
                                            (number->string img-height-em)
                                            "em;"
                                            "    width: auto; "
                                            "}")))
             (figure ((class "latex-wrapper"))
                     (@ (div (img ((class ,spec-css-class) (id ,unique-html-id)
                                                           (src ,img-path)
                                                           (alt ,img-caption))))))))]
    [(pdf) `(txt-noescape ,(apply string-append code))]))

(define (pdf->svg #:pdf-path (pdf-path "") #:svg-path (svg-path "") #:minitab (minitab #f))
  (define img-cmd
    (string-append
     "inkscape --pdf-poppler --pdf-page=1 --export-type=svg --export-text-to-path --export-area-drawing --export-filename"
     " "
     (path->string svg-path)
     " "
     (path->string pdf-path)))
  (@ (system img-cmd)
     (system (strings->string
              (list "sed -i '' \"s/fill:#ffffff;fill-opacity:1/fill:#ffffff;fill-opacity:0/\" "
                    (path->string svg-path))))
     ;;; fill:#e6e6e6;
     (if minitab
         (@ (system (strings->string (list "sed -i '' \"s/fill:#e6e6e6;/fill:#ffffff;/\" "
                                           (path->string svg-path))))
            (system (strings->string (list "sed -i '' \"s/fill:#e3e3e3;/fill:#ffffff;/\" "
                                           (path->string svg-path)))))
         (@ ""))))
