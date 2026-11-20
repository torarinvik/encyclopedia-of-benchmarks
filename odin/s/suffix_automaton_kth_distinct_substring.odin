// Independently authored draft; not compiled or run.
package suffix_automaton_kth_distinct_substring
import "core:c"

@(export)
suffix_automaton_kth_distinct_substring :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 3 || length > 259 do return -1
    raw_n := input[0]
    k := input[1]
    if raw_n < 1 || raw_n > 256 || length != c.size_t(raw_n+2) || k < 1 do return -1
    n := int(raw_n)
    for i := 0; i < n; i += 1 { if input[i+2] < 0 || input[i+2] > 255 do return -1 }
    next: [131072]i32 = {}
    links, lengths: [512]i32
    paths: [512]i64 = {}
    for i := 0; i < len(next); i += 1 { next[i] = -1 }
    for i := 0; i < len(links); i += 1 { links[i] = -1; lengths[i] = 0 }
    count, last := 1, 0
    for i := 0; i < n; i += 1 {
        symbol := int(input[i+2]); current := count; count += 1
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
    buckets: [257]int = {}
    order: [512]int = {}
    for i := 0; i < count; i += 1 { buckets[int(lengths[i])] += 1 }
    for i := 1; i <= n; i += 1 { buckets[i] += buckets[i-1] }
    for i := count-1; i >= 0; i -= 1 {
        l := int(lengths[i]); buckets[l] -= 1; order[buckets[l]] = i
    }
    for i := count-1; i >= 0; i -= 1 {
        state := order[i]
        for c := 0; c < 256; c += 1 {
            target := int(next[state*256+c])
            if target >= 0 { paths[state] += 1 + paths[target] }
        }
    }
    if k > paths[0] do return -1
    result: [256]u8 = {}
    used, state := 0, 0
    for {
        found := false
        for c := 0; c < 256; c += 1 {
            target := int(next[state*256+c])
            if target < 0 do continue
            group := 1 + paths[target]
            if k > group { k -= group; continue }
            result[used] = u8(c); used += 1; state = target; found = true; break
        }
        if !found do return -1
        if k == 1 do break
        k -= 1
    }
    if output == nil || capacity < c.size_t(used) do return -2
    for i := 0; i < used; i += 1 { output[i] = result[i] }
    return i64(used)
}
