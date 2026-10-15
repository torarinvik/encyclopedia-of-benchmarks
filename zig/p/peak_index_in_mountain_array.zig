/// Find the peak of a strict mountain array with binary search.
const MAX_ARRAY_LENGTH: usize = 100000;

export fn peak_index_in_mountain_array(values: [*]const i64, length: usize) i64 {
    if (length < 3 or length > MAX_ARRAY_LENGTH) return -1;
    var low: usize = 0;
    var high = length - 1;
    while (low < high) {
        const middle = low + (high - low) / 2;
        if (values[middle] < values[middle + 1]) low = middle + 1 else high = middle;
    }
    if (low == 0 or low + 1 == length) return -1;
    return @intCast(low);
}
