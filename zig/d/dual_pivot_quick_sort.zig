fn dualPivotSortRange(values: [*]i64, low_value: usize, high_value: usize) void {
    var low = low_value;
    var high = high_value;
    while (high - low > 2) {
        if (values[low] > values[high - 1]) {
            const temporary = values[low];
            values[low] = values[high - 1];
            values[high - 1] = temporary;
        }
        const pivot1 = values[low];
        const pivot2 = values[high - 1];
        var less = low + 1;
        var scan = low + 1;
        var greater = high - 2;
        while (scan <= greater) {
            if (values[scan] < pivot1) {
                const temporary = values[scan];
                values[scan] = values[less];
                values[less] = temporary;
                less += 1;
            } else if (values[scan] >= pivot2) {
                while (scan < greater and values[greater] > pivot2) : (greater -= 1) {}
                const temporary = values[scan];
                values[scan] = values[greater];
                values[greater] = temporary;
                greater -= 1;
                if (values[scan] < pivot1) {
                    const second_temporary = values[scan];
                    values[scan] = values[less];
                    values[less] = second_temporary;
                    less += 1;
                }
            }
            scan += 1;
        }
        const pivot1_index = less - 1;
        const pivot2_index = greater + 1;
        const first_temporary = values[low];
        values[low] = values[pivot1_index];
        values[pivot1_index] = first_temporary;
        const second_temporary = values[high - 1];
        values[high - 1] = values[pivot2_index];
        values[pivot2_index] = second_temporary;
        const left_size = pivot1_index - low;
        const middle_size = pivot2_index - pivot1_index - 1;
        const right_size = high - pivot2_index - 1;
        if (left_size >= middle_size and left_size >= right_size) {
            dualPivotSortRange(values, pivot1_index + 1, pivot2_index);
            dualPivotSortRange(values, pivot2_index + 1, high);
            high = pivot1_index;
        } else if (middle_size >= right_size) {
            dualPivotSortRange(values, low, pivot1_index);
            dualPivotSortRange(values, pivot2_index + 1, high);
            low = pivot1_index + 1;
            high = pivot2_index;
        } else {
            dualPivotSortRange(values, low, pivot1_index);
            dualPivotSortRange(values, pivot1_index + 1, pivot2_index);
            low = pivot2_index + 1;
        }
    }
    if (high - low == 2 and values[low] > values[low + 1]) {
        const temporary = values[low];
        values[low] = values[low + 1];
        values[low + 1] = temporary;
    }
}

/// In-place dual-pivot quicksort using the first and final values as pivots.
export fn dual_pivot_quick_sort(values: [*]i64, length: usize) void {
    if (length > 1) dualPivotSortRange(values, 0, length);
}
