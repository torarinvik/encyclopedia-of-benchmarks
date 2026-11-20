package bench

HS_SLOTS :: 16
HS_H :: 4
HS_MAX_OPS :: 32
HS_MAX_WORDS :: 1 + 3 * HS_MAX_OPS

hs_distance :: proc(from, to: int) -> int {
    return (to - from + HS_SLOTS) % HS_SLOTS
}

hs_contains :: proc(keys: [^]i16, hops: [^]u8, key, home: int) -> bool {
    for offset in 0..<HS_H {
        if (hops[home] & (u8(1) << offset)) != 0 &&
            keys[(home + offset) % HS_SLOTS] == i16(key) { return true }
    }
    return false
}

hs_insert :: proc(keys: [^]i16, homes: [^]u8, hops: [^]u8,
                  key, home: int) -> u8 {
    if hs_contains(keys, hops, key, home) { return 2 }
    hole := -1
    for step in 0..<HS_SLOTS {
        slot := (home + step) % HS_SLOTS
        if keys[slot] < 0 { hole = slot; break }
    }
    if hole < 0 { return 0 }
    reach := hs_distance(home, hole)
    for reach >= HS_H {
        shifted := false
        for back := HS_H - 1; back > 0 && !shifted; back -= 1 {
            bucket := (hole - back + HS_SLOTS) % HS_SLOTS
            new_offset := hs_distance(bucket, hole)
            if hs_distance(home, bucket) >= reach { continue }
            for old_offset in 0..<new_offset {
                if (hops[bucket] & (u8(1) << old_offset)) == 0 { continue }
                old_slot := (bucket + old_offset) % HS_SLOTS
                if keys[old_slot] < 0 || int(homes[old_slot]) != bucket ||
                    hs_distance(home, old_slot) >= reach { continue }
                keys[hole] = keys[old_slot]
                homes[hole] = homes[old_slot]
                keys[old_slot] = -1
                homes[old_slot] = 0
                hops[bucket] = hops[bucket] & ~(u8(1) << old_offset)
                hops[bucket] = hops[bucket] | (u8(1) << new_offset)
                hole = old_slot
                reach = hs_distance(home, hole)
                shifted = true
                break
            }
            if shifted { break }
        }
        if !shifted { return 0 }
    }
    keys[hole] = i16(key)
    homes[hole] = u8(home)
    hops[home] = hops[home] | (u8(1) << reach)
    return 1
}

@(export)
hash_map_hopscotch_hashing :: proc "c" (input: [^]i64, length: uint,
    output: [^]u8, capacity: uint) -> i64 {
    if input == nil || length < 1 || length > HS_MAX_WORDS { return -1 }
    count_value := input[0]
    if count_value < 0 || count_value > HS_MAX_OPS { return -1 }
    count := uint(count_value)
    if length != 1 + 3 * count { return -1 }

    known_home: [64]i8
    for key in 0..<64 { known_home[key] = -1 }
    for op in 0..<count {
        opcode := input[1 + 3 * op]
        key := input[2 + 3 * op]
        home := input[3 + 3 * op]
        if (opcode != 1 && opcode != 2) || key < 0 || key >= 64 ||
            home < 0 || home >= HS_SLOTS { return -1 }
        key_index := uint(key)
        if known_home[key_index] >= 0 && i64(known_home[key_index]) != home { return -1 }
        known_home[key_index] = i8(home)
    }

    required := count + 2 * HS_SLOTS
    if output == nil || capacity < required { return -2 }
    keys: [HS_SLOTS]i16
    homes: [HS_SLOTS]u8
    hops: [HS_SLOTS]u8
    statuses: [HS_MAX_OPS]u8
    for slot in 0..<HS_SLOTS { keys[slot] = -1 }
    for op in 0..<count {
        opcode := int(input[1 + 3 * op])
        key := int(input[2 + 3 * op])
        home := int(input[3 + 3 * op])
        if opcode == 1 {
            statuses[op] = hs_insert(&keys[0], &homes[0], &hops[0], key, home)
        } else {
            statuses[op] = u8(hs_contains(&keys[0], &hops[0], key, home))
        }
    }

    cursor := uint(0)
    for op in 0..<count { output[cursor] = statuses[op]; cursor += 1 }
    for key in keys {
        output[cursor] = 0
        if key >= 0 { output[cursor] = u8(key + 1) }
        cursor += 1
    }
    for mask in hops { output[cursor] = mask; cursor += 1 }
    return i64(required)
}
