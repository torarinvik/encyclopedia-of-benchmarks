const MAX_ARRAY_LENGTH: usize = 256;
const MAX_INPUT_LENGTH: usize = MAX_ARRAY_LENGTH + 1;
const INT32_MIN: i64 = -2147483648;
const INT32_MAX: i64 = 2147483647;

export fn how_many_times_rotated(input: [*c]const i64, length: usize) i64 {
    if (length > MAX_INPUT_LENGTH) return -1;
    if (length > MAX_ARRAY_LENGTH) return -1;
    if (length == 0) return 0;
    if (input == null) return -1;
    for (0..length) |index| {
        if (input[index] < INT32_MIN or input[index] > INT32_MAX) return -1;
    }

    var low: usize = 0;
    var high: usize = if (length == 0) 0 else length - 1;
    while (low < high) {
        const middle = low + (high - low) / 2;
        if (input[middle] > input[high]) low = middle + 1;
        else high = middle;
    }
    return @intCast(low);
}
