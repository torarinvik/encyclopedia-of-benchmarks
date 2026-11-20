package bench

@(export)
zobrist_position_hash_trace :: proc "c" (input: [^]i64, length: uint,
    output: [^]u8, capacity: uint) -> i64 {
    SLOTS :: 16
    FEATURES :: 3
    MAX_OPERATIONS :: 64
    BASE_WORDS :: 1 + SLOTS * FEATURES + SLOTS
    MAX_VALID_WORDS :: BASE_WORDS + 2 * MAX_OPERATIONS
    if input == nil || length < BASE_WORDS || length > MAX_VALID_WORDS + 1 { return -1 }
    count_value := input[0]
    if count_value < 0 || count_value > MAX_OPERATIONS { return -1 }
    count := uint(count_value)
    if length != BASE_WORDS + 2 * count { return -1 }

    for index in 0..<SLOTS * FEATURES {
        if input[1 + uint(index)] < 0 { return -1 }
    }
    state_start :: 1 + SLOTS * FEATURES
    for slot in 0..<SLOTS {
        feature := input[state_start + uint(slot)]
        if feature < 0 || feature > FEATURES { return -1 }
    }
    edits_start :: state_start + SLOTS
    for edit in 0..<count {
        slot := input[edits_start + 2 * edit]
        feature := input[edits_start + 2 * edit + 1]
        if slot < 0 || slot >= SLOTS || feature < 0 || feature > FEATURES { return -1 }
    }

    required := 8 * (count + 1)
    if output == nil || capacity < required { return -2 }

    board: [SLOTS]u8 = {}
    hash: u64 = 0
    for slot in 0..<SLOTS {
        feature := u8(input[state_start + uint(slot)])
        board[slot] = feature
        if feature != 0 { hash ~= u64(input[1 + uint(slot * FEATURES + int(feature) - 1)]) }
    }
    for byte in 0..<8 {
        output[uint(byte)] = u8(hash >> u64(byte * 8))
    }
    for edit in 0..<count {
        slot := uint(input[edits_start + 2 * edit])
        next := u8(input[edits_start + 2 * edit + 1])
        previous := board[slot]
        if previous != 0 { hash ~= u64(input[1 + slot * FEATURES + uint(previous) - 1]) }
        if next != 0 { hash ~= u64(input[1 + slot * FEATURES + uint(next) - 1]) }
        board[slot] = next
        offset := 8 * (edit + 1)
        for byte in 0..<8 {
            output[offset + uint(byte)] = u8(hash >> u64(byte * 8))
        }
    }
    return i64(required)
}
