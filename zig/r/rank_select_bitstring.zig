const MAX_BITS: usize = 63;
const MAX_BLOCKS: usize = 8;
const MAX_QUERIES: usize = 16;
const MAX_INPUT: usize = 35;
const MAX_OUTPUT_BYTES: usize = 128;

fn store_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn rank_select_bitstring(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const packed_value = input[1];
    const query_value = input[2];
    if (n_value < 1 or n_value > @as(i64, MAX_BITS) or packed_value < 0 or query_value < 0 or query_value > @as(i64, MAX_QUERIES)) return -1;
    const n: usize = @intCast(n_value);
    const queries: usize = @intCast(query_value);
    const bits: u64 = @intCast(packed_value);
    if ((bits >> @intCast(n)) != 0 or length != 3 + 2 * queries) return -1;
    const block_count = (n + 7) / 8;
    var prefix: [MAX_BLOCKS + 1]i64 = @splat(0);
    for (0..block_count) |block| {
        prefix[block + 1] = prefix[block];
        const end = @min(n, 8 * block + 8);
        for (8 * block..end) |pos| prefix[block + 1] += @intCast((bits >> @intCast(pos)) & 1);
    }
    var answers: [MAX_QUERIES]i64 = @splat(0);
    for (0..queries) |query| {
        const op = input[3 + 2 * query];
        const index_value = input[4 + 2 * query];
        if ((op != 0 and op != 1) or index_value < 1 or
            (op == 0 and index_value > n_value) or (op == 1 and index_value > @as(i64, MAX_BITS + 1))) return -1;
        const index: usize = @intCast(index_value);
        if (op == 0) {
            const full_blocks = index / 8;
            const remainder = index % 8;
            var answer = prefix[full_blocks];
            for (8 * full_blocks..8 * full_blocks + remainder) |pos| answer += @intCast((bits >> @intCast(pos)) & 1);
            answers[query] = answer;
        } else {
            var block: usize = 0;
            while (block < block_count and prefix[block + 1] < @as(i64, @intCast(index))) : (block += 1) {}
            answers[query] = -1;
            if (block < block_count) {
                var remaining = index - @as(usize, @intCast(prefix[block]));
                const end = @min(n, 8 * block + 8);
                for (8 * block..end) |pos| {
                    if ((bits >> @intCast(pos)) & 1 != 0) {
                        remaining -= 1;
                        if (remaining == 0) { answers[query] = @intCast(pos + 1); break; }
                    }
                }
            }
        }
    }
    const output_bytes = 8 * queries;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var staged: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    for (0..queries) |query| store_i64_le(&staged, 8 * query, answers[query]);
    for (0..output_bytes) |byte| output[byte] = staged[byte];
    return @intCast(output_bytes);
}
