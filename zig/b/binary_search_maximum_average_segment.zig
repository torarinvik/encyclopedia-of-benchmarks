const MAX_N: usize = 32;
const MAX_INPUT: usize = 35;
const INVALID_RESULT: i64 = -1_000_001;

fn feasible(input: [*c]const i64, n: usize, minimum_length: usize, threshold: i64) bool {
    var prefix: [MAX_N + 1]i64 = @splat(0);
    for (0..n) |index| {
        prefix[index + 1] = prefix[index] + 1000 * input[index + 2] - threshold;
    }
    var minimum_prefix: i64 = 9_223_372_036_854_775_807;
    var end = minimum_length;
    while (end <= n) : (end += 1) {
        const eligible_start = end - minimum_length;
        minimum_prefix = @min(minimum_prefix, prefix[eligible_start]);
        if (prefix[end] >= minimum_prefix) return true;
    }
    return false;
}

pub export fn binary_search_maximum_average_segment(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT) return INVALID_RESULT;
    const n_value = input[0];
    const minimum_value = input[1];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_N))
        or minimum_value < 1 or minimum_value > n_value) return INVALID_RESULT;
    const n: usize = @intCast(n_value);
    if (length != n + 2) return INVALID_RESULT;
    for (0..n) |index| {
        if (input[index + 2] < -1000 or input[index + 2] > 1000) return INVALID_RESULT;
    }

    var low: i64 = -1_000_000;
    var high: i64 = 1_000_001;
    while (high - low > 1) {
        const middle = low + @divTrunc(high - low, 2);
        if (feasible(input, n, @intCast(minimum_value), middle)) low = middle else high = middle;
    }
    return low;
}
