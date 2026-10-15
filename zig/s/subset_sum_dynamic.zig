/// Memoized top-down subset existence for signed values.
const MAX_ITEMS: usize = 16;
const WIDTH: usize = 801;
const STATES: usize = (MAX_ITEMS + 1) * WIDTH;

fn search(input: []const i64, index: usize, remaining: i64, memo: *[STATES]i64) i64 {
    if (remaining == 0) return 1;
    if (index == input.len) return 0;
    const state: usize = index * WIDTH + @as(usize, @intCast(remaining + 400));
    if (memo[state] != -2) return memo[state];
    var result = search(input, index + 1, remaining - input[index], memo);
    if (result == 0) result = search(input, index + 1, remaining, memo);
    memo[state] = result;
    return result;
}

export fn subset_sum_dynamic(input: [*]const i64, length: usize) i64 {
    if (length == 0 or length > MAX_ITEMS + 1) return -1;
    const values = input[0..length];
    const target = values[0];
    if (target < -80 or target > 80) return -1;
    for (values[1..]) |value| {
        if (value < -20 or value > 20) return -1;
    }
    var memo: [STATES]i64 = @splat(-2);
    return search(values[1..], 0, target, &memo);
}
