fn putI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

pub export fn count_min_sketch_width_one_collision(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > 513) return -1;
    const count_value = input[0];
    if (count_value < 0 or count_value > 256) return -1;
    const count: usize = @intCast(count_value);
    if (length != 1 + count * 2) return -1;
    var queries: usize = 0;
    for (0..count) |i| {
        const operation = input[1 + 2 * i];
        const key = input[2 + 2 * i];
        if ((operation != 0 and operation != 1) or key < -1_000_000 or key > 1_000_000) return -1;
        if (operation == 1) queries += 1;
    }
    const required = queries * 8;
    if (capacity < required or (required > 0 and output == null)) return -2;
    var inserts: i64 = 0;
    var output_offset: usize = 0;
    for (0..count) |i| {
        if (input[1 + 2 * i] == 0) inserts += 1
        else { putI64Le(output, output_offset, inserts); output_offset += 8; }
    }
    return @intCast(required);
}
