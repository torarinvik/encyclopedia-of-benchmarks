const MAX_TEXT_LENGTH: usize = 1024;

fn storeI64Le(value: i64, output: [*]u8) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn onepad_cipher(input: [*]const i64, length: usize, output: [*]u8, output_capacity: usize) i64 {
    if (length < 2 or length > 2 + 2 * MAX_TEXT_LENGTH) return -1;
    const mode = input[0];
    const count_value = input[1];
    if ((mode != 0 and mode != 1) or count_value < 0 or count_value > MAX_TEXT_LENGTH) return -1;
    const count: usize = @intCast(count_value);
    if (length != 2 + 2 * count) return -1;
    const needed = if (mode == 0) 8 * count else count;
    if (output_capacity < needed) return -2;
    for (0..count) |index| {
        const data = input[2 + index];
        const key = input[2 + count + index];
        if (key < 1 or key > 300) return -1;
        if (mode == 0) {
            if (data < 32 or data > 126) return -1;
            storeI64Le((data + key) * key, output + 8 * index);
        } else {
            const key_square = key * key;
            if (data < key_square or @rem(data - key_square, key) != 0) return -1;
            const plain = @divTrunc(data - key_square, key);
            if (plain < 32 or plain > 126) return -1;
            output[index] = @intCast(plain);
        }
    }
    return @intCast(needed);
}
