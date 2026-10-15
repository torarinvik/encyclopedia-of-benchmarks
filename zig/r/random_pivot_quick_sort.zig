fn randomPivotQuickSortNext31(state: *u64) u64 {
    state.* = (state.* * 48271) % 2147483647;
    return state.*;
}

fn randomPivotQuickSortNext(state: *u64) u64 {
    const high = randomPivotQuickSortNext31(state);
    const low = randomPivotQuickSortNext31(state);
    return high * 2147483647 + low;
}

fn randomPivotQuickSortPartition(values: [*]i64, low: usize, high: usize, state: *u64) usize {
    const width = high - low;
    const pivot_index = low + @as(usize, @intCast(randomPivotQuickSortNext(state) % width));
    const pivot_value = values[pivot_index];
    const pivot_slot = values[high - 1];
    values[high - 1] = pivot_value;
    values[pivot_index] = pivot_slot;
    var boundary = low;
    var scan = low;
    while (scan < high - 1) : (scan += 1) {
        if (values[scan] < pivot_value) {
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

/// Quicksort with a reproducible pseudorandom pivot stream.
export fn random_pivot_quick_sort(values: [*]i64, length: usize) void {
    if (length < 2) return;
    var stack_low: [128]usize = undefined;
    var stack_high: [128]usize = undefined;
    var stack_size: usize = 0;
    var low: usize = 0;
    var high = length;
    var random_state: u64 = 1;
    while (true) {
        while (high - low > 1) {
            const pivot = randomPivotQuickSortPartition(values, low, high, &random_state);
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
