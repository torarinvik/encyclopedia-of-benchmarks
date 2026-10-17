const MAX_INTERVALS: usize = 256;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_INTERVALS;

fn storeI32Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u32 = @bitCast(@as(i32, @intCast(value)));
    for (0..4) |byte| {
        output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
    }
}

export fn merge_intervals(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const raw_count = values[0];
    if (raw_count < 0 or raw_count > @as(i64, @intCast(MAX_INTERVALS))) return -1;
    const count: usize = @intCast(raw_count);
    if (length != 1 + 2 * count) return -1;

    var starts: [MAX_INTERVALS]i64 = @splat(0);
    var ends: [MAX_INTERVALS]i64 = @splat(0);
    for (0..count) |index| {
        const start = values[1 + 2 * index];
        const ending = values[2 + 2 * index];
        if (start < -2147483648 or start > 2147483647 or
            ending < -2147483648 or ending > 2147483647 or start > ending) return -1;
        starts[index] = start;
        ends[index] = ending;
    }

    var index: usize = 1;
    while (index < count) : (index += 1) {
        const start = starts[index];
        const ending = ends[index];
        var position = index;
        while (position > 0 and starts[position - 1] > start) : (position -= 1) {
            starts[position] = starts[position - 1];
            ends[position] = ends[position - 1];
        }
        starts[position] = start;
        ends[position] = ending;
    }

    var merged: usize = 0;
    for (0..count) |current| {
        if (merged != 0 and starts[current] <= ends[merged - 1]) {
            if (ends[current] > ends[merged - 1]) ends[merged - 1] = ends[current];
        } else {
            starts[merged] = starts[current];
            ends[merged] = ends[current];
            merged += 1;
        }
    }

    const byte_count = 8 * merged;
    if (output == null or output_capacity < byte_count) return -2;
    for (0..merged) |result_index| {
        storeI32Le(output, 8 * result_index, starts[result_index]);
        storeI32Le(output, 8 * result_index + 4, ends[result_index]);
    }
    return @intCast(byte_count);
}
