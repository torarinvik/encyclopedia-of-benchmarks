const MAX_ELEMENTS: usize = 16;

fn insertAtBottom(items: *[MAX_ELEMENTS]i64, size: usize, value: i64) void {
    if (size == 0) { items[0] = value; return; }
    const top = items[size - 1];
    insertAtBottom(items, size - 1, value);
    items[size] = top;
}

fn reverseRecursive(items: *[MAX_ELEMENTS]i64, size: usize) void {
    if (size == 0) return;
    const top = items[size - 1];
    reverseRecursive(items, size - 1);
    insertAtBottom(items, size - 1, top);
}

fn putI64Le(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn reverse_stack(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 1) return -1;
    const values = input.?[0..length];
    const raw_count = values[0];
    if (raw_count < 0 or raw_count > MAX_ELEMENTS or length != @as(usize, @intCast(raw_count)) + 1) return -1;
    const count: usize = @intCast(raw_count);
    for (values[1..]) |value| if (value < -1_000_000 or value > 1_000_000) return -1;
    const bytes = (count + 1) * 8;
    if (output == null or capacity < bytes) return -2;
    var items: [MAX_ELEMENTS]i64 = @splat(0);
    @memcpy(items[0..count], values[1..]);
    reverseRecursive(&items, count);
    const result = output.?[0..bytes];
    putI64Le(result, 0, raw_count);
    for (0..count) |i| putI64Le(result, 8 * (i + 1), items[i]);
    return @intCast(bytes);
}
