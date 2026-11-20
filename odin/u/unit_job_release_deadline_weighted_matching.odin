package unit_job_release_deadline_weighted_matching

import "core:c"

assign :: proc(job: int, starts, ends: ^[32]int, slots: ^[32]int, seen: ^[32]bool) -> bool {
    for slot := starts[job]; slot <= ends[job]; slot += 1 {
        if seen[slot] do continue
        seen[slot] = true
        old := slots[slot]
        if old < 0 || assign(old, starts, ends, slots, seen) {
            slots[slot] = job
            return true
        }
    }
    return false
}

@(export)
unit_job_release_deadline_weighted_matching :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 1 || length > 98 do return -1
    if input[0] < 0 || input[0] > 32 do return -1
    n := int(input[0])
    if length != c.size_t(1+3*n) do return -1
    starts, ends, order, slots: [32]int
    weights: [32]i64
    for i := 0; i < 32; i += 1 { slots[i] = -1 }
    for i := 0; i < n; i += 1 {
        r, d, w := input[1+3*i], input[2+3*i], input[3+3*i]
        if r < 0 || d < r || d >= 32 || w < 0 || w > 1000000 do return -1
        starts[i], ends[i], weights[i] = int(r), int(d), w
        j := i
        for j > 0 && weights[order[j-1]] < w { order[j] = order[j-1]; j -= 1 }
        order[j] = i
    }
    total := i64(0)
    for i := 0; i < n; i += 1 {
        seen: [32]bool = {}
        job := order[i]
        if assign(job, &starts, &ends, &slots, &seen) { total += weights[job] }
    }
    return total
}
