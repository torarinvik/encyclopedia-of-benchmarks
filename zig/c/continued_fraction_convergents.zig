const MAX_INPUT_LENGTH: usize = 18;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn continued_fraction_convergents(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..length];
    const count_value = values[0];
    if (count_value < 1 or count_value > 16 or values[1] < -1000 or values[1] > 1000) return -1;
    const count: usize = @intCast(count_value);
    if (length != count + 1) return -1;
    for (values[2..]) |coefficient| if (coefficient < 1 or coefficient > 8) return -1;
    const required = 16 * count;
    if (output == null or capacity < required) return -2;
    const bytes = output.?;

    var p_two_back: i64 = 0;
    var p_one_back: i64 = 1;
    var q_two_back: i64 = 1;
    var q_one_back: i64 = 0;
    for (0..count) |index| {
        const p = values[index + 1] * p_one_back + p_two_back;
        const q = values[index + 1] * q_one_back + q_two_back;
        storeI64Le(bytes, 16 * index, p);
        storeI64Le(bytes, 16 * index + 8, q);
        p_two_back = p_one_back; p_one_back = p;
        q_two_back = q_one_back; q_one_back = q;
    }
    return @intCast(required);
}
