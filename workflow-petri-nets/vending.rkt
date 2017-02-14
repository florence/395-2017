#lang s-exp "lang.rkt"
#|
Vending machine with 15c and 20c bars
Excepts only exact change, in 5c and 10c coins

1 start state, with one control token
two transition for dispencing the two bars, that loop back to the start
|#
#:draw "dot"
#:places
start
c5
c10
c15
c20
#:transitions
d5-1
d5-2
d5-3
d5-4
d10-1
d10-2
d10-3
dispence-15c-bar
dispence-20c-bar
#:arcs
p:start -> t:d5-1
p:start -> t:d10-1

t:d5-1 -> p:c5
t:d10-1 -> p:c10

p:c5 -> t:d5-2
p:c5 -> t:d10-2

t:d5-2 -> p:c10
t:d10-2 -> p:c15

p:c10 -> t:d5-3
p:c10 -> t:d10-3

t:d5-3 -> p:c15
t:d10-3 -> p:c20

p:c15 -> t:d5-4
p:c15 -> t:dispence-15c-bar

t:d5-4 -> p:c20

p:c20 -> t:dispence-20c-bar

t:dispence-15c-bar -> p:start
t:dispence-20c-bar -> p:start







#:initials
1 * start
0 * c5
0 * c10
0 * c15
0 * c20
