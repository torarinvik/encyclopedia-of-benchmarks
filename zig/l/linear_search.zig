/// First-match linear search for the shared benchmark contract.
fn linear_search_slice(values: []const i64, target: i64) i64 {
    for (values, 0..) |value, index| {
        if (value == target) {
            // The benchmark contract limits input lengths to i64::MAX.
            return @intCast(index);
        }
    }

    return -1;
}

/// C ABI entry point used by the common benchmark runner.
export fn linear_search(values: [*]const i64, length: usize, target: i64) i64 {
    return linear_search_slice(values[0..length], target);
}
