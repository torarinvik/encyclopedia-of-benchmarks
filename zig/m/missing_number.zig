/// Return the absent value from 0 through the number of supplied values.
const MAX_VALUES: usize = 1024;

export fn missing_number(values: [*]const i64, length: usize) i64 {
    if (length > MAX_VALUES) return -1;
    var seen: [MAX_VALUES + 1]bool = @splat(false);
    var actual_sum: i64 = 0;
    for (0..length) |index| {
        const value = values[index];
        if (value < 0 or value > length) return -1;
        const slot: usize = @intCast(value);
        if (seen[slot]) return -1;
        seen[slot] = true;
        actual_sum += value;
    }
    const n: i64 = @intCast(length);
    return @divExact(n * (n + 1), 2) - actual_sum;
}
