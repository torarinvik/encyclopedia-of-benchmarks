/// SlowSort over an inclusive interval.
fn slowSortRange(values: [*]i64, first: usize, last: usize) void {
    if (first >= last) return;
    const middle = first + (last - first) / 2;
    slowSortRange(values, first, middle);
    slowSortRange(values, middle + 1, last);
    if (values[last] < values[middle]) {
        const temporary = values[last]; values[last] = values[middle]; values[middle] = temporary;
    }
    slowSortRange(values, first, last - 1);
}

export fn slow_sort(values: [*]i64, length: usize) void {
    if (length > 1) slowSortRange(values, 0, length - 1);
}
