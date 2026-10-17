const MAX_ITEMS: usize = 64;

fn insert_sorted(stack: *[MAX_ITEMS]i32, size: *usize, value: i32) void {
    if (size.* == 0 or value > stack[size.* - 1]) {
        stack[size.*] = value;
        size.* += 1;
        return;
    }
    size.* -= 1;
    const top = stack[size.*];
    insert_sorted(stack, size, value);
    stack[size.*] = top;
    size.* += 1;
}

fn sort_recursively(stack: *[MAX_ITEMS]i32, size: *usize) void {
    if (size.* == 0) return;
    size.* -= 1;
    const top = stack[size.*];
    sort_recursively(stack, size);
    insert_sorted(stack, size, top);
}

export fn sort_stack(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > 65) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > MAX_ITEMS or length != 1 + @as(usize, @intCast(input[0]))) return -1;
    const count: usize = @intCast(input[0]);
    var stack: [MAX_ITEMS]i32 = undefined;
    for (0..count) |i| {
        if (input[i + 1] < -2147483648 or input[i + 1] > 2147483647) return -1;
        stack[i] = @intCast(input[i + 1]);
    }
    var size = count;
    sort_recursively(&stack, &size);
    const bytes = size * 4;
    const output = output_opt orelse return -2;
    if (output_capacity < bytes) return -2;
    for (0..size) |i| {
        const bits: u32 = @bitCast(stack[i]);
        for (0..4) |b| output[4 * i + b] = @truncate(bits >> @intCast(8 * b));
    }
    return @intCast(bytes);
}
