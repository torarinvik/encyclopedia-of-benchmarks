const MAX_LENGTH: usize = 4096;
const INT32_MIN_VALUE: i64 = -2_147_483_648;
const INT32_MAX_VALUE: i64 = 2_147_483_647;

fn isLocalMaximum(values: []const i64, index: usize) bool {
    if (index == 0) return values[0] > values[1];
    if (index == values.len - 1) return values[index] > values[index - 1];
    return values[index] > values[index - 1] and values[index] > values[index + 1];
}

fn countRange(values: []const i64, start: usize, ending: usize) i64 {
    if (start == ending) return if (isLocalMaximum(values, start)) 1 else 0;
    const middle = (start + ending) / 2;
    return countRange(values, start, middle) + countRange(values, middle + 1, ending);
}

/// Count strict local maxima using the pinned recursive partition.
export fn number_of_local_maximum_points(values: [*]const i64, length: usize) i64 {
    if (length == 0 or length > MAX_LENGTH) return -1;
    const data = values[0..length];
    for (data) |value| {
        if (value < INT32_MIN_VALUE or value > INT32_MAX_VALUE) return -1;
    }
    if (length == 1) return 0; // Source compares the sole element with undefined.
    return countRange(data, 0, length - 1);
}
