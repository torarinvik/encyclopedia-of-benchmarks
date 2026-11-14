package longest_common_substring_sam
import "core:c"

@(export)
longest_common_substring_sam :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 515 || input[0] < 0 || input[0] > 256 do return -1
    n := int(input[0])
    if length < c.size_t(n+2) || input[n+1] < 0 || input[n+1] > 256 do return -1
    m := int(input[n+1])
    if length != c.size_t(n+m+2) do return -1
    for i := 0; i < n; i += 1 do if input[1+i] < 32 || input[1+i] > 126 do return -1
    for i := 0; i < m; i += 1 do if input[n+2+i] < 32 || input[n+2+i] > 126 do return -1
    edges: [513][95]i32; links: [513]i32; lens: [513]int
    for s := 0; s < 513; s += 1 { links[s] = -1; for a := 0; a < 95; a += 1 do edges[s][a] = -1 }
    size, last := 1, 0
    for i := 0; i < n; i += 1 {
        symbol := int(input[1+i])-32; current := size; size += 1; lens[current] = lens[last]+1; p := last
        for p >= 0 && edges[p][symbol] < 0 { edges[p][symbol] = i32(current); p = int(links[p]) }
        if p < 0 { links[current] = 0 } else {
            q := int(edges[p][symbol])
            if lens[p]+1 == lens[q] { links[current] = i32(q) } else {
                clone := size; size += 1; edges[clone] = edges[q]; links[clone] = links[q]; lens[clone] = lens[p]+1
                for p >= 0 && edges[p][symbol] == i32(q) { edges[p][symbol] = i32(clone); p = int(links[p]) }
                links[q] = i32(clone); links[current] = i32(clone)
            }
        }
        last = current
    }
    state, matched, best := 0, 0, 0
    for i := 0; i < m; i += 1 {
        symbol := int(input[n+2+i])-32
        for state != 0 && edges[state][symbol] < 0 { state = int(links[state]); matched = lens[state] }
        next := int(edges[state][symbol])
        if next < 0 { state = 0; matched = 0 } else { state = next; matched += 1; if matched > best do best = matched }
    }
    return i64(best)
}
