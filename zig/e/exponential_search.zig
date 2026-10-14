/// Exponential search in an ascending sequence for the shared benchmark contract.
fn binary_search_range(values: []const i64, low_bound: usize, high_bound: usize, target: i64) i64 {
    var low = low_bound;
    var high = high_bound;
    while (low < high) {
        const middle = low + (high - low) / 2;
        const value = values[middle];
        if (value == target) {
            return @intCast(middle);
        }
        if (value < target) {
            low = middle + 1;
        } else {
            high = middle;
        }
    }
    return -1;
}

/// C ABI entry point used by the common search benchmark runner.
export fn exponential_search(values: [*]const i64, length: usize, target: i64) i64 {
    if (length == 0) {
        return -1;
    }
    const slice = values[0..length];
    var upper: usize = 1;
    while (upper < length and slice[upper] <= target) {
        if (upper > length / 2) {
            upper = length;
        } else {
            upper *= 2;
        }
    }
    return binary_search_range(slice, upper / 2, upper, target);
}
