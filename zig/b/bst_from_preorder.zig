/// Validate and serialize a strict BST reconstructed from preorder values.
fn validPreorder(values: [*]const i64, start: usize, end: usize,
                 lower: i64, upper: i64) bool {
    if (start == end) return true;
    const root = values[start];
    if (root <= lower or root >= upper) return false;
    var split = start + 1;
    while (split < end and values[split] < root) : (split += 1) {}
    return validPreorder(values, start + 1, split, lower, root) and
        validPreorder(values, split, end, root, upper);
}

fn emitPreorderTree(values: [*]const i64, start: usize, end: usize,
                    output: [*]u8, position: usize) usize {
    if (start == end) {
        output[position] = 0;
        return position + 1;
    }
    const root = values[start];
    var split = start + 1;
    while (split < end and values[split] < root) : (split += 1) {}
    output[position] = 1;
    const encoded: u32 = @bitCast(@as(i32, @intCast(root)));
    output[position + 1] = @truncate(encoded);
    output[position + 2] = @truncate(encoded >> 8);
    output[position + 3] = @truncate(encoded >> 16);
    output[position + 4] = @truncate(encoded >> 24);
    const next_position = emitPreorderTree(values, start + 1, split, output, position + 5);
    return emitPreorderTree(values, split, end, output, next_position);
}

export fn bst_from_preorder(values: [*]const i64, length: usize,
                            output: [*]u8, output_capacity: usize) i64 {
    if (length == 0 or length > 15) return -1;
    for (0..length) |index| {
        if (values[index] < -2147483648 or values[index] > 2147483647) return -1;
    }
    if (!validPreorder(values, 0, length, -2147483649, 2147483648)) return -1;
    const required = 6 * length + 1;
    if (output_capacity < required) return -2;
    _ = emitPreorderTree(values, 0, length, output, 0);
    return @intCast(length);
}
