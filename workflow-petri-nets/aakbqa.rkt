#lang s-exp "lang.rkt"
#:draw "dot"
#:places
start
middle/await
middle/final
good
bad
path1
path2
path3
#:transitions
start-paths
a
a*
b
a2
a3
else1
else2
else3
#:arcs
p:start -> t:start-paths
t:start-paths -> p:path1
t:start-paths -> p:path2
t:start-paths -> p:path3
p:path1 -> t:a
p:path2 -> t:a3
p:path3 -> t:else1

t:a -> p:middle/await

p:middle/await -> t:a*
p:middle/await -> t:else2
p:middle/await -> t:b

t:a* -> p:middle/await

t:b -> p:middle/final

p:middle/final -> t:a2
p:middle/final -> t:else3

t:a3 -> p:good
t:a2 -> p:good
t:b -> p:good

t:else1 -> p:bad
t:else2 -> p:bad
t:else3 -> p:bad

#:initials
1 * start
0 * good
0 * bad
0 * middle/await
0 * middle/final
0 * path1
0 * path2
0 * path3
