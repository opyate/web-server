#lang racket
(require (for-syntax racket 
                     syntax/parse)
         racket/stxparam
         "lib.rkt"
         (for-syntax "lib.rkt"))

(define-syntax-parameter #%# 
  (λ (stx) (raise-syntax-error '#%# "Only allowed inside formlet or formlet*" stx)))

(define-for-syntax (cross-of stx)
  (syntax-parse 
   stx
   #:literals (unquote unquote-splicing => #%# values)
   [s:str
    (syntax/loc stx empty)]
   [,(formlet . => . (values name:id ...)) (syntax/loc stx (vector name ...))]
   [,(formlet . => . name:id) (syntax/loc stx name)]
   [,e (syntax/loc stx empty)]
   [,@e (syntax/loc stx empty)]
   [(#%# n ...)
    (quasisyntax/loc stx (list #,@(map cross-of (syntax->list #'(n ...)))))]
   [(t ([k v] ...) n ...)
    (quasisyntax/loc stx (list #,@(map cross-of (syntax->list #'(n ...)))))]
   [(t n ...)
    (quasisyntax/loc stx (list #,@(map cross-of (syntax->list #'(n ...)))))]))

(define-for-syntax (circ-of stx)
  (syntax-parse
   stx
   #:literals (unquote unquote-splicing => #%# values)
   [s:str
    (syntax/loc stx (text s))]
   [,(formlet . => . (values name:id ...)) (syntax/loc stx (cross (pure (lambda (name ...) (vector name ...))) formlet))]
   [,(formlet . => . name:id) (syntax/loc stx formlet)]
   [,e (syntax/loc stx (xml e))]
   [,@e (syntax/loc stx (xml-forest e))]
   [(#%# n ...)
    (let ([n-cross (map cross-of (syntax->list #'(n ...)))])
      (quasisyntax/loc stx
        (cross*
         (pure (match-lambda*
                 [(list #,@n-cross)
                  (list #,@n-cross)]))
         #,@(map circ-of (syntax->list #'(n ...))))))]
   [(t ([k v] ...) n ...)
    (quasisyntax/loc stx
      (tag-xexpr `t `([k v] ...)
                 #,(circ-of (syntax/loc stx (#%# n ...)))))]
   [(t n ...)
    (quasisyntax/loc stx
      (tag-xexpr `t empty
                 #,(circ-of (syntax/loc stx (#%# n ...)))))]))

(define-syntax (formlet stx)
  (syntax-case stx ()
    [(_ q e)
     (quasisyntax/loc stx
       (cross (pure (match-lambda [#,(cross-of #'q) e]))
              #,(circ-of #'q)))]))

(provide formlet #%#)