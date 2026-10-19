const MAX_ITERATIONS: i64 = 1_125_000;
const NIBBLE_BITS = [_]i32{ 0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4 };
const INITIAL_SEEDS = [_]u32{1, 1, 1, 1, 1, 1, 1};

fn countKernighan(input: u32) i32 {
    var value = input;
    var count: i32 = 0;
    while (value != 0) {
        value &= value - 1;
        count += 1;
    }
    return count;
}

fn countParallel(input: u32) i32 {
    var value = input;
    value = ((value & 0xAAAAAAAA) >> 1) + (value & 0x55555555);
    value = ((value & 0xCCCCCCCC) >> 2) + (value & 0x33333333);
    value = ((value & 0xF0F0F0F0) >> 4) + (value & 0x0F0F0F0F);
    value = ((value & 0xFF00FF00) >> 8) + (value & 0x00FF00FF);
    value = ((value & 0xFFFF0000) >> 16) + (value & 0x0000FFFF);
    return @intCast(value);
}

fn countRecursiveNybbles(value: u32) i32 {
    const count = NIBBLE_BITS[@intCast(value & 0xF)];
    if (value >> 4 == 0) return count;
    return count + countRecursiveNybbles(value >> 4);
}

fn countFixedNybbles(value: u32) i32 {
    var count: i32 = 0;
    for (0..8) |nybble| {
        const shift: u5 = @intCast(nybble * 4);
        count += NIBBLE_BITS[@intCast((value >> shift) & 0xF)];
    }
    return count;
}

fn countByte(value: u32) i32 {
    return NIBBLE_BITS[@intCast(value & 0xF)] + NIBBLE_BITS[@intCast((value >> 4) & 0xF)];
}

fn countBwBytes(value: u32) i32 {
    return countByte(value) + countByte(value >> 8) + countByte(value >> 24) + countByte(value >> 16);
}

fn countArBytes(value: u32) i32 {
    var count: i32 = 0;
    for (0..4) |index| count += countByte(value >> @intCast(index * 8));
    return count;
}

fn countShiftTest(input: u32) i32 {
    var value = input;
    var count: i32 = 0;
    for (0..64) |_| {
        if (value == 0) break;
        count += @intCast(value & 1);
        value >>= 1;
    }
    return count;
}

fn countSelected(algorithm: usize, value: u32) i32 {
    if (algorithm == 0) return countKernighan(value);
    if (algorithm == 1) return countParallel(value);
    if (algorithm == 2) return countRecursiveNybbles(value);
    if (algorithm == 3) return countFixedNybbles(value);
    if (algorithm == 4) return countBwBytes(value);
    if (algorithm == 5) return countArBytes(value);
    return countShiftTest(value);
}

export fn cbench_automotive_bitcount(iterations: i64) i64 {
    if (iterations < 0 or iterations > MAX_ITERATIONS) return -1;
    var result: i64 = 0;
    for (0..7) |algorithm| {
        var seed = INITIAL_SEEDS[algorithm];
        var total: i64 = 0;
        var iteration: i64 = 0;
        while (iteration < iterations) : (iteration += 1) {
            total += @as(i64, @intCast(countSelected(algorithm, seed)));
            seed += 13;
        }
        result += @as(i64, @intCast(algorithm + 1)) * total;
    }
    return result;
}
