package shortest_absent_substring_sam
import "core:c"

@(export)
shortest_absent_substring_sam :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 66 do return -1
    if input[0] < 2 || input[0] > 4 || input[1] < 0 || input[1] > 64 do return -1
    alphabet, n := int(input[0]), int(input[1])
    if length != c.size_t(2+n) do return -1
    for i := 0; i < n; i += 1 do if input[2+i] < 0 || input[2+i] >= i64(alphabet) do return -1
    edges: [129][4]int; links, lens: [129]int
    for s := 0; s < 129; s += 1 { links[s] = -1; for a := 0; a < 4; a += 1 do edges[s][a] = -1 }
    size, last := 1, 0
    for i := 0; i < n; i += 1 {
        symbol := int(input[2+i]); current := size; size += 1; lens[current] = lens[last]+1; p := last
        for p >= 0 && edges[p][symbol] < 0 { edges[p][symbol] = current; p = links[p] }
        if p < 0 { links[current] = 0 } else {
            q := edges[p][symbol]
            if lens[p]+1 == lens[q] { links[current] = q } else {
                clone := size; size += 1; edges[clone] = edges[q]; links[clone] = links[q]; lens[clone] = lens[p]+1
                for p >= 0 && edges[p][symbol] == q { edges[p][symbol] = clone; p = links[p] }
                links[q] = clone; links[current] = clone
            }
        }
        last = current
    }
    counts: [65]int; order, dp: [129]int
    for s := 0; s < size; s += 1 do counts[lens[s]] += 1
    for i := 1; i <= n; i += 1 do counts[i] += counts[i-1]
    for s := size-1; s >= 0; s -= 1 { counts[lens[s]] -= 1; order[counts[lens[s]]] = s }
    for i := size-1; i >= 0; i -= 1 {
        s := order[i]; best := 100
        for a := 0; a < alphabet; a += 1 {
            child := edges[s][a]; candidate := 1
            if child >= 0 do candidate += dp[child]
            if candidate < best do best = candidate
        }
        dp[s] = best
    }
    result: [6]u8; count, state := 0, 0
    for state >= 0 {
        for a := 0; a < alphabet; a += 1 {
            child := edges[state][a]; eligible := child < 0 && dp[state] == 1
            if child >= 0 do eligible = dp[state] == 1+dp[child]
            if eligible { result[count] = u8(a); count += 1; state = child; break }
        }
    }
    if output == nil || capacity < c.size_t(count) do return -2
    for i := 0; i < count; i += 1 do output[i] = result[i]
    return i64(count)
}
