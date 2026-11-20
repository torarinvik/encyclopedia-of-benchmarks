package bench

@(export)
cupif_giannini_tree_traversal :: proc "c" (input: [^]i64, length: uint,
    output: [^]u8, capacity: uint) -> i64 {
    if input == nil || length < 2 || length > 3 { return -1 }
    if length != 2 { return -1 }

    height_value := input[0]
    key_value := input[1]
    if height_value < 0 || height_value > 6 { return -1 }
    height := int(height_value)
    leaf_count := 1 << height
    if key_value < 0 || key_value >= i64(leaf_count) { return -1 }
    if output == nil || capacity < uint(leaf_count) { return -2 }

    for count in 0..<leaf_count {
        path := u64(count) ~ u64(key_value)
        leaf_code: u8 = 0
        for depth in 0..<height {
            if ((path >> u64(depth)) & 1) != 0 {
                leaf_code |= u8(1) << u8(depth)
            }
        }
        output[uint(count)] = leaf_code
    }
    return i64(leaf_count)
}
