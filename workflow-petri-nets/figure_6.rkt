#lang s-exp "lang.rkt"
#:draw "dot"
#:no-scale
#:places
i c1 c2 c3 c4 c5 c6 c7 c8 c9 o
#:transitions
register
send_questionaire
evaluate
time_out
process_questionaire
archive
no_processing
processing_required
process_complaint
check_processing
processing_NOK
processing_OK
#:arcs
p:i -> t:register

t:register -> p:c1
p:c1 -> t:send_questionaire
t:send_questionaire -> p:c3
p:c3 -> t:time_out
p:c3 -> t:process_questionaire
p:c5 <- t:time_out
p:c5 <- t:process_questionaire
p:c5 -> t:archive
p:c5 -> t:process_complaint

t:register -> p:c2
p:c2 -> t:evaluate
p:c4 <- t:evaluate

p:c4 -> t:no_processing
p:no_processing -> t:c6
t:c6 -> p:archive

p:c4 -> t:processing_required
p:c7 <- t:processing_required
p:c7 -> t:process_complaint
p:c5 <- t:process_complaint
p:c8 <- t:process_complaint
p:c8 -> t:check_processing
p:c9 <- t:check_processing

p:c9 -> t:processing_OK
p:c6 <- t:processing_OK

p:c9 -> t:processing_NOK
p:c7 <- t:processing_NOK

t:archive -> p:o
#:initials
1 * i
0 * c1
0 * c2
0 * c3
0 * c4
0 * c5
0 * c6
0 * c7
0 * c8
0 * c9
0 * o
