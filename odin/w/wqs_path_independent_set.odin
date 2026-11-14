// Uncompiled and unexecuted weighted-binary-search draft.
package wqs_path_independent_set
import "core:c"
State :: struct { score, count: i64 }
evaluate :: proc(input: [^]i64, n: int, penalty: i64) -> State {
    two, one := State{}, State{}
    for i := 0; i < n; i += 1 {
        take := State{two.score+input[2+i]-penalty, two.count+1}
        current := one
        if take.score > one.score || (take.score == one.score && take.count > one.count) { current = take }
        two = one; one = current
    }
    return one
}
@(export)
wqs_path_independent_set :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 130 { return -1000000000 }
    if input[0] < 0 || input[0] > 128 || input[1] < 0 || input[1] > (input[0]+1)/2 { return -1000000000 }
    n := int(input[0])
    if length != c.size_t(n+2) { return -1000000000 }
    for i := 0; i < n; i += 1 { if input[2+i] < -1000 || input[2+i] > 1000 { return -1000000000 } }
    low, high := i64(-256001), i64(256001)
    for low < high {
        middle := low+(high-low+1)/2
        if evaluate(input, n, middle).count >= input[1] { low = middle } else { high = middle-1 }
    }
    return evaluate(input, n, low).score+low*input[1]
}
