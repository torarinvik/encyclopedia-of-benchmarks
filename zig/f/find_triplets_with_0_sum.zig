const MAX_ITEMS: usize = 64;
const BYTES_PER_TRIPLET: usize = 12;

fn writeI32Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u32 = @bitCast(@as(i32, @intCast(value)));
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

fn enumerate(values: []const i64, output: [*c]u8, writeOutput: bool) usize {
    var count: usize = 0;
    var hasLast = false;
    var lastA: i64 = 0;
    var lastB: i64 = 0;
    var lastC: i64 = 0;
    for (0..values.len) |i| {
        if (i + 2 >= values.len) break;
        for (i + 1..values.len) |j| {
            if (j + 1 >= values.len) break;
            for (j + 1..values.len) |k| {
                if (values[i] + values[j] + values[k] != 0) continue;
                if (hasLast and values[i] == lastA and values[j] == lastB and values[k] == lastC) continue;
                if (writeOutput) {
                    const offset = count * BYTES_PER_TRIPLET;
                    writeI32Le(output, offset, values[i]);
                    writeI32Le(output, offset + 4, values[j]);
                    writeI32Le(output, offset + 8, values[k]);
                }
                lastA = values[i];
                lastB = values[j];
                lastC = values[k];
                hasLast = true;
                count += 1;
            }
        }
    }
    return count;
}

export fn find_triplets_with_0_sum(input: [*c]const i64, length: usize, output: [*c]u8, output_capacity: usize) i64 {
    if (length > MAX_ITEMS or (length > 0 and input == null)) return -1;
    var values: [MAX_ITEMS]i64 = @splat(0);
    for (0..length) |i| {
        if (input[i] < -100_000 or input[i] > 100_000) return -1;
        values[i] = input[i];
    }
    for (1..length) |i| {
        const key = values[i];
        var j = i;
        while (j > 0 and values[j - 1] > key) : (j -= 1) values[j] = values[j - 1];
        values[j] = key;
    }
    const sorted = values[0..length];
    const count = enumerate(sorted, null, false);
    if (count == 0) return 0;
    const needed = count * BYTES_PER_TRIPLET;
    if (output == null or output_capacity < needed) return -2;
    return @intCast(enumerate(sorted, output, true));
}

