fn partitionRange(values: [*]i64, low: usize, high: usize) usize {
    const pivot = values[low];
    var left = low;
    var right = high;
    while (true) {
        while (values[left] < pivot) left += 1;
        while (values[right] > pivot) right -= 1;
        if (left >= right) return right;
        const temporary = values[left];
        values[left] = values[right];
        values[right] = temporary;
        left += 1;
        right -= 1;
    }
}

fn partitionSortRange(values: [*]i64, low: usize, high: usize) void {
    if (low < high) {
        const split = partitionRange(values, low, high);
        partitionSortRange(values, low, split);
        partitionSortRange(values, split + 1, high);
    }
}

/// First-element-pivot quicksort using Hoare's partition scheme.
export fn partition_sort(values: [*]i64, length: usize) void {
    if (length > 1) partitionSortRange(values, 0, length - 1);
}
