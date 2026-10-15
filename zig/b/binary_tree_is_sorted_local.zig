const MAX_SLOTS: usize = 255;
const MISSING_NODE: i64 = -2_147_483_649;

export fn binary_tree_is_sorted_local(input: ?[*]const i64, length: usize) i64 {
    if (length == 0 or length > MAX_SLOTS or input == null) return -1;
    const nodes = input.?[0..length];
    if (nodes[0] == MISSING_NODE) return -1;
    for (nodes, 0..) |value, index| {
        if (value == MISSING_NODE) continue;
        if (value < -2_147_483_648 or value > 2_147_483_647) return -1;
        if (index > 0) {
            const parent = (index - 1) / 2;
            if (nodes[parent] == MISSING_NODE) return -1;
            if ((index % 2 == 1 and value > nodes[parent]) or
                (index % 2 == 0 and value < nodes[parent])) return 0;
        }
    }
    return 1;
}
