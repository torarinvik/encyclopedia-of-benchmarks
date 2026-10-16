package double_hash_hash_table

import "core:c"

@(export)
double_hash_hash_table :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if length < 2 do return -1
    cap64 := input[0]
    count := input[1]
    if cap64 < 3 || cap64 > 101 || count < 0 || count > 512 do return -1
    cap := int(cap64)
    if length != c.size_t(2 + 2 * count) do return -1
    for d := 2; d * d <= cap; d += 1 { if cap % d == 0 do return -1 }
    states: [101]u8
    keys: [101]i64
    successes: i64 = 0
    for i := 0; i < int(count); i += 1 {
        op := input[2 + 2 * i]
        key := input[3 + 2 * i]
        if op < 1 || op > 3 do return -1
        first_rem := key % cap64
        if first_rem < 0 do first_rem += cap64
        first := int(first_rem)
        step_rem := key % (cap64 - 1)
        if step_rem < 0 do step_rem += cap64 - 1
        step := 1 + int(step_rem)
        if op == 1 {
            tomb := cap
            inserted := false
            for p := 0; p < cap; p += 1 {
                slot := (first + p * step) % cap
                if states[slot] == 1 && keys[slot] == key { tomb = cap; break }
                if states[slot] == 2 && tomb == cap do tomb = slot
                if states[slot] == 0 {
                    target := slot
                    if tomb != cap do target = tomb
                    states[target] = 1
                    keys[target] = key
                    inserted = true
                    break
                }
            }
            if !inserted && tomb != cap {
                states[tomb] = 1
                keys[tomb] = key
                inserted = true
            }
            if inserted do successes += 1
        } else {
            for p := 0; p < cap; p += 1 {
                slot := (first + p * step) % cap
                if states[slot] == 0 do break
                if states[slot] == 1 && keys[slot] == key {
                    successes += 1
                    if op == 3 do states[slot] = 2
                    break
                }
            }
        }
    }
    return successes
}
