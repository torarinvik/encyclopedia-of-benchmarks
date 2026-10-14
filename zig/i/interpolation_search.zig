/// Interpolation search in an ascending sequence for the shared benchmark contract.
export fn interpolation_search(values: [*]const i64, length: usize, target: i64) i64 {
    if (length == 0) return -1;
    const slice = values[0..length];
    var low: usize = 0;
    var high = length - 1;
    while (low <= high) {
        const low_value = slice[low];
        const high_value = slice[high];
        if (target < low_value or target > high_value) return -1;
        if (low_value == high_value) return if (low_value == target) @intCast(low) else -1;
        const numerator = (target - low_value) * @as(i64, @intCast(high - low));
        const denominator = high_value - low_value;
        const position = low + @as(usize, @intCast(@divTrunc(numerator, denominator)));
        const value = slice[position];
        if (value == target) return @intCast(position);
        if (value < target) {
            low = position + 1;
        } else {
            if (position == 0) return -1;
            high = position - 1;
        }
    }
    return -1;
}
