const MAX_POINTS: usize = 256;

fn spread16(value_in: u32) u32 {
    var value = value_in;
    value = (value | (value << 8)) & 0x00ff00ff;
    value = (value | (value << 4)) & 0x0f0f0f0f;
    value = (value | (value << 2)) & 0x33333333;
    return (value | (value << 1)) & 0x55555555;
}

fn put(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(byte * 8)));
}

pub export fn morton_sort(input: ?[*]const i64, length: usize,
                          output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > 513) return -1;
    const values = input.?;
    if (values[0] < 1 or values[0] > MAX_POINTS) return -1;
    const count: usize = @intCast(values[0]);
    if (length != 1 + 2 * count) return -1;
    var keys = [_]u32{0} ** MAX_POINTS;
    var order = [_]usize{0} ** MAX_POINTS;
    for (0..count) |index| {
        const x = values[1 + 2 * index];
        const y = values[2 + 2 * index];
        if (x < 0 or x > 65535 or y < 0 or y > 65535) return -1;
        keys[index] = spread16(@intCast(x)) | (spread16(@intCast(y)) << 1);
        order[index] = index;
    }
    const bytes = count * 8;
    if (output == null or capacity < bytes) return -2;
    const out = output.?;
    for (1..count) |index| {
        const current = order[index];
        var position = index;
        while (position > 0 and (keys[order[position - 1]] > keys[current] or
              (keys[order[position - 1]] == keys[current] and order[position - 1] > current))) {
            order[position] = order[position - 1];
            position -= 1;
        }
        order[position] = current;
    }
    for (0..count) |index| put(out, index * 8, @intCast(order[index]));
    return @intCast(bytes);
}
