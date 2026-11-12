const std = @import("std");

const MAX_N: usize = 16;
const MAX_STATES: usize = 1 << MAX_N;
const MAX_OUTPUT_WORDS: usize = 2 + MAX_N;
const MAX_INPUT_VALUES: usize = 2 + 3 * (MAX_N * (MAX_N - 1) / 2) + 1;
const MAX_WEIGHT: i64 = 1_000_000;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn general_weighted_matching(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_VALUES) return -1;
    const n_value = input[0];
    const m_value = input[1];
    if (n_value < 1 or n_value > MAX_N or m_value < 0 or m_value > n_value * (n_value - 1) / 2) return -1;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    if (length != 2 + 3 * m) return -1;

    var weights: [MAX_N][MAX_N]i64 = std.mem.zeroes([MAX_N][MAX_N]i64);
    var present: [MAX_N][MAX_N]bool = std.mem.zeroes([MAX_N][MAX_N]bool);
    var cursor: usize = 2;
    for (0..m) |_| {
        const u_value = input[cursor];
        const v_value = input[cursor + 1];
        const edge_weight = input[cursor + 2];
        cursor += 3;
        if (u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value or
            u_value == v_value or edge_weight < 1 or edge_weight > MAX_WEIGHT) return -1;
        const u: usize = @intCast(u_value);
        const v: usize = @intCast(v_value);
        if (present[u][v]) return -1;
        present[u][v] = true;
        present[v][u] = true;
        weights[u][v] = edge_weight;
        weights[v][u] = edge_weight;
    }

    var dp: [MAX_STATES]i64 = @splat(0);
    const state_count: usize = 1 << n;
    for (1..state_count) |mask| {
        const bit = mask & (~mask + 1);
        var vertex: usize = 0;
        while ((bit >> @intCast(vertex)) != 1) vertex += 1;
        const remainder = mask ^ bit;
        dp[mask] = dp[remainder];
        for (vertex + 1..n) |partner| {
            const partner_bit = @as(usize, 1) << @intCast(partner);
            if ((remainder & partner_bit) == 0 or !present[vertex][partner]) continue;
            const candidate = weights[vertex][partner] + dp[remainder ^ partner_bit];
            if (candidate > dp[mask]) dp[mask] = candidate;
        }
    }

    var words: [MAX_OUTPUT_WORDS]i64 = @splat(0);
    var pair_count: usize = 0;
    var mask = state_count - 1;
    while (mask != 0) {
        const bit = mask & (~mask + 1);
        var vertex: usize = 0;
        while ((bit >> @intCast(vertex)) != 1) vertex += 1;
        const remainder = mask ^ bit;
        if (dp[mask] == dp[remainder]) {
            mask = remainder;
            continue;
        }
        var selected: ?usize = null;
        for (vertex + 1..n) |partner| {
            const partner_bit = @as(usize, 1) << @intCast(partner);
            if ((remainder & partner_bit) != 0 and present[vertex][partner] and
                weights[vertex][partner] + dp[remainder ^ partner_bit] == dp[mask]) {
                selected = partner;
                break;
            }
        }
        const partner = selected orelse return -1;
        words[2 + 2 * pair_count] = @intCast(vertex);
        words[3 + 2 * pair_count] = @intCast(partner);
        pair_count += 1;
        mask = remainder ^ (@as(usize, 1) << @intCast(partner));
    }

    words[0] = @intCast(pair_count);
    words[1] = dp[state_count - 1];
    const output_words = 2 + 2 * pair_count;
    const output_bytes = 8 * output_words;
    if (output == null or capacity < output_bytes) return -2;
    for (0..output_words) |word| storeI64Le(output, 8 * word, words[word]);
    return @intCast(output_bytes);
}
