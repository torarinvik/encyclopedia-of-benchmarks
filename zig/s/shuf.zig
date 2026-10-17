const MAX_INPUT_LENGTH: usize = 67;

fn writeI32Le(output: []u8, index: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    const offset = index * 4;
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn shuf(input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?[0..length];
    const count_raw = input[0];
    const sample_size_raw = input[1];
    if (count_raw < 0 or count_raw > 32 or sample_size_raw < 1 or sample_size_raw > 32) return -1;
    const count: usize = @intCast(count_raw);
    const sample_size: usize = @intCast(sample_size_raw);
    if (length != 2 + 2 * count) return -1;

    var items: [32]i32 = [_]i32{0} ** 32;
    var sample: [32]i32 = [_]i32{0} ** 32;
    var occupied: [32]bool = [_]bool{false} ** 32;
    for (0..count) |index| {
        const value = input[2 + index];
        if (value < -2147483648 or value > 2147483647) return -1;
        items[index] = @intCast(value);
    }
    const initial_count = @min(count, sample_size);
    for (0..initial_count) |index| {
        const draw = input[2 + count + index];
        if (draw < 0 or draw >= @as(i64, @intCast(sample_size))) return -1;
        var slot: usize = @intCast(draw);
        while (occupied[slot]) slot = (slot + 1) % sample_size;
        sample[slot] = items[index];
        occupied[slot] = true;
    }
    if (count >= sample_size) {
        for (sample_size..count) |index| {
            const draw = input[2 + count + index];
            if (draw < 0 or draw > @as(i64, @intCast(index))) return -1;
            if (draw < @as(i64, @intCast(sample_size))) sample[@intCast(draw)] = items[index];
        }
    }

    const output_count = initial_count;
    const output_bytes = output_count * 4;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?[0..output_bytes];
    var output_index: usize = 0;
    for (0..sample_size) |slot| {
        if (occupied[slot]) {
            writeI32Le(output, output_index, sample[slot]);
            output_index += 1;
        }
    }
    return @intCast(output_index);
}
