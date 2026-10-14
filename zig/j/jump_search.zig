/// Integer square root used to select the jump width without a platform math dependency.
fn integer_sqrt(value: usize) usize {
    if (value < 2) return value;
    var low: usize = 1;
    var high = value / 2 + 1;
    var result: usize = 1;
    while (low <= high) {
        const middle = low + (high - low) / 2;
        if (middle <= value / middle) {
            result = middle;
            low = middle + 1;
        } else {
            high = middle - 1;
        }
    }
    return result;
}

/// C ABI entry point for jump search on an ascending sequence.
export fn jump_search(values: [*]const i64, length: usize, target: i64) i64 {
    if (length == 0) return -1;
    const slice = values[0..length];
    const step = integer_sqrt(length);
    var block_start: usize = 0;
    var block_end = @min(step, length);
    while (slice[block_end - 1] < target) {
        if (block_end == length) return -1;
        block_start = block_end;
        block_end = if (step > length - block_end) length else block_end + step;
    }
    for (block_start..block_end) |index| {
        if (slice[index] == target) return @intCast(index);
        if (slice[index] > target) return -1;
    }
    return -1;
}
