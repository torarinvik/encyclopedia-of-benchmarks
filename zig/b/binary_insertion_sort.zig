/// Stable binary insertion sort using an upper-bound search for each key.
export fn binary_insertion_sort(values: [*]i64, length: usize) void {
    var index: usize = 1;
    while (index < length) : (index += 1) {
        const key = values[index];
        var low: usize = 0;
        var high = index;
        while (low < high) {
            const middle = low + (high - low) / 2;
            if (values[middle] <= key) {
                low = middle + 1;
            } else {
                high = middle;
            }
        }
        var position = index;
        while (position > low) : (position -= 1) {
            values[position] = values[position - 1];
        }
        values[low] = key;
    }
}
