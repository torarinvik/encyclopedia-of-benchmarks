package chan_output_sensitive_hull

import "core:c"

// Unverified Chan hull draft; no compiler or benchmark has run.
turn :: proc "contextless" (x, y: []i64, a, b, d: int) -> i64 {
    return (x[b]-x[a])*(y[d]-y[a]) - (y[b]-y[a])*(x[d]-x[a])
}
less :: proc "contextless" (x, y: []i64, a, b: int) -> bool {
    return x[a] < x[b] || (x[a] == x[b] && y[a] < y[b])
}
group_hull :: proc "contextless" (x, y: []i64, begin, count: int, out: []int) -> int {
    order, scratch: [32]int
    chain: [64]int
    for i := 0; i < count; i += 1 { order[i] = begin+i }
    for width := 1; width < count; width *= 2 {
        for block := 0; block < count; block += 2*width {
            middle := min(block+width, count)
            end := min(block+2*width, count)
            left, right, dest := block, middle, block
            for left < middle && right < end {
                if less(x, y, order[right], order[left]) { scratch[dest] = order[right]; right += 1
                } else { scratch[dest] = order[left]; left += 1 }
                dest += 1
            }
            for left < middle { scratch[dest] = order[left]; left += 1; dest += 1 }
            for right < end { scratch[dest] = order[right]; right += 1; dest += 1 }
        }
        for i := 0; i < count; i += 1 { order[i] = scratch[i] }
    }
    if count == 1 { out[0] = order[0]; return 1 }
    used := 0
    for i := 0; i < count; i += 1 {
        for used >= 2 && turn(x, y, chain[used-2], chain[used-1], order[i]) <= 0 { used -= 1 }
        chain[used] = order[i]; used += 1
    }
    lower := used
    for i := count-1; i > 0; {
        i -= 1
        for used > lower && turn(x, y, chain[used-2], chain[used-1], order[i]) <= 0 { used -= 1 }
        chain[used] = order[i]; used += 1
    }
    used -= 1
    for i := 0; i < used; i += 1 { out[i] = chain[i] }
    return used
}
tangent :: proc "contextless" (x, y: []i64, hull: []int, query: int) -> int {
    n := len(hull)
    if n == 1 do return hull[0]
    if n == 2 {
        if turn(x, y, query, hull[0], hull[1]) > 0 do return hull[0]
        return hull[1]
    }
    initial_up := turn(x, y, query, hull[0], hull[1]) > 0
    lo, hi := 0, n
    for lo < hi {
        mid := lo + (hi-lo)/2
        before := turn(x, y, query, hull[mid], hull[(mid+n-1)%n]) > 0
        after := turn(x, y, query, hull[mid], hull[(mid+1)%n]) > 0
        if before && after do return hull[mid]
        below := mid != 0 && turn(x, y, query, hull[mid], hull[0]) > 0
        above := mid != 0 && turn(x, y, query, hull[0], hull[mid]) > 0
        search_left := after || above
        if initial_up do search_left = after && below
        if search_left { hi = mid } else { lo = mid+1 }
    }
    return -1
}

@(export)
chan_output_sensitive_hull :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 7 || length > 66 || input[0] < 3 || input[0] > 32 do return -1
    n := int(input[0])
    if int(length) != 1+2*n do return -1
    x, y: [32]i64
    for i := 0; i < n; i += 1 {
        x[i] = input[1+2*i]; y[i] = input[2+2*i]
        if x[i] < -1000 || x[i] > 1000 || y[i] < -1000 || y[i] > 1000 do return -1
        for j := 0; j < i; j += 1 { if x[i] == x[j] && y[i] == y[j] do return -1 }
    }
    for i := 0; i < n; i += 1 {
        for j := i+1; j < n; j += 1 {
            for k := j+1; k < n; k += 1 { if turn(x[:], y[:], i, j, k) == 0 do return -1 }
        }
    }
    start := 0
    for i := 1; i < n; i += 1 { if less(x[:], y[:], i, start) do start = i }
    guess := min(4, n)
    for {
        hulls, offsets, sizes, group_of, position: [32]int
        groups, stored, begin := 0, 0, 0
        for begin < n {
            end := min(n, begin+guess)
            offsets[groups] = stored
            sizes[groups] = group_hull(x[:], y[:], begin, end-begin, hulls[stored:])
            for i := begin; i < end; i += 1 { group_of[i] = groups; position[i] = -1 }
            for i := 0; i < sizes[groups]; i += 1 { position[hulls[stored+i]] = i }
            stored += sizes[groups]; groups += 1; begin = end
        }
        result: [32]int
        result[0] = start
        used := 1
        for step := 0; step < guess; step += 1 {
            current, candidate := result[used-1], -1
            for g := 0; g < groups; g += 1 {
                local := -1
                if g == group_of[current] {
                    if position[current] < 0 do return -1
                    if sizes[g] > 1 do local = hulls[offsets[g]+(position[current]+1)%sizes[g]]
                } else {
                    local = tangent(x[:], y[:], hulls[offsets[g]:offsets[g]+sizes[g]], current)
                    if local < 0 do return -1
                }
                if local >= 0 && (candidate < 0 || turn(x[:], y[:], current, candidate, local) < 0) do candidate = local
            }
            if candidate < 0 do return -1
            if candidate == start {
                bytes := 16*used
                if output == nil || int(capacity) < bytes do return -2
                for i := 0; i < used; i += 1 {
                    fields := [2]u64{u64(x[result[i]]), u64(y[result[i]])}
                    for axis := 0; axis < 2; axis += 1 {
                        for b := 0; b < 8; b += 1 { output[16*i+8*axis+b] = u8(fields[axis] >> u64(8*b)) }
                    }
                }
                return i64(bytes)
            }
            if used == n do return -1
            result[used] = candidate; used += 1
        }
        if guess == n do return -1
        guess = min(n, guess*guess)
    }
}
