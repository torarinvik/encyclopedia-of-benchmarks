module double_hash_hash_table

@[export: 'double_hash_hash_table']
pub fn double_hash_hash_table(input &i64, length usize) i64 {
    if length < 2 { return -1 }
    cap64 := unsafe { input[0] }
    count := unsafe { input[1] }
    if cap64 < 3 || cap64 > 101 || count < 0 || count > 512 { return -1 }
    cap := int(cap64)
    if length != usize(2 + 2 * count) { return -1 }
    for d := 2; d * d <= cap; d++ { if cap % d == 0 { return -1 } }
    mut states := [101]u8{init: 0}
    mut keys := [101]i64{init: 0}
    mut successes := i64(0)
    for i in 0 .. int(count) {
        op := unsafe { input[2 + 2 * i] }
        key := unsafe { input[3 + 2 * i] }
        if op < 1 || op > 3 { return -1 }
        first := int((key % cap64 + cap64) % cap64)
        step := 1 + int((key % (cap64 - 1) + cap64 - 1) % (cap64 - 1))
        if op == 1 {
            mut tomb := cap
            mut inserted := false
            for p in 0 .. cap {
                slot := (first + p * step) % cap
                if states[slot] == 1 && keys[slot] == key { tomb = cap; break }
                if states[slot] == 2 && tomb == cap { tomb = slot }
                if states[slot] == 0 {
                    target := if tomb == cap { slot } else { tomb }
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
            if inserted { successes++ }
        } else {
            for p in 0 .. cap {
                slot := (first + p * step) % cap
                if states[slot] == 0 { break }
                if states[slot] == 1 && keys[slot] == key {
                    successes++
                    if op == 3 { states[slot] = 2 }
                    break
                }
            }
        }
    }
    return successes
}
