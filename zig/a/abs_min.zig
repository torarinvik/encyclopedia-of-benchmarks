const MAX_VALUES: usize = 256;
const MAX_INPUT_VALUES: usize = MAX_VALUES + 1;
const VALUE_LIMIT: i64 = 1_000_000_000_000;

fn magnitude(value: i64) i64 { return if (value < 0) -value else value; }

fn selectAbsolute(values: [*]const i64, length: usize, choose_max: bool) i64 {
    if (length < 2 or length > MAX_INPUT_VALUES) return -1;
    const count_value = values[0];
    if (count_value < 1 or count_value > MAX_VALUES or length != @as(usize, @intCast(count_value)) + 1) return -1;
    for (1..length) |index| {
        if (values[index] < -VALUE_LIMIT or values[index] > VALUE_LIMIT) return -1;
    }
    var best = values[1];
    for (2..length) |index| {
        const candidate = values[index];
        if ((choose_max and magnitude(candidate) > magnitude(best)) or
            (!choose_max and magnitude(candidate) < magnitude(best))) best = candidate;
    }
    return best;
}

export fn abs_min_benchmark(values: [*]const i64, length: usize) i64 {
    return selectAbsolute(values, length, false);
}
