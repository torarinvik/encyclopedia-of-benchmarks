/// Independent port of the class-W NAS Parallel Benchmarks Integer Sort.
const TOTAL_KEYS: usize = 1 << 20;
const MAX_KEY: usize = 1 << 16;
const NUM_BUCKETS: usize = 1 << 10;
const MAX_ITERATIONS: usize = 10;
const MAX_PASSES: i64 = 10;
const TEST_INDICES = [_]usize{ 357773, 934767, 875723, 898999, 404505 };
const BASELINE_RANKS = [_]u32{ 1249, 11698, 1039987, 1043896, 1048018 };

var key_array: [TOTAL_KEYS]u32 = @splat(0);
var key_buff2: [TOTAL_KEYS]u32 = @splat(0);
var key_buff1: [MAX_KEY]u32 = @splat(0);
var bucket_size: [NUM_BUCKETS]u32 = @splat(0);
var bucket_ptrs: [NUM_BUCKETS]u32 = @splat(0);

fn nextState(state: u64) u64 {
    const two23: u64 = 1 << 23;
    const low_mask: u64 = two23 - 1;
    const state_mask: u64 = (1 << 46) - 1;
    const multiplier_high: u64 = 1220703125 / two23;
    const multiplier_low: u64 = 1220703125 % two23;
    const x1 = state >> 23;
    const x2 = state & low_mask;
    const t1 = multiplier_high * x2 + multiplier_low * x1;
    const z = t1 & low_mask;
    return ((z << 23) + multiplier_low * x2) & state_mask;
}

fn generateKeys() void {
    var state: u64 = 314159265;
    for (0..TOTAL_KEYS) |index| {
        var four_state_sum: u64 = 0;
        for (0..4) |_| {
            state = nextState(state);
            four_state_sum += state;
        }
        key_array[index] = @intCast(four_state_sum >> 32);
    }
}

fn expectedRank(index: usize, iteration: u32) u32 {
    if (index < 2)
        return @intCast(@as(i64, BASELINE_RANKS[index]) + @as(i64, iteration) - 2);
    return BASELINE_RANKS[index] - iteration;
}

fn decimalWidth(value_input: u32) usize {
    var value = value_input;
    var width: usize = 1;
    while (value >= 10) {
        value /= 10;
        width += 1;
    }
    return width;
}

fn appendDecimal(value_input: u32, output: [*]u8, position_input: usize) usize {
    var value = value_input;
    var position = position_input;
    var reversed: [10]u8 = @splat(0);
    var count: usize = 0;
    while (true) {
        reversed[count] = @intCast(48 + value % 10);
        count += 1;
        value /= 10;
        if (value == 0) break;
    }
    while (count > 0) {
        count -= 1;
        output[position] = reversed[count];
        position += 1;
    }
    return position;
}

fn rankPass(iteration: u32, partials: *[5]u32) void {
    const iteration_index: usize = @intCast(iteration);
    key_array[iteration_index] = iteration;
    key_array[iteration_index + MAX_ITERATIONS] = @as(u32, @intCast(MAX_KEY)) - iteration;
    @memset(&bucket_size, 0);
    for (0..TOTAL_KEYS) |index| bucket_size[@intCast(key_array[index] >> 6)] += 1;
    bucket_ptrs[0] = 0;
    for (1..NUM_BUCKETS) |bucket|
        bucket_ptrs[bucket] = bucket_ptrs[bucket - 1] + bucket_size[bucket - 1];
    for (0..TOTAL_KEYS) |index| {
        const key = key_array[index];
        const bucket: usize = @intCast(key >> 6);
        const position: usize = @intCast(bucket_ptrs[bucket]);
        key_buff2[position] = key;
        bucket_ptrs[bucket] += 1;
    }
    @memset(&key_buff1, 0);
    for (0..TOTAL_KEYS) |index| key_buff1[@intCast(key_buff2[index])] += 1;
    for (1..MAX_KEY) |key| key_buff1[key] += key_buff1[key - 1];
    for (0..5) |test| {
        const key: usize = key_array[TEST_INDICES[test]];
        partials[test] = if (key == 0) 0 else key_buff1[key - 1];
    }
}

fn fullVerify() bool {
    for (0..TOTAL_KEYS) |index| {
        const key: usize = key_buff2[index];
        key_buff1[key] -= 1;
        key_array[@intCast(key_buff1[key])] = @intCast(key);
    }
    for (1..TOTAL_KEYS) |index|
        if (key_array[index - 1] > key_array[index]) return false;
    return true;
}

export fn npb_is(pass_count: i64, output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (pass_count < 1 or pass_count > MAX_PASSES) return -1;
    const passes: u32 = @intCast(pass_count);
    if (output_opt == null) return -2;
    const output = output_opt.?;

    var staged: [353]u8 = @splat(0);
    generateKeys();
    var partials: [5]u32 = @splat(0);
    rankPass(1, &partials); // Untimed source warm-up.
    var passed_verification: u32 = 0;
    var position: usize = 0;
    for (1..@as(usize, passes) + 1) |iteration_usize| {
        const iteration: u32 = @intCast(iteration_usize);
        rankPass(iteration, &partials);
        var row_required: usize = 5;
        for (0..5) |test| row_required += decimalWidth(partials[test]);
        if (position + row_required > staged.len) return -2;
        for (0..5) |test| {
            if (partials[test] == expectedRank(test, iteration)) passed_verification += 1;
            position = appendDecimal(partials[test], staged[0..].ptr, position);
            if (test + 1 < 5) {
                staged[position] = ',';
                position += 1;
            }
        }
        staged[position] = '\n';
        position += 1;
    }
    if (fullVerify()) passed_verification += 1;
    if (passed_verification != 5 * passes + 1) passed_verification = 0;
    if (position + decimalWidth(passed_verification) + 1 > staged.len) return -2;
    position = appendDecimal(passed_verification, staged[0..].ptr, position);
    staged[position] = '\n';
    position += 1;
    if (output_capacity < position) return -2;
    for (0..position) |index| output[index] = staged[index];
    return @intCast(position);
}
