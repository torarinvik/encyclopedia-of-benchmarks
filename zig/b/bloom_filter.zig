const MAX_TRACE_VALUES: usize = 256;
const MAX_KEY: i64 = 1_000_000_000;

export fn bloom_filter(trace: [*]const i64, length: usize,
                       output: [*]u8, output_capacity: usize) i64 {
    if (length > MAX_TRACE_VALUES or length % 2 != 0) return -1;
    var query_count: usize = 0;
    var index: usize = 0;
    while (index < length) : (index += 2) {
        const operation = trace[index];
        const key = trace[index + 1];
        if ((operation != 1 and operation != 2) or key < 0 or key > MAX_KEY) return -1;
        if (operation == 2) query_count += 1;
    }
    if (output_capacity < query_count) return -2;

    var bits: u64 = 0;
    var written: usize = 0;
    index = 0;
    while (index < length) : (index += 2) {
        const operation = trace[index];
        const key = trace[index + 1];
        const first: u6 = @intCast(@mod(key * 17 + 3, 64));
        const second: u6 = @intCast(@mod(key * 31 + 7, 64));
        const first_mask: u64 = @as(u64, 1) << first;
        const second_mask: u64 = @as(u64, 1) << second;
        if (operation == 1) {
            bits |= first_mask | second_mask;
        } else {
            output[written] = @intFromBool((bits & first_mask) != 0 and (bits & second_mask) != 0);
            written += 1;
        }
    }
    return @intCast(written);
}
