const MAX_N: usize = 12;
const MAX_INPUT: usize = 26;
const MAX_PARSEABLE: usize = 27;

fn gcd(left: i64, right: i64) i64 {
    var a = left;
    var b = right;
    while (b != 0) {
        const remainder = @rem(a, b);
        a = b;
        b = remainder;
    }
    return a;
}

fn before(a: usize, b: usize, scores: *const [MAX_N]i64) bool {
    if (scores[a] != scores[b]) return scores[a] > scores[b];
    return a < b;
}

export fn dinkelbach_fixed_cardinality_ratio(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 2 or length > MAX_PARSEABLE) return -1;
    const n_value = input[0];
    const k_value = input[1];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_N)) or k_value < 1 or k_value > n_value) return -1;
    const n: usize = @intCast(n_value);
    const k: usize = @intCast(k_value);
    if (length != 2 + 2 * n or length > MAX_INPUT) return -1;

    var numerators: [MAX_N]i64 = @splat(0);
    var denominators: [MAX_N]i64 = @splat(0);
    for (0..n) |index| {
        const a_value = input[2 + 2 * index];
        const b_value = input[3 + 2 * index];
        if (a_value < 0 or a_value > 10000 or b_value < 1 or b_value > 10000) return -1;
        numerators[index] = a_value;
        denominators[index] = b_value;
    }

    var combination_count: usize = 1;
    for (0..k) |step| combination_count = combination_count * (n - step) / (step + 1);
    var ratio_numerator: i64 = 0;
    var ratio_denominator: i64 = 1;
    for (0..combination_count + 1) |_| {
        var scores: [MAX_N]i64 = @splat(0);
        var order: [MAX_N]usize = @splat(0);
        for (0..n) |index| {
            scores[index] = numerators[index] * ratio_denominator - ratio_numerator * denominators[index];
            order[index] = index;
        }
        for (1..n) |index| {
            const item = order[index];
            var position = index;
            while (position > 0 and before(item, order[position - 1], &scores)) {
                order[position] = order[position - 1];
                position -= 1;
            }
            order[position] = item;
        }

        var selected_numerator: i64 = 0;
        var selected_denominator: i64 = 0;
        for (0..k) |index| {
            selected_numerator += numerators[order[index]];
            selected_denominator += denominators[order[index]];
        }
        const residual = selected_numerator * ratio_denominator - ratio_numerator * selected_denominator;
        if (residual == 0) {
            const divisor = gcd(selected_numerator, selected_denominator);
            return (selected_numerator / divisor) * 120001 + selected_denominator / divisor;
        }
        if (residual < 0) return -1;
        const divisor = gcd(selected_numerator, selected_denominator);
        ratio_numerator = selected_numerator / divisor;
        ratio_denominator = selected_denominator / divisor;
    }
    return -1;
}
