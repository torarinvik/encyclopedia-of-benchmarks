pub export fn cupif_giannini_tree_traversal(
    input: [*c]const i64,
    length: usize,
    output: [*c]u8,
    capacity: usize,
) i64 {
    if (input == null or length < 2 or length > 3) return -1;
    if (length != 2) return -1;

    const height = input[0];
    const key_value = input[1];
    if (height < 0 or height > 6) return -1;
    const height_shift: u6 = @intCast(height);
    const leaf_count: u64 = @as(u64, 1) << height_shift;
    if (key_value < 0 or @as(u64, @intCast(key_value)) >= leaf_count) return -1;
    const required: usize = @intCast(leaf_count);
    if (output == null or capacity < required) return -2;

    for (0..leaf_count) |count| {
        const path = count ^ @as(u64, @intCast(key_value));
        var leaf_code: u8 = 0;
        for (0..height_shift) |depth| {
            const shift: u6 = @intCast(depth);
            if (((path >> shift) & 1) != 0) leaf_code |= @as(u8, 1) << shift;
        }
        output[@intCast(count)] = leaf_code;
    }
    return @intCast(leaf_count);
}
