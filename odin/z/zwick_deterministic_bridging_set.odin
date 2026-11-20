package z

import "core:c"

MAX_N :: 8
INF_DIST :: u8(9)

State :: struct {
    n, threshold: int,
    edge, witness, distance: [64]u8,
    constraints: [64]u16,
    constraint_count: int,
}

Prefix :: struct { values: [8]u8, count: int }

popcount16 :: proc(mask: u16) -> int {
    value := mask
    count := 0
    for value != 0 { count += int(value & 1); value >>= 1 }
    return count
}

subpath :: proc(state: ^State, from: int, to: int, limit: int) -> Prefix {
    result: Prefix = {}
    if limit <= 0 || state.witness[from*state.n+to] == 0 do return result
    middle := int(state.witness[from*state.n+to]) - 1
    left := subpath(state, from, middle, limit-1)
    result = left
    result.values[result.count] = u8(middle)
    result.count += 1
    remaining := limit-result.count
    if remaining > 0 {
        right := subpath(state, middle, to, remaining)
        for i in 0..<right.count {
            result.values[result.count] = right.values[i]
            result.count += 1
        }
    }
    return result
}

@(export)
zwick_deterministic_bridging_set :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 131 do return -1
    if input[0] < 2 || input[0] > MAX_N do return -1
    n := int(input[0])
    if input[1] < 2 || input[1] > i64(n) || int(length) != 2+2*n*n do return -1
    state: State = {n=n, threshold=int(input[1])}
    matrix := n*n
    for i in 0..<matrix {
        if input[2+i] < 0 || input[2+i] > 1 || input[2+matrix+i] < 0 || input[2+matrix+i] > i64(n) do return -1
        state.edge[i] = u8(input[2+i])
        state.witness[i] = u8(input[2+matrix+i])
    }
    for i in 0..<n {
        if state.edge[i*n+i] != 0 do return -1
        for j in 0..<n {
            state.distance[i*n+j] = if i == j do 0 else if state.edge[i*n+j] != 0 do 1 else INF_DIST
        }
    }
    for k in 0..<n do for i in 0..<n do for j in 0..<n {
        candidate := int(state.distance[i*n+k]) + int(state.distance[k*n+j])
        if candidate < int(state.distance[i*n+j]) do state.distance[i*n+j] = u8(candidate)
    }
    for i in 0..<n do for j in 0..<n {
        d := int(state.distance[i*n+j])
        w := int(state.witness[i*n+j])
        if d >= int(INF_DIST) do return -1
        if d <= 1 {
            if w != 0 do return -1
        } else {
            if w == 0 do return -1
            v := w-1
            if v == i || v == j do return -1
            left, right := int(state.distance[i*n+v]), int(state.distance[v*n+j])
            if left+right != d || left >= d || right >= d do return -1
        }
    }
    for i in 0..<n do for j in 0..<n {
        prefix := subpath(&state, i, j, state.threshold)
        mask := (u16(1)<<i) | (u16(1)<<j)
        for k in 0..<prefix.count do mask |= u16(1)<<prefix.values[k]
        if popcount16(mask) >= state.threshold {
            duplicate := false
            for cidx in 0..<state.constraint_count do if state.constraints[cidx] == mask do duplicate = true
            if !duplicate {
                state.constraints[state.constraint_count] = mask
                state.constraint_count += 1
            }
        }
    }
    unhit: [64]bool = {}
    for i in 0..<state.constraint_count do unhit[i] = true
    remaining := state.constraint_count
    selected: u16 = 0
    for remaining > 0 {
        best_vertex, best_score := 0, 0
        for v in 0..<n {
            score := 0
            for cidx in 0..<state.constraint_count {
                if unhit[cidx] && state.constraints[cidx] & (u16(1)<<v) != 0 do score += 1
            }
            if score > best_score { best_vertex, best_score = v, score }
        }
        if best_score == 0 do return -1
        selected |= u16(1)<<best_vertex
        for cidx in 0..<state.constraint_count {
            if unhit[cidx] && state.constraints[cidx] & (u16(1)<<best_vertex) != 0 {
                unhit[cidx] = false
                remaining -= 1
            }
        }
    }
    return i64(selected)
}
