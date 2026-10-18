const MAX_N: usize = 64;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 67;
const MAX_OUTPUT_BYTES: usize = 520;
const I32_MIN: i64 = -2_147_483_648;
const I32_MAX: i64 = 2_147_483_647;
const MBIG: i64 = 2_147_483_647;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

fn compatNext(seed_array: *[56]i64, inext: *usize, inextp: *usize) i64 {
    inext.* += 1;
    if (inext.* >= 56) inext.* = 1;
    inextp.* += 1;
    if (inextp.* >= 56) inextp.* = 1;

    var sample = seed_array.*[inext.*] - seed_array.*[inextp.*];
    if (sample == MBIG) sample -= 1;
    if (sample < 0) sample += MBIG;
    seed_array.*[inext.*] = sample;
    return sample;
}

export fn linqshuffler(input: [*c]const i64, input_length: usize,
                       output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or input_length < 2 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const n_value = input[0];
    const seed = input[1];
    if (n_value < 0 or n_value > MAX_N or seed < I32_MIN or seed > I32_MAX) return -1;
    const n: usize = @intCast(n_value);
    if (input_length != n + 2) return -1;

    var values: [MAX_N]i64 = @splat(0);
    var keys: [MAX_N]i64 = @splat(0);
    for (0..n) |index| {
        const value = input[index + 2];
        if (value < I32_MIN or value > I32_MAX) return -1;
        values[index] = value;
    }

    const subtraction = if (seed == I32_MIN) I32_MAX else if (seed < 0) -seed else seed;
    var seed_array: [56]i64 = @splat(0);
    var mj: i64 = 161803398 - subtraction;
    seed_array[55] = mj;
    var mk: i64 = 1;
    for (1..55) |i| {
        const ii = (21 * i) % 55;
        seed_array[ii] = mk;
        mk = mj - mk;
        if (mk < 0) mk += MBIG;
        mj = seed_array[ii];
    }
    for (0..4) |_| {
        for (1..56) |i| {
            const offset_index = 1 + (i + 30) % 55;
            seed_array[i] -= seed_array[offset_index];
            if (seed_array[i] < 0) seed_array[i] += MBIG;
        }
    }

    var inext: usize = 0;
    var inextp: usize = 21;
    for (0..n) |index| {
        keys[index] = compatNext(&seed_array, &inext, &inextp);
    }

    // Strict comparison preserves input order for equal random keys.
    for (1..n) |index| {
        const key = keys[index];
        const value = values[index];
        var cursor = index;
        while (cursor > 0 and keys[cursor - 1] > key) {
            keys[cursor] = keys[cursor - 1];
            values[cursor] = values[cursor - 1];
            cursor -= 1;
        }
        keys[cursor] = key;
        values[cursor] = value;
    }

    const output_bytes = 8 * (n + 1);
    if (output_bytes > MAX_OUTPUT_BYTES or output == null or output_capacity < output_bytes) return -2;
    storeI64Le(output, 0, n_value);
    for (0..n) |index| storeI64Le(output, 8 * (index + 1), values[index]);
    return @intCast(output_bytes);
}
