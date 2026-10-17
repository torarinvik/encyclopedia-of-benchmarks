const MAX_INPUT_LENGTH: usize = 33;

export fn subset_count(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const input = values[0..length];
    const count_value = input[0];
    const target_value = input[1];
    if (count_value < 1 or count_value > 30 or target_value < 0 or target_value > 64) return -1;
    const count: usize = @intCast(count_value);
    if (length != count + 2) return -1;
    for (input[2..]) |value| {
        if (value < 0 or value > 64) return -1;
    }

    const target: usize = @intCast(target_value);
    var previous = [_]i64{0} ** 65;
    previous[0] = 1;
    const first_value: usize = @intCast(input[2]);
    if (first_value <= target) previous[first_value] = 1;

    for (input[3..]) |raw_value| {
        const value: usize = @intCast(raw_value);
        var current = [_]i64{0} ** 65;
        current[0] = 1;
        for (1..target + 1) |amount| {
            const not_taken = previous[amount];
            const taken = if (value <= amount) previous[amount - value] else 0;
            current[amount] = not_taken + taken;
        }
        previous = current;
    }
    return previous[target];
}
