const MAX_OPERATIONS: usize = 64;
const MAX_PARSEABLE_LENGTH: usize = 130;
const COUNTER_COUNT: usize = 67;
const HASH_COUNT: usize = 4;

fn hashPositions(key: i64) [HASH_COUNT]usize {
    const bounded_key: u32 = @intCast(key);
    const counter_count: u32 = @intCast(COUNTER_COUNT);
    const base: u32 = (17 * bounded_key + 3) % counter_count;
    const stride: u32 = 1 + ((5 * bounded_key + 3) % (counter_count - 1));
    var positions: [HASH_COUNT]usize = @splat(0);
    for (0..HASH_COUNT) |j| {
        const offset: u32 = @as(u32, @intCast(j)) * stride;
        positions[j] = @intCast((base + offset) % counter_count);
    }
    return positions;
}

pub export fn counting_bloom_filter_operation_trace(
    input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize,
) i64 {
    if (input == null or length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    const raw_count = input[0];
    if (raw_count < 0 or raw_count > @as(i64, MAX_OPERATIONS)) return -1;
    const count: usize = @intCast(raw_count);
    if (length != 1 + 2 * count) return -1;
    for (0..count) |operation| {
        const opcode = input[1 + 2 * operation];
        const key = input[2 + 2 * operation];
        if (opcode < 0 or opcode > 2 or key < 0 or key > 65535) return -1;
    }
    if (output == null or capacity < count) return -2;

    var counters: [COUNTER_COUNT]u8 = @splat(0);
    var statuses: [MAX_OPERATIONS]u8 = @splat(0);
    for (0..count) |operation| {
        const opcode = input[1 + 2 * operation];
        const key = input[2 + 2 * operation];
        const positions = hashPositions(key);
        if (opcode == 0) {
            for (positions) |position| counters[position] += 1;
            statuses[operation] = 1;
        } else if (opcode == 1) {
            // The input contract guarantees that each deleted key is live.
            for (positions) |position| counters[position] -= 1;
            statuses[operation] = 1;
        } else {
            var present = true;
            for (positions) |position| {
                if (counters[position] == 0) present = false;
            }
            statuses[operation] = if (present) 1 else 0;
        }
    }
    for (0..count) |operation| output[operation] = statuses[operation];
    return @intCast(count);
}
