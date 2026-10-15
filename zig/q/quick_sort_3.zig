fn quickSort3Range(values: [*]i64, low_value: usize, high_value: usize) void {
    var low = low_value;
    var high = high_value;
    while (high - low > 1) {
        const pivot = values[high - 1];
        var less = low;
        var scan = low;
        var greater = high;
        while (scan < greater) {
            if (values[scan] < pivot) {
                const temporary = values[less];
                values[less] = values[scan];
                values[scan] = temporary;
                less += 1;
                scan += 1;
            } else if (values[scan] > pivot) {
                greater -= 1;
                const temporary = values[scan];
                values[scan] = values[greater];
                values[greater] = temporary;
            } else {
                scan += 1;
            }
        }
        if (less - low < high - greater) {
            quickSort3Range(values, low, less);
            low = greater;
        } else {
            quickSort3Range(values, greater, high);
            high = less;
        }
    }
}

/// In-place three-way quicksort using the final value as pivot.
export fn quick_sort_3(values: [*]i64, length: usize) void {
    if (length > 1) quickSort3Range(values, 0, length);
}
