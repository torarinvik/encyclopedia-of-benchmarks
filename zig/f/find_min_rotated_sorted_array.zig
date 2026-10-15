export fn find_min_rotated_sorted_array(values: [*]const i64, length: usize) i64 {
    if (length < 1 or length > 256) return -1;
    var low: usize = 0;
    var high: usize = length - 1;
    while (low < high) {
        const middle = low + (high - low) / 2;
        if (values[middle] <= values[high]) high = middle else low = middle + 1;
    }
    return values[low];
}
