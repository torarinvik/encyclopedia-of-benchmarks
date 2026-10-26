// Clean-room bounded GBBS approximate set-cover profile; see package MIT notice.
package gbbs_approximate_set_cover

import "core:c"

store_le :: proc(out: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for i := 0; i < 8; i += 1 { out[offset+i] = u8(bits & 255); bits >>= 8 }
}

@(export)
gbbs_approximate_set_cover :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 10 do return -1
    ns64 := input[0]
    if ns64 < 1 || ns64 > 8 do return -1
    ns, ne := int(ns64), int(ns64)
    if int(length) != 1 + ns do return -1
    valid := u16((1 << ne) - 1)
    sets: [8]u16
    for s := 0; s < ns; s += 1 {
        if input[1+s] < 0 || (u64(input[1+s]) & ~u64(valid)) != 0 do return -1
        sets[s] = u16(input[1+s])
        if (sets[s] & u16(1 << s)) != 0 do return -1
    }
    for u := 0; u < ns; u += 1 {
        for v := 0; v < ns; v += 1 {
            if ((sets[u] >> v) & 1) != ((sets[v] >> u) & 1) do return -1
        }
    }
    if output == nil || capacity < 16 do return -2
    uncovered, selected := valid, u16(0)
    bucket: [8]int
    for s := 0; s < ns; s += 1 {
        bits := sets[s]
        for bits != 0 { bits &= bits - 1; bucket[s] += 1 }
    }
    round := 0
    for uncovered != 0 {
        degree: [8]int
        top := 0
        for s := 0; s < ns; s += 1 { if bucket[s] > top do top = bucket[s] }
        if top == 0 do break
        eligible: [8]bool
        eligible_count := 0
        for s := 0; s < ns; s += 1 {
            if bucket[s] == top {
                bits := sets[s] & uncovered
                for bits != 0 { bits &= bits - 1; degree[s] += 1 }
                bucket[s] = degree[s]
                eligible[s] = degree[s] >= top
                if eligible[s] do eligible_count += 1
            }
        }
        priority: [8]int
        priority_count := 0
        for r := 0; r < ns; r += 1 {
            s := (round + r) % ns
            if eligible[s] { priority[priority_count] = s; priority_count += 1 }
        }
        wins: [8]int
        for e := 0; e < ne; e += 1 {
            bit := u16(1 << e)
            if (uncovered & bit) == 0 do continue
            for r := 0; r < priority_count; r += 1 {
                s := priority[r]
                if (sets[s] & bit) != 0 { wins[s] += 1; break }
            }
        }
        round_cover := u16(0)
        for s := 0; s < ns; s += 1 {
            if eligible[s] && wins[s] >= top do round_cover |= u16(1 << s)
        }
        if round_cover == 0 && eligible_count != 0 do return -1
        selected |= round_cover
        covered := u16(0)
        for s := 0; s < ns; s += 1 { if (round_cover & u16(1 << s)) != 0 do covered |= sets[s] }
        uncovered &= ~covered
        for s := 0; s < ns; s += 1 { if (round_cover & u16(1 << s)) != 0 do bucket[s] = 0 }
        round += 1
    }
    store_le(output, 0, i64(selected))
    store_le(output, 8, i64(uncovered))
    return 16
}
