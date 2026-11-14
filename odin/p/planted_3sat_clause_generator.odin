package planted_3sat_clause_generator

import "core:c"

// Unverified deterministic planted 3-SAT generator draft.
@(export)
planted_3sat_clause_generator :: proc "c" (input: [^]i64, length: c.size_t,
                                           output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 5 || length > 83 || input[0] < 3 || input[0] > 16 || input[1] < 0 || input[1] > 32 do return -1
    n, m := int(input[0]), int(input[1])
    if int(length) != 2+n+2*m do return -1
    for i := 0; i < n; i += 1 { if input[2+i] != 0 && input[2+i] != 1 do return -1 }
    choices := n*(n-1)*(n-2)/6
    literals: [96]i64
    for clause := 0; clause < m; clause += 1 {
        raw, mask := input[2+n+2*clause], input[3+n+2*clause]
        if raw < 0 || raw >= i64(choices) || mask < 1 || mask > 7 do return -1
        rank, next := int(raw), 0
        for position := 0; position < 3; position += 1 {
            for variable := next; variable < n-(2-position); variable += 1 {
                remaining := n-variable-1
                ways := 1
                if position == 0 { ways = remaining*(remaining-1)/2
                } else if position == 1 { ways = remaining }
                if rank >= ways { rank -= ways; continue }
                value := i64(variable+1)
                if input[2+variable] == ((mask >> u64(position)) & 1) {
                    literals[3*clause+position] = value
                } else { literals[3*clause+position] = -value }
                next = variable+1
                break
            }
        }
    }
    bytes := 24*m
    if bytes == 0 do return 0
    if output == nil || capacity < c.size_t(bytes) do return -2
    for i := 0; i < 3*m; i += 1 {
        bits := u64(literals[i])
        for b := 0; b < 8; b += 1 { output[8*i+b] = u8(bits >> u64(8*b)) }
    }
    return i64(bytes)
}
