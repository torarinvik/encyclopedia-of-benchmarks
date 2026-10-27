const MAX_N: usize = 5;
const MAX_STATES: usize = 3840;
const MAX_MOVES: usize = 10;
const MAX_OUTPUT_BYTES: usize = 168;

fn store_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn encode(permutation: *const [MAX_N]i64, n: usize) usize {
    var rank: usize = 0;
    var signs: usize = 0;
    for (0..n) |i| {
        const signed = permutation[i];
        const value: usize = @intCast(if (signed < 0) -signed else signed);
        var smaller: usize = 0;
        for (i + 1..n) |j| {
            const other = permutation[j];
            if ((if (other < 0) -other else other) < @as(i64, @intCast(value))) smaller += 1;
        }
        rank = rank * (n - i) + smaller;
        if (signed < 0) signs |= @as(usize, 1) << @intCast(value - 1);
    }
    return rank * (@as(usize, 1) << @intCast(n)) + signs;
}

fn decode_state(state: usize, n: usize, factorials: *const [MAX_N + 1]usize,
                permutation: *[MAX_N]i64) void {
    const sign_count = @as(usize, 1) << @intCast(n);
    var rank = state / sign_count;
    const signs = state % sign_count;
    var available: [MAX_N]usize = @splat(0);
    for (0..n) |i| available[i] = i + 1;
    var remaining = n;
    for (0..n) |i| {
        const factor = factorials[n - i - 1];
        const digit = rank / factor;
        rank %= factor;
        const value = available[digit];
        for (digit..remaining - 1) |j| available[j] = available[j + 1];
        remaining -= 1;
        const bit = (@as(usize, 1) << @intCast(value - 1));
        permutation[i] = if (signs & bit != 0) -@as(i64, @intCast(value)) else @intCast(value);
    }
}

fn reverse_signed(permutation: *[MAX_N]i64, left_start: usize, right_start: usize) void {
    var left = left_start;
    var right = right_start;
    while (left < right) {
        const a = permutation[left];
        const b = permutation[right];
        permutation[left] = -b;
        permutation[right] = -a;
        left += 1;
        right -= 1;
    }
    if (left == right) permutation[left] = -permutation[left];
}

export fn signed_permutation_reversal_sequence(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_N + 1) return -1;
    const input = input_opt.?;
    const raw_n = input[0];
    if (raw_n < 2 or raw_n > @as(i64, MAX_N) or length != @as(usize, @intCast(raw_n + 1))) return -1;
    const n: usize = @intCast(raw_n);
    var seen: usize = 0;
    var permutation: [MAX_N]i64 = @splat(0);
    for (0..n) |i| {
        const value = input[i + 1];
        if (value == 0 or value < -raw_n or value > raw_n) return -1;
        const absolute: usize = @intCast(if (value < 0) -value else value);
        const bit = @as(usize, 1) << @intCast(absolute - 1);
        if (seen & bit != 0) return -1;
        seen |= bit;
        permutation[i] = value;
    }
    if (seen != (@as(usize, 1) << @intCast(n)) - 1) return -1;
    if (output_opt == null) return -2;
    const output = output_opt.?;

    const factorials: [MAX_N + 1]usize = .{ 1, 1, 2, 6, 24, 120 };
    const state_count = factorials[n] * (@as(usize, 1) << @intCast(n));
    var parent: [MAX_STATES]i32 = @splat(-2);
    var queue: [MAX_STATES]i32 = @splat(0);
    var move_left: [MAX_STATES]i8 = @splat(0);
    var move_right: [MAX_STATES]i8 = @splat(0);
    for (0..state_count) |state| parent[state] = -2;
    const start = encode(&permutation, n);
    var head: usize = 0;
    var tail: usize = 0;
    parent[start] = -1;
    queue[tail] = @intCast(start);
    tail += 1;
    while (head < tail and parent[0] == -2) {
        const current: usize = @intCast(queue[head]);
        head += 1;
        var current_permutation: [MAX_N]i64 = @splat(0);
        decode_state(current, n, &factorials, &current_permutation);
        for (0..n) |left| {
            if (parent[0] != -2) break;
            for (left..n) |right| {
                var neighbor = current_permutation;
                reverse_signed(&neighbor, left, right);
                const next = encode(&neighbor, n);
                if (parent[next] != -2) continue;
                parent[next] = @intCast(current);
                move_left[next] = @intCast(left + 1);
                move_right[next] = @intCast(right + 1);
                queue[tail] = @intCast(next);
                tail += 1;
                if (next == 0) break;
            }
        }
    }
    if (parent[0] == -2) return -1;
    var reverse_left: [MAX_MOVES]i64 = @splat(0);
    var reverse_right: [MAX_MOVES]i64 = @splat(0);
    var move_count: usize = 0;
    var current: usize = 0;
    while (parent[current] >= 0) {
        if (move_count == MAX_MOVES) return -1;
        reverse_left[move_count] = move_left[current];
        reverse_right[move_count] = move_right[current];
        move_count += 1;
        current = @intCast(parent[current]);
    }
    const output_bytes = 8 * (1 + 2 * move_count);
    if (capacity < output_bytes) return -2;
    var staged: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    store_i64_le(&staged, 0, @intCast(move_count));
    for (0..move_count) |i| {
        const reverse_index = move_count - 1 - i;
        store_i64_le(&staged, 8 * (1 + 2 * i), reverse_left[reverse_index]);
        store_i64_le(&staged, 8 * (2 + 2 * i), reverse_right[reverse_index]);
    }
    for (0..output_bytes) |byte| output[byte] = staged[byte];
    return @intCast(output_bytes);
}
