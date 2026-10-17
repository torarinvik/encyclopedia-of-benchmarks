const MAX_INPUT_VALUES: usize = 131;
const MAX_VALIDATORS: i64 = 128;
const MAX_STAKE: i64 = 1_000_000;
const MAX_TOTAL_STAKE: i64 = 128_000_000;

export fn roulette_wheel_selection(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_VALUES) return -1;
    const values = input.?[0..length];

    const count_value = values[0];
    if (count_value < 1 or count_value > MAX_VALIDATORS) return -1;
    const count: usize = @intCast(count_value);
    if (length != count + 2) return -1;

    var total: i64 = 0;
    for (0..count) |index| {
        const stake = values[1 + index];
        if (stake < 1 or stake > MAX_STAKE) return -1;
        if (total > MAX_TOTAL_STAKE - stake) return -1;
        total += stake;
    }

    const ticket = values[1 + count];
    if (ticket < 0 or ticket >= total) return -1;

    var cumulative: i64 = 0;
    for (0..count) |index| {
        cumulative += values[1 + index];
        if (ticket < cumulative) return @as(i64, @intCast(index + 1));
    }
    return -1;
}
