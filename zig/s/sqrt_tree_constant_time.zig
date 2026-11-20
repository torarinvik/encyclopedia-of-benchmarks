const MAX_N: usize = 64;
const MAX_Q: usize = 64;
const MAX_LEVELS: usize = 4;
const MAX_INPUT: usize = 195;
const VALUE_LIMIT: i64 = 1_000_000_000;
const INF: i64 = 0x7fffffffffffffff;

const State = struct {
    values: [MAX_N]i64 = @splat(0),
    prefix: [MAX_LEVELS * MAX_N]i64 = @splat(0),
    suffix: [MAX_LEVELS * MAX_N]i64 = @splat(0),
    between: [MAX_LEVELS * MAX_N]i64 = @splat(0),
    floor_log: [MAX_N + 1]usize = @splat(0),
    padded: usize = 1,
    layer_count: usize = 0,
    segment_bits: [MAX_LEVELS]usize = @splat(0),
    block_bits: [MAX_LEVELS]usize = @splat(0),
    layer_for_diff: [MAX_LEVELS + 3]isize = @splat(-1),
};

fn build(state: *State, input: [*c]const i64, n: usize) void {
    var padded: usize = 1;
    while (padded < n) : (padded *= 2) {}
    state.padded = padded;
    for (0..n) |i| state.values[i] = input[2 + i];
    for (n..padded) |i| state.values[i] = INF;
    state.floor_log[0] = 0;
    state.floor_log[1] = 0;
    for (2..padded + 1) |i| state.floor_log[i] = state.floor_log[i / 2] + 1;
    @memset(&state.layer_for_diff, -1);
    var bits = state.floor_log[padded];
    while (bits > 1) {
        const level = state.layer_count;
        state.layer_count += 1;
        const block_bits = (bits + 1) / 2;
        state.segment_bits[level] = bits;
        state.block_bits[level] = block_bits;
        for (block_bits..bits) |bit| state.layer_for_diff[bit] = @intCast(level);
        bits = block_bits;
    }

    for (0..state.layer_count) |level| {
        const segment_bits = state.segment_bits[level];
        const block_bits = state.block_bits[level];
        const segment_size = @as(usize, 1) << @intCast(segment_bits);
        const block_size = @as(usize, 1) << @intCast(block_bits);
        const block_count = segment_size / block_size;
        const pair_count = block_count * block_count;
        var base: usize = 0;
        while (base < padded) : (base += segment_size) {
            const segment_index = base / segment_size;
            for (0..block_count) |block| {
                const start = base + block * block_size;
                const end = start + block_size;
                state.prefix[level * MAX_N + start] = state.values[start];
                for (start + 1..end) |pos| {
                    state.prefix[level * MAX_N + pos] = @min(state.prefix[level * MAX_N + pos - 1], state.values[pos]);
                }
                state.suffix[level * MAX_N + end - 1] = state.values[end - 1];
                var pos = end - 1;
                while (pos > start) {
                    pos -= 1;
                    state.suffix[level * MAX_N + pos] = @min(state.values[pos], state.suffix[level * MAX_N + pos + 1]);
                }
            }
            for (0..block_count) |left_block| {
                var aggregate = INF;
                var right_block = left_block;
                while (right_block < block_count) : (right_block += 1) {
                    const start = base + right_block * block_size;
                    aggregate = @min(aggregate, state.suffix[level * MAX_N + start]);
                    const slot = segment_index * pair_count + left_block * block_count + right_block;
                    state.between[level * MAX_N + slot] = aggregate;
                }
            }
        }
    }
}

fn query(state: *const State, left: usize, right: usize) i64 {
    if (left == right) return state.values[left];
    const bit = state.floor_log[left ^ right];
    if (bit == 0) return @min(state.values[left], state.values[right]);
    const level: usize = @intCast(state.layer_for_diff[bit]);
    const segment_bits = state.segment_bits[level];
    const block_bits = state.block_bits[level];
    const segment_size = @as(usize, 1) << @intCast(segment_bits);
    const block_size = @as(usize, 1) << @intCast(block_bits);
    const base = (left / segment_size) * segment_size;
    const segment_index = base / segment_size;
    const block_count = segment_size / block_size;
    const left_block = (left - base) / block_size;
    const right_block = (right - base) / block_size;
    var answer = @min(state.suffix[level * MAX_N + left], state.prefix[level * MAX_N + right]);
    if (left_block + 1 < right_block) {
        const pair_count = block_count * block_count;
        const slot = segment_index * pair_count + (left_block + 1) * block_count + right_block - 1;
        answer = @min(answer, state.between[level * MAX_N + slot]);
    }
    return answer;
}

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    var bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        output[offset + byte] = @truncate(bits & 255);
        bits >>= 8;
    }
}

export fn sqrt_tree_constant_time(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT) return -1;
    const n_value = input[0];
    const q_value = input[1];
    if (n_value < 1 or n_value > MAX_N or q_value < 0 or q_value > MAX_Q) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    if (length != 2 + n + 2 * q) return -1;
    for (0..n) |i| {
        if (input[2 + i] < -VALUE_LIMIT or input[2 + i] > VALUE_LIMIT) return -1;
    }
    const query_offset = 2 + n;
    for (0..q) |i| {
        const left = input[query_offset + 2 * i];
        const right = input[query_offset + 2 * i + 1];
        if (left < 0 or right < left or right >= n_value) return -1;
    }
    const required = 8 * q;
    if (capacity < required or (required != 0 and output == null)) return -2;
    var state: State = .{};
    build(&state, input, n);
    for (0..q) |i| {
        const left: usize = @intCast(input[query_offset + 2 * i]);
        const right: usize = @intCast(input[query_offset + 2 * i + 1]);
        storeI64Le(output, 8 * i, query(&state, left, right));
    }
    return @intCast(required);
}
