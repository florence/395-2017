#lang racket

;; Racket namespace nonsense...
(define-namespace-anchor a)
(define ns (namespace-anchor->namespace a))

;; Let's write up the example optimized "all" for practice.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; NOTE(jordan): ’ codepoint is 2019.
(define (all’ p xs)
  (if (empty? xs) #t
      (and (p (first xs)) (all’ p (rest xs)))))

(define (all p xs) (andmap p xs))

(and (all number? '(5 5 5)) (all’ number? '(5 5 5)))

;; Okay next up. Let's define build.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define -build
  `(define (build g) (g cons '())))
(eval -build ns)
;; ^^ Essentially: partial application of g with cons and '().!

;; Let's do the from example.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; from
(define (from a b)
  (if (> a b)
    '()
    (cons a (from (+ a 1) b))))

;; from’
(define -from’
  `(define (from’ a b)
    (λ (c n)
       (if (> a b)
         n
         (c a ((from’ (+ a 1) b) c n))))))
(eval -from’ ns)

;; Verify from’ is spiritually equal to from.
(eval `(andmap equal? (from 0 5) (build (from’ 0 5))) ns)

;; Nice! We can see that these things work, just like the paper said. (Whodathunk.)
;; Let's build the (build) stdlib.
(define -map’
  `(define (map’ f xs)
    (build (λ (c n) (foldr (λ (a b) (c (f a) b)) n xs)))))
(eval -map’ ns)

(define -filter’
  `(define (filter’ f xs)
    (build (λ (c n) (foldr (λ (a b) (if (f a) (c a b) b)) n xs)))))
(eval -filter’ ns)

(define -++’
  `(define (++’ xs ys)
    (build (λ (c n) (foldr c (foldr c n ys) xs)))))
(eval -++’ ns)

(define -concat’
  `(define (concat’ xs)
    (build (λ (c n) (foldr (λ (x y) (foldr c y x)) n xs)))))
(eval -concat’ ns)

;; Seems non-trivial to create an infinite list in Racket to mimic repeat.
;; Would I need Streams here? Not that important.
#| (define (repeat’ x)      |#
#|   (build (λ (c n) ...))) |#

#| (repeat’ 5)              |#

(define -zip’
  `(define (zip’ xs ys)
    (build (λ (c n) (if (and (not (empty? xs)) (not (empty? ys)))
                        (c `(,(first xs) ,(first ys)) (zip’ (rest xs) (rest ys)))
                        n)))))
(eval -zip’ ns)

(define -nil’
  `(define nil’ (build (λ (c n) n))))
(eval -nil’ ns)

(define -cons’
  `(define (cons’ x xs) (build (λ (c n) (c x (foldr c n xs))))))
(eval -cons’ ns)

(define -cons’-nil’
  `(define (cons’ x nil’) (build (λ (c n) (c x n)))))

;; Verify loosely/informally that these behave more-or-less as expected.
(eval `(map’ - '(1 2 3)) ns)

(eval `(filter’ number? '(1 2 "a" "b" 4 "c")) ns )

(eval `(++’ '(1 2) '(3 4)) ns)

(eval `(concat’ '((1) (2 3) (4 5 6))) ns)

(eval `(zip’ '(1 2 3) '("a" "b" "c")) ns)

(eval `nil’ ns)

(eval `(cons’ 5 '(4 3 2 1)) ns)

;; Now let's do some kind of actual work.
;; Convert unlines to use build-based library functions.
;; In Haskell, strings are lists, which means racket don't do that... So we fake it.
(define (unlines ls) (flatten (map (λ (l) (append l '("\n"))) ls)))

(define ls '(("t" "h" "i" "s") () ("s" "u" "c" "K" "s")))
(unlines ls)

;; flatten -> concat’
;; append  -> append’

(define (libfn->buildfn exp)
  (match exp
    [`(flatten ,xs) `(concat’ ,(libfn->buildfn xs))]
    [`(append ,xs ,ys) `(++’ ,(libfn->buildfn xs) ,(libfn->buildfn ys))]
    [`(map ,f ,xs) `(map’ ,(libfn->buildfn f) ,(libfn->buildfn xs))]
    [`'(,elt) `(cons’ ,elt nil’)]
    [`(λ ,args ,body) `(λ ,args ,(libfn->buildfn body))]
    [e e]))

(libfn->buildfn `(append l '("\n")))

;; Let's actually try to run it!
(letrec ([bexp (libfn->buildfn `(flatten (map (λ (l) (append l '("\n"))) ',ls)))])
  (display (apply string-append (eval bexp ns))))
;; But hey, the transformation is (roughly) working on the body of unlines.

;; Let's try expanding buildfns using their bodies.

;; Oh man this is awful. What have I done.
(define -body third)

;; This must be incomplete. But anyway.
;; This needs to be capture-avoiding substitution. (See whiteboard photo.)
;; Application with variable, occurrence where variable doesn't occur free in λ body.
;; Add more of their examples and make sure they work.
(define (replace-exp exp val body)
  (match body
    ;; This is the interesting case:
    [`(λ ,args ,lbody) `(λ ,args ,(replace-exp exp val lbody))]
    [(? list?) (map (curry replace-exp exp val) body)]
    [(? symbol?) (if (equal? body exp) val body)]
    [e (error 'replace-broke)]))

;; Who needs efficiency?!
(define (expand-buildfn exp)
  (match exp
    [`(concat’ ,xs)   (replace-exp 'xs (expand-buildfn xs) (-body -concat’))]
    [`(++’ ,xs ,ys)   (replace-exp 'ys (expand-buildfn ys)
                                   (replace-exp 'xs (expand-buildfn xs) (-body -++’)))]
    [`(map’ ,f ,xs)   (replace-exp 'f (expand-buildfn f)
                                   (replace-exp 'xs (expand-buildfn xs) (-body -map’)))]
    ;; God this is sickening.
    [`(cons’ ,x nil’) (replace-exp 'x x (-body -cons’-nil’))]
    [`(λ ,args ,body) `(λ ,(expand-buildfn args) ,(expand-buildfn body))]
    [e e]))

(eval (expand-buildfn `(concat’ '((a b c) (d e f)))) ns)
(eval (expand-buildfn `(++’ '(a b c) '(d e f))) ns)

;; Completely expand our implementation of `unlines`.
(pretty-print (expand-buildfn (libfn->buildfn `(flatten (map (λ (l) (append l '("\n"))) ls)))))

;; ^ Turn this into a macro. syntax-rules
(define-syntax-rule (define-rule var lhs rhs)
  (define (var exp)
    (match exp
        [lhs rhs]
        [(? list?) (map var exp)]
        [e e])))

(define-rule fold-build-rule `(((foldr ,k) ,z) (build ,g)) `((,g ,k) ,z))

;; Keep running until a fixed point using a list of rules iterating over them.
;; ^ May not always terminate.
