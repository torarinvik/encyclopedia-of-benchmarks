/// In-place cycle sort for signed 64-bit values.
export fn cycle_sort(values: [*]i64, length: usize) void {
    if (length < 2) return;
    var cycle_start: usize = 0;
    while (cycle_start < length - 1) : (cycle_start += 1) {
        var item = values[cycle_start];
        var position = cycle_start;
        var scan = cycle_start + 1;
        while (scan < length) : (scan += 1) {
            if (values[scan] < item) position += 1;
        }
        if (position == cycle_start) continue;
        while (position < length and item == values[position]) : (position += 1) {}
        if (position == length) continue;
        var temporary = values[position];
        values[position] = item;
        item = temporary;
        while (position != cycle_start) {
            position = cycle_start;
            scan = cycle_start + 1;
            while (scan < length) : (scan += 1) {
                if (values[scan] < item) position += 1;
            }
            while (position < length and item == values[position]) : (position += 1) {}
            if (position == length) break;
            temporary = values[position];
            values[position] = item;
            item = temporary;
        }
    }
}
