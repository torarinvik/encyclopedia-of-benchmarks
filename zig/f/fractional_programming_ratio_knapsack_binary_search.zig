const MAX_N: usize = 12;
const MAX_WEIGHT: usize = 32;
const MAX_PARSEABLE: usize = 27;
const SCALE: i64 = 1_000_000;
const MAX_SCALED_RATIO: i64 = 1_000_000_000;
const NEGATIVE_INFINITY: i64 = -2_305_843_009_213_693_952;

fn ratioFeasible(numerators: *const [MAX_N]i64, denominators: *const [MAX_N]i64,
                 n: usize, required_weight: usize, threshold: i64) bool {
    var current: [MAX_WEIGHT + 1]i64 = @splat(NEGATIVE_INFINITY);
    var next: [MAX_WEIGHT + 1]i64 = @splat(NEGATIVE_INFINITY);
    current[0] = 0;
    for (0..n) |item| {
        for (0..(required_weight + 1)) |weight| next[weight] = current[weight];
        const score = SCALE * numerators[item] - threshold * denominators[item];
        for (0..(required_weight + 1)) |weight| {
            if (current[weight] == NEGATIVE_INFINITY) continue;
            const sum_weight = weight + @as(usize, @intCast(denominators[item]));
            const target = @min(sum_weight, required_weight);
            const candidate = current[weight] + score;
            if (candidate > next[target]) next[target] = candidate;
        }
        current = next;
    }
    return current[required_weight] >= 0;
}

export fn fractional_programming_ratio_knapsack_binary_search(input_opt: ?[*]const i64,
                                                              length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 2 or length > MAX_PARSEABLE) return -1;
    const n_value = input[0];
    const required_value = input[1];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_N)) or required_value < 1 or
        required_value > @as(i64, @intCast(MAX_WEIGHT))) return -1;
    const n: usize = @intCast(n_value);
    const required_weight: usize = @intCast(required_value);
    if (length != 2 + 2 * n) return -1;

    var numerators: [MAX_N]i64 = @splat(0);
    var denominators: [MAX_N]i64 = @splat(0);
    var denominator_sum: i64 = 0;
    for (0..n) |item| {
        const numerator = input[2 + 2 * item];
        const denominator = input[3 + 2 * item];
        if (numerator < 0 or numerator > 1000 or denominator < 1 or denominator > 8) return -1;
        numerators[item] = numerator;
        denominators[item] = denominator;
        denominator_sum += denominator;
    }
    if (required_value > denominator_sum) return -1;

    var low: i64 = 0;
    var high: i64 = MAX_SCALED_RATIO + 1;
    while (high - low > 1) {
        const middle = low + @divTrunc(high - low, 2);
        if (ratioFeasible(&numerators, &denominators, n, required_weight, middle)) {
            low = middle;
        } else {
            high = middle;
        }
    }
    return low;
}
