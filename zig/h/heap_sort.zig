fn sift_down(values: [*]i64, root_value: usize, end: usize) void {
    var root = root_value;
    while (root < end / 2) {
        var child = root * 2 + 1;
        if (child + 1 < end and values[child] < values[child + 1]) child += 1;
        if (values[root] >= values[child]) break;
        const temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

/// In-place max-heap sort with a zero-based heap.
export fn heap_sort(values: [*]i64, length: usize) void {
    var start = length / 2;
    while (start > 0) {
        start -= 1;
        sift_down(values, start, length);
    }
    var end = length;
    while (end > 1) {
        end -= 1;
        const temporary = values[0];
        values[0] = values[end];
        values[end] = temporary;
        sift_down(values, 0, end);
    }
}
