/// Binary search in an ascending sequence for the shared benchmark contract.
fn binary_search_slice(values: []const i64, target: i64) i64 {
    var low: usize = 0;
    var high = values.len;

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
export fn binary_search(values: [*]const i64, length: usize, target: i64) i64 {
    return binary_search_slice(values[0..length], target);
}
