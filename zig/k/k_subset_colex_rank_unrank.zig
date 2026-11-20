const MAX_N: i64 = 16;
const MAX_K: usize = 16;
const MAX_INPUT: usize = 20;

fn chooseSmall(n: usize, k_value: usize) i64 {
    if (k_value > n) return 0;
    const k = @min(k_value, n - k_value);
    var value: i64 = 1;
    for (1..(k + 1)) |i| value = @divTrunc(value * @as(i64, @intCast(n - k + i)), @as(i64, @intCast(i)));
    return value;
}

fn storeI64Le(output: [*]u8, index: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[index * 8 + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn k_subset_colex_rank_unrank(input: [*]const i64, length: usize,
    output: [*]u8, capacity: usize) i64 {
    if (@intFromPtr(input) == 0 or length < 3 or length > MAX_INPUT) return -1;
    const mode = input[0];
    if (mode != 0 and mode != 1) return -1;
    const raw_n = input[1];
    const raw_k = input[2];
    if (raw_n < 0 or raw_n > MAX_N or raw_k < 0 or raw_k > raw_n) return -1;
    const n: usize = @intCast(raw_n);
    const k: usize = @intCast(raw_k);
    var indices: [MAX_K]i64 = @splat(0);
    var rank: i64 = 0;

    if (mode == 0) {
        if (length != 3 + k) return -1;
        for (0..k) |i| {
            const index = input[3 + i];
            if (index < 0 or index >= raw_n or (i > 0 and indices[i - 1] >= index)) return -1;
            indices[i] = index;
            rank += chooseSmall(@intCast(index), i + 1);
        }
    } else {
        if (length != 4) return -1;
        rank = input[3];
        if (rank < 0 or rank >= chooseSmall(n, k)) return -1;
        var upper: isize = @as(isize, @intCast(n)) - 1;
        var remainder = rank;
        var order = k;
        while (order > 0) {
            var candidate = upper;
            while (candidate >= 0 and chooseSmall(@intCast(candidate), order) > remainder) candidate -= 1;
            if (candidate < 0) return -1;
            indices[order - 1] = @intCast(candidate);
            remainder -= chooseSmall(@intCast(candidate), order);
            upper = candidate - 1;
            order -= 1;
        }
    }

    const needed = (k + 1) * 8;
    if (@intFromPtr(output) == 0 or capacity < needed) return -2;
    storeI64Le(output, 0, rank);
    for (0..k) |i| storeI64Le(output, i + 1, indices[i]);
    return @intCast(needed);
}
