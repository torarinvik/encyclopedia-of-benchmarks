package random_3sat_greedy_dpll
import "core:c"

MAX_VARS :: 12
MAX_CLAUSES :: 32
MAX_INPUT :: 98
MAX_OUTPUT :: 104

put_i64 :: proc(out: [^]u8, at: int, value: i64) {
    bits := u64(value)
    for i := 0; i < 8; i += 1 { out[at+i] = u8(bits & 255); bits >>= 8 }
}

@(export)
random_3sat_greedy_dpll :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT || input[0] < 3 || input[0] > MAX_VARS || input[1] < 0 || input[1] > MAX_CLAUSES { return -1 }
    n, m := int(input[0]), int(input[1])
    if length != c.size_t(2+3*m) { return -1 }
    clauses: [MAX_CLAUSES][3]int
    lens: [MAX_CLAUSES]int
    active: [MAX_CLAUSES]bool
    for i := 0; i < m; i += 1 {
        seen: [MAX_VARS]bool
        for j := 0; j < 3; j += 1 {
            lit := input[2+3*i+j]
            if lit == 0 || lit < -i64(n) || lit > i64(n) { return -1 }
            v := int(abs(lit))-1
            if seen[v] { return -1 }
            seen[v] = true
            clauses[i][j] = int(lit)
        }
        lens[i] = 3
        active[i] = true
    }
    assigned: [MAX_VARS]int
    success, failed := false, false
    for step := 0; step < n && !failed; step += 1 {
        remaining := 0
        for i := 0; i < m; i += 1 { if active[i] { remaining += 1 } }
        if remaining == 0 { success = true; break }
        chosen := 0
        for i := 0; i < m; i += 1 { if chosen == 0 && active[i] && lens[i] == 1 { chosen = clauses[i][0] } }
        if chosen == 0 {
            counts: [2*MAX_VARS]int
            for i := 0; i < m; i += 1 {
                if active[i] { for j := 0; j < lens[i]; j += 1 { lit := clauses[i][j]; v := int(abs(lit))-1; sign := 0; if lit < 0 { sign = 1 }; counts[2*v+sign] += 1 } }
            }
            best := 0
            for v := 0; v < n; v += 1 { for sign := 0; sign < 2; sign += 1 { count := counts[2*v+sign]; if count > best { best = count; chosen = v+1; if sign == 1 { chosen = -(v+1) } } } }
        }
        if chosen == 0 { failed = true; break }
        variable := int(abs(chosen))-1
        if chosen > 0 { assigned[variable] = 1 } else { assigned[variable] = -1 }
        for i := 0; i < m; i += 1 {
            if active[i] {
                satisfied := false
                for j := 0; j < lens[i]; j += 1 { if clauses[i][j] == chosen { satisfied = true } }
                if satisfied { active[i] = false; continue }
                write := 0
                for j := 0; j < lens[i]; j += 1 { if clauses[i][j] != -chosen { clauses[i][write] = clauses[i][j]; write += 1 } }
                lens[i] = write
                if write == 0 { failed = true; break }
            }
        }
    }
    if !failed { remaining := 0; for i := 0; i < m; i += 1 { if active[i] { remaining += 1 } }; success = remaining == 0 }
    if success { for i := 0; i < n; i += 1 { if assigned[i] == 0 { assigned[i] = -1 } } }
    bytes := 8*(n+1)
    if output == nil || capacity < c.size_t(bytes) { return -2 }
    staged: [MAX_OUTPUT]u8
    verdict: i64 = 0; if success { verdict = 1 }
    put_i64(&staged[0], 0, verdict)
    for i := 0; i < n; i += 1 { put_i64(&staged[0], 8*(i+1), i64(assigned[i])) }
    for i := 0; i < bytes; i += 1 { output[i] = staged[i] }
    return i64(bytes)
}
