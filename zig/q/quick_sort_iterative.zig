fn quickSortIterativePartition(values: [*]i64, low: usize, high: usize) usize {
    const pivot = values[high - 1];
    var boundary = low;
    var scan = low;
    while (scan < high - 1) : (scan += 1) {
        if (values[scan] <= pivot) {
            const temporary = values[boundary];
            values[boundary] = values[scan];
            values[scan] = temporary;
            boundary += 1;
        }
    }
    const temporary = values[boundary];
    values[boundary] = values[high - 1];
    values[high - 1] = temporary;
    return boundary;
}

/// Iterative Lomuto quicksort using the final value as the pivot.
export fn quick_sort_iterative(values: [*]i64, length: usize) void {
    if (length < 2) return;

    var stack_low: [128]usize = undefined;
    var stack_high: [128]usize = undefined;
    var stack_size: usize = 0;
    var low: usize = 0;
    var high = length;
    while (true) {
        while (high - low > 1) {
            const pivot = quickSortIterativePartition(values, low, high);
            const left_size = pivot - low;
            const right_size = high - pivot - 1;
            if (left_size < right_size) {
                if (right_size > 1) {
                    stack_low[stack_size] = pivot + 1;
                    stack_high[stack_size] = high;
                    stack_size += 1;
                }
                high = pivot;
            } else {
                if (left_size > 1) {
                    stack_low[stack_size] = low;
                    stack_high[stack_size] = pivot;
                    stack_size += 1;
                }
                low = pivot + 1;
            }
        }
        if (stack_size == 0) break;
        stack_size -= 1;
        low = stack_low[stack_size];
        high = stack_high[stack_size];
    }
}
