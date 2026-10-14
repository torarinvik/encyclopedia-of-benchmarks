const TIM_SORT_RUN: usize = 32;

fn insertion_sort_run(values: []i64, low: usize, high: usize) void {
    var index = low + 1;
    while (index < high) : (index += 1) {
        const key = values[index];
        var cursor = index;
        while (cursor > low and values[cursor - 1] > key) : (cursor -= 1) {
            values[cursor] = values[cursor - 1];
        }
        values[cursor] = key;
    }
}

fn merge_runs(values: []i64, scratch: []i64, left: usize, middle: usize, right: usize) void {
    @memcpy(scratch[left..right], values[left..right]);
    var first = left;
    var second = middle;
    for (left..right) |output| {
        if (first == middle) {
            values[output] = scratch[second];
            second += 1;
        } else if (second == right or scratch[first] <= scratch[second]) {
            values[output] = scratch[first];
            first += 1;
        } else {
            values[output] = scratch[second];
            second += 1;
        }
    }
}

/// Stable bottom-up TimSort-style sort using caller-provided scratch storage.
export fn tim_sort(values: [*]i64, scratch: [*]i64, length: usize) void {
    if (length < 2) return;
    var start: usize = 0;
    while (start < length) {
        const remaining = length - start;
        const ending = if (remaining < TIM_SORT_RUN) length else start + TIM_SORT_RUN;
        insertion_sort_run(values[0..length], start, ending);
        start = ending;
    }

    var width = TIM_SORT_RUN;
    while (width < length) {
        var left: usize = 0;
        while (left < length) {
            const left_remaining = length - left;
            const middle = left + @min(width, left_remaining);
            const right_remaining = length - middle;
            const right = middle + @min(width, right_remaining);
            if (middle < right) {
                merge_runs(values[0..length], scratch[0..length], left, middle, right);
            }
            left = right;
        }
        if (width >= length - width) break;
        width *= 2;
    }
}
