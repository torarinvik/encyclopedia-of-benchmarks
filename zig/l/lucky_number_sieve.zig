const max_candidates: usize = 2048;

export fn lucky_number_sieve(input: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length != 2) return -1;
    const values = input.?[0..2];
    const mode = values[0];
    const bound = values[1];
    if ((mode != 0 and mode != 1) or bound < 0 or bound > 4096) return -1;

    var candidates: [max_candidates]i64 = @splat(0);
    var count: usize = 0;
    const first: i64 = if (mode == 0) 1 else 2;
    var value = first;
    while (value <= bound) : (value += 2) {
        candidates[count] = value;
        count += 1;
    }

    var selected: usize = 1;
    while (selected < count) : (selected += 1) {
        const step: usize = @intCast(candidates[selected]);
        if (step > count) break;
        var write: usize = 0;
        var rank: usize = 0;
        for (0..count) |read| {
            rank += 1;
            if (rank % step != 0) {
                candidates[write] = candidates[read];
                write += 1;
            }
        }
        count = write;
    }

    const output_bytes = count * 8;
    if (output == null or output_capacity < output_bytes) return -2;
    const bytes = output.?[0..output_bytes];
    for (0..count) |index| {
        const bits: u64 = @bitCast(candidates[index]);
        for (0..8) |byte| {
            const shift: u6 = @intCast(byte * 8);
            bytes[index * 8 + byte] = @truncate(bits >> shift);
        }
    }
    return @intCast(output_bytes);
}
