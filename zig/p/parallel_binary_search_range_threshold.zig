const MAX_N: usize = 16;
const MAX_EVENTS: usize = 32;
const MAX_QUERIES: usize = 32;
const MAX_PARSEABLE_LENGTH: usize = 196;

fn bitAdd(bit: []i64, start: usize, delta: i64, limit: usize) void {
    var index = start;
    while (index <= limit + 1) {
        bit[index] += delta;
        index += index & (~index +% 1);
    }
}

fn bitSum(bit: []const i64, start: usize) i64 {
    var index = start;
    var total: i64 = 0;
    while (index > 0) {
        total += bit[index];
        index -= index & (~index +% 1);
    }
    return total;
}

fn rangeAdd(bit1: []i64, bit2: []i64, n: usize, left: usize, right: usize, delta: i64) void {
    const lo = left + 1;
    const hi = right + 1;
    bitAdd(bit1, lo, delta, n);
    bitAdd(bit1, hi + 1, -delta, n);
    bitAdd(bit2, lo, delta * @as(i64, @intCast(lo - 1)), n);
    bitAdd(bit2, hi + 1, -delta * @as(i64, @intCast(hi)), n);
}

fn prefixSum(bit1: []const i64, bit2: []const i64, count: usize) i64 {
    return @as(i64, @intCast(count)) * bitSum(bit1, count) - bitSum(bit2, count);
}

fn rangeSum(bit1: []const i64, bit2: []const i64, left: usize, right: usize) i64 {
    return prefixSum(bit1, bit2, right + 1) - prefixSum(bit1, bit2, left);
}

export fn parallel_binary_search_range_threshold(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_PARSEABLE_LENGTH) return -1;
    const input = input_opt.?[0..length];
    if (input[0] < 1 or input[0] > MAX_N or input[1] < 0 or input[1] > MAX_EVENTS or
        input[2] < 0 or input[2] > MAX_QUERIES) return -1;
    const n: usize = @intCast(input[0]);
    const event_count: usize = @intCast(input[1]);
    const query_count: usize = @intCast(input[2]);
    if (length != 3 + 3 * event_count + 3 * query_count) return -1;

    var event_left: [MAX_EVENTS]usize = undefined;
    var event_right: [MAX_EVENTS]usize = undefined;
    var event_delta: [MAX_EVENTS]i64 = undefined;
    var query_left: [MAX_QUERIES]usize = undefined;
    var query_right: [MAX_QUERIES]usize = undefined;
    var query_target: [MAX_QUERIES]i64 = undefined;
    var cursor: usize = 3;
    for (0..event_count) |event| {
        const left = input[cursor];
        const right = input[cursor + 1];
        const delta = input[cursor + 2];
        cursor += 3;
        if (left < 0 or left > right or right >= n or delta < 0 or delta > 1000) return -1;
        event_left[event] = @intCast(left);
        event_right[event] = @intCast(right);
        event_delta[event] = delta;
    }
    for (0..query_count) |query| {
        const left = input[cursor];
        const right = input[cursor + 1];
        const target = input[cursor + 2];
        cursor += 3;
        if (left < 0 or left > right or right >= n or target < 1 or target > 512000) return -1;
        query_left[query] = @intCast(left);
        query_right[query] = @intCast(right);
        query_target[query] = target;
    }

    var low: [MAX_QUERIES]i64 = [_]i64{0} ** MAX_QUERIES;
    var high: [MAX_QUERIES]i64 = undefined;
    var next_query: [MAX_QUERIES]i64 = undefined;
    for (0..query_count) |query| high[query] = @as(i64, @intCast(event_count)) + 1;
    while (true) {
        var heads: [MAX_EVENTS + 1]i64 = [_]i64{-1} ** (MAX_EVENTS + 1);
        for (0..query_count) |query| next_query[query] = -1;
        var active = false;
        for (0..query_count) |query| {
            if (high[query] - low[query] > 1) {
                active = true;
                const middle: usize = @intCast(@divTrunc(low[query] + high[query], 2));
                next_query[query] = heads[middle];
                heads[middle] = @intCast(query);
            }
        }
        if (!active) break;

        var bit1: [MAX_N + 2]i64 = [_]i64{0} ** (MAX_N + 2);
        var bit2: [MAX_N + 2]i64 = [_]i64{0} ** (MAX_N + 2);
        var applied: usize = 0;
        for (0..event_count + 1) |middle| {
            while (applied < middle) : (applied += 1) {
                rangeAdd(bit1[0..], bit2[0..], n, event_left[applied], event_right[applied], event_delta[applied]);
            }
            var query = heads[middle];
            while (query >= 0) {
                const id: usize = @intCast(query);
                if (rangeSum(bit1[0..], bit2[0..], query_left[id], query_right[id]) >= query_target[id]) {
                    high[id] = @intCast(middle);
                } else {
                    low[id] = @intCast(middle);
                }
                query = next_query[id];
            }
        }
    }

    var result: i64 = 0;
    for (0..query_count) |query| result += @as(i64, @intCast(query + 1)) * (high[query] + 1);
    return result;
}
