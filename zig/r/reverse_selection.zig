/// Selection sort variant that reverses the selected prefix to place its minimum.
export fn reverse_selection(values: [*]i64, length: usize) void {
    if (length < 2) return;
    var start: usize = 0;
    while (start + 1 < length) : (start += 1) {
        var minimum = start;
        var scan = start + 1;
        while (scan < length) : (scan += 1) {
            if (values[scan] < values[minimum]) minimum = scan;
        }
        var left = start;
        var right = minimum;
        while (left < right) {
            const temporary = values[left];
            values[left] = values[right];
            values[right] = temporary;
            left += 1;
            right -= 1;
        }
    }
}
