const MAX_VALUES: usize = 100000;

fn siftDown(values: *[MAX_VALUES]i64, root_start: usize, end: usize) void {
    var root = root_start;
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

fn heapSort(values: *[MAX_VALUES]i64, length: usize) void {
    var start = length / 2;
    while (start > 0) {
        start -= 1;
        siftDown(values, start, length);
    }
    var end = length;
    while (end > 1) {
        end -= 1;
        const temporary = values[0];
        values[0] = values[end];
        values[end] = temporary;
        siftDown(values, 0, end);
    }
}

/// Return the smallest absent nonnegative value after sorting a local copy.
export fn mex(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > MAX_VALUES + 1) return -1;
    const count_value = input[0];
    if (count_value < 0 or count_value > @as(i64, MAX_VALUES) or length != @as(usize, @intCast(count_value)) + 1) return -1;
    const count: usize = @intCast(count_value);
    var values: [MAX_VALUES]i64 = @splat(0);
    for (0..count) |index| {
        const value = input[index + 1];
        if (value < -2147483648 or value > 2147483647) return -1;
        values[index] = value;
    }
    heapSort(&values, count);
    var candidate: i64 = 0;
    for (0..count) |index| {
        if (values[index] == candidate) candidate += 1;
    }
    return candidate;
}
