package random_3sat_hajiaghayi_sorkin_algorithm_a
import "core:c"

MAX_VARS :: 12
MAX_CLAUSES :: 32
MAX_INPUT :: 98
MAX_OUTPUT :: 104

put_i64 :: proc(out: [^]u8, at: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 { out[at+byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
random_3sat_hajiaghayi_sorkin_algorithm_a :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT || input[0] < 3 || input[0] > MAX_VARS || input[1] < 0 || input[1] > MAX_CLAUSES { return -1 }
    n, m := int(input[0]), int(input[1])
    if length != c.size_t(2+3*m) { return -1 }
    clauses: [MAX_CLAUSES][3]int
    lens: [MAX_CLAUSES]int
    active: [MAX_CLAUSES]bool
    for clause := 0; clause < m; clause += 1 {
        seen: [MAX_VARS]bool
        for at := 0; at < 3; at += 1 {
            raw := input[2+3*clause+at]
            if raw == 0 || raw < -i64(n) || raw > i64(n) { return -1 }
            variable := int(abs(raw))-1
            if seen[variable] { return -1 }
            seen[variable] = true
            clauses[clause][at] = int(raw)
        }
        lens[clause] = 3
        active[clause] = true
    }
    assigned: [MAX_VARS]int
    assigned_count := 0
    failed := false
    for assigned_count < n && !failed {
        positive: [MAX_VARS]int
        negative: [MAX_VARS]int
        for clause := 0; clause < m; clause += 1 {
            if active[clause] {
                for at := 0; at < lens[clause]; at += 1 {
                    literal := clauses[clause][at]
                    variable := int(abs(literal))-1
                    if literal > 0 { positive[variable] += 1 } else { negative[variable] += 1 }
                }
            }
        }
        chosen_variable := -1
        for variable := 0; variable < n; variable += 1 {
            if assigned[variable] == 0 && (positive[variable] == 0 || negative[variable] == 0) { chosen_variable = variable; break }
        }
        if chosen_variable < 0 {
            best_difference, best_total := -1, -1
            for variable := 0; variable < n; variable += 1 {
                if assigned[variable] != 0 { continue }
                difference := positive[variable]-negative[variable]
                if difference < 0 { difference = -difference }
                total := positive[variable]+negative[variable]
                if difference > best_difference || (difference == best_difference && total > best_total) {
                    best_difference, best_total, chosen_variable = difference, total, variable
                }
            }
        }
        if chosen_variable < 0 { failed = true; break }
        chosen := -(chosen_variable+1)
        if positive[chosen_variable] < negative[chosen_variable] { chosen = chosen_variable+1 }
        assigned[chosen_variable] = 1
        if chosen < 0 { assigned[chosen_variable] = -1 }
        assigned_count += 1
        unit_phase := true
        for unit_phase {
            for clause := 0; clause < m && !failed; clause += 1 {
                if active[clause] {
                    satisfied := false
                    for at := 0; at < lens[clause]; at += 1 { if clauses[clause][at] == chosen { satisfied = true } }
                    if satisfied { active[clause] = false; continue }
                    write := 0
                    for at := 0; at < lens[clause]; at += 1 { if clauses[clause][at] != -chosen { clauses[clause][write] = clauses[clause][at]; write += 1 } }
                    lens[clause] = write
                    if write == 0 { failed = true }
                }
            }
            if failed { break }
            chosen = 0
            for clause := 0; clause < m; clause += 1 { if chosen == 0 && active[clause] && lens[clause] == 1 { chosen = clauses[clause][0] } }
            if chosen == 0 { unit_phase = false } else {
                variable := int(abs(chosen))-1
                assigned[variable] = 1
                if chosen < 0 { assigned[variable] = -1 }
                assigned_count += 1
            }
        }
    }
    bytes := 8*(n+1)
    if output == nil || capacity < c.size_t(bytes) { return -2 }
    staged: [MAX_OUTPUT]u8
    verdict: i64 = 1
    if failed { verdict = 0 }
    put_i64(&staged[0], 0, verdict)
    for variable := 0; variable < n; variable += 1 { put_i64(&staged[0], 8*(variable+1), i64(assigned[variable])) }
    for byte := 0; byte < bytes; byte += 1 { output[byte] = staged[byte] }
    return i64(bytes)
}
