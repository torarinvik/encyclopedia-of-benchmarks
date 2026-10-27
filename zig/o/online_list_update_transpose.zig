const MAX_N: usize = 8;
const MAX_REQUESTS: usize = 32;
const MAX_INPUT: usize = 42;
const MAX_OUTPUT_BYTES: usize = 328;

fn store_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn online_list_update_transpose(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n_raw = input[0];
    const requests_raw = input[1];
    if (n_raw < 1 or n_raw > @as(i64, MAX_N) or requests_raw < 0 or requests_raw > @as(i64, MAX_REQUESTS)) return -1;
    const n: usize = @intCast(n_raw);
    const request_count: usize = @intCast(requests_raw);
    if (length != 2 + n + request_count) return -1;
    var order: [MAX_N]usize = @splat(0);
    var seen: [MAX_N]bool = @splat(false);
    for (0..n) |i| {
        const item = input[2 + i];
        if (item < 0 or item >= n_raw or seen[@intCast(item)]) return -1;
        order[i] = @intCast(item);
        seen[@intCast(item)] = true;
    }
    var positions: [MAX_REQUESTS]i64 = @splat(0);
    var total_cost: i64 = 0;
    for (0..request_count) |request| {
        const item_raw = input[2 + n + request];
        if (item_raw < 0 or item_raw >= n_raw) return -1;
        const item: usize = @intCast(item_raw);
        var position: usize = 0;
        while (position < n and order[position] != item) position += 1;
        if (position == n) return -1;
        positions[request] = @intCast(position + 1);
        total_cost += @intCast(position + 1);
        if (position > 0) {
            const previous = order[position - 1];
            order[position - 1] = order[position];
            order[position] = previous;
            total_cost += 1;
        }
    }
    var words: [1 + MAX_N + MAX_REQUESTS]i64 = @splat(0);
    words[0] = total_cost;
    for (0..n) |i| words[1 + i] = @intCast(order[i]);
    for (0..request_count) |i| words[1 + n + i] = positions[i];
    const output_bytes = 8 * (1 + n + request_count);
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var staged: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    for (0..1 + n + request_count) |word| store_i64_le(&staged, 8 * word, words[word]);
    for (0..output_bytes) |byte| output[byte] = staged[byte];
    return @intCast(output_bytes);
}
