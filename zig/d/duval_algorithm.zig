/// Lyndon factorization using Duval's linear-time algorithm.
const MAX_LENGTH: usize = 4096;

fn validInput(values: [*]const i64, length: usize) bool {
    if (length > MAX_LENGTH) return false;
    if (length == 0) return true;
    for (values[0..length]) |value| {
        if (value < 0 or value > 127) return false;
    }
    return true;
}

fn factorCount(values: [*]const i64, length: usize) usize {
    var start: usize = 0;
    var count: usize = 0;
    while (start < length) {
        var end = start + 1;
        var repeat = start;
        while (end < length and values[repeat] <= values[end]) {
            if (values[repeat] < values[end]) repeat = start else repeat += 1;
            end += 1;
        }
        const factor_length = end - repeat;
        while (start <= repeat) {
            count += 1;
            start += factor_length;
        }
    }
    return count;
}

fn storeU32LE(output: [*]u8, offset: usize, value: usize) void {
    const packed: u32 = @intCast(value);
    output[offset] = @truncate(packed & 255);
    output[offset + 1] = @truncate((packed >> 8) & 255);
    output[offset + 2] = @truncate((packed >> 16) & 255);
    output[offset + 3] = @truncate((packed >> 24) & 255);
}

fn writeFactors(values: [*]const i64, length: usize, output: [*]u8) void {
    var start: usize = 0;
    var factor_index: usize = 0;
    while (start < length) {
        var end = start + 1;
        var repeat = start;
        while (end < length and values[repeat] <= values[end]) {
            if (values[repeat] < values[end]) repeat = start else repeat += 1;
            end += 1;
        }
        const factor_length = end - repeat;
        while (start <= repeat) {
            storeU32LE(output, 4 * factor_index, factor_length);
            factor_index += 1;
            start += factor_length;
        }
    }
}

export fn duval_algorithm(values: [*]const i64, length: usize,
                          output: [*]u8, output_capacity: usize) i64 {
    if (length > MAX_LENGTH) return -1;
    for (values[0..length]) |value| {
        if (value < 0 or value > 127) return -1;
    }
    const count = factorCount(values, length);
    const required = 4 * count;
    if (required == 0) return 0;
    if (output_capacity < required) return -2;
    writeFactors(values, length, output);
    return @intCast(count);
}
