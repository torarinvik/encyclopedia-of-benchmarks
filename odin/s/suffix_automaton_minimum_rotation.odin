// Uncompiled suffix-automaton minimum-rotation draft.
package suffix_automaton_minimum_rotation
import "core:c"
@(export)
suffix_automaton_minimum_rotation :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 258 do return -1
    raw_n := input[0]
    if raw_n < 1 || raw_n > 256 || length != c.size_t(raw_n+1) do return -1
    n := int(raw_n)
    for i := 1; i < int(length); i += 1 { if input[i] < 0 || input[i] > 255 do return -1 }
    if output == nil || capacity < c.size_t(n) do return -2
    next: [262144]i32 = {}
    links, lengths: [1024]i32
    for i := 0; i < len(next); i += 1 { next[i] = -1 }
    for i := 0; i < len(links); i += 1 { links[i] = -1; lengths[i] = 0 }
    count, last := 1, 0
    for i := 0; i < 2*n; i += 1 {
        symbol := int(input[1+i%n]); current := count; count += 1
        lengths[current] = lengths[last]+1
        p := last
        for p >= 0 && next[p*256+symbol] < 0 {
            next[p*256+symbol] = i32(current); p = int(links[p])
        }
        if p < 0 { links[current] = 0 } else {
            q := int(next[p*256+symbol])
            if lengths[p]+1 == lengths[q] { links[current] = i32(q) } else {
                clone := count; count += 1
                for c := 0; c < 256; c += 1 { next[clone*256+c] = next[q*256+c] }
                links[clone] = links[q]; lengths[clone] = lengths[p]+1
                for p >= 0 && next[p*256+symbol] == i32(q) {
                    next[p*256+symbol] = i32(clone); p = int(links[p])
                }
                links[q] = i32(clone); links[current] = i32(clone)
            }
        }
        last = current
    }
    state := 0
    for i := 0; i < n; i += 1 {
        symbol := 0
        for next[state*256+symbol] < 0 { symbol += 1 }
        output[i] = u8(symbol); state = int(next[state*256+symbol])
    }
    return raw_n
}
