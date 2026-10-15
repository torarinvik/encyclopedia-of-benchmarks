/// Restore the max-heap property in values[root..end].
const MAX_LENGTH: usize = 512;

fn sift_down(values: *[MAX_LENGTH]i32, root_start: usize, end: usize) void {
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

/// Sort a local copy with portable heapsort, then index from the end.
export fn kth_largest_by_sort(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_LENGTH + 1) return -1;
    const count = length - 1;
    if (input[0] < 1 or input[0] > count) return -1;
    var values: [MAX_LENGTH]i32 = undefined;
    for (0..count) |index| {
        const value = input[index + 1];
        if (value < -2147483648 or value > 2147483647) return -1;
        values[index] = @intCast(value);
    }
    var start = count / 2;
    while (start > 0) {
        start -= 1;
        sift_down(&values, start, count);
    }
    var end = count;
    while (end > 1) {
        const temporary = values[0];
        values[0] = values[end - 1];
        values[end - 1] = temporary;
        end -= 1;
        sift_down(&values, 0, end);
    }
    return values[count - @as(usize, @intCast(input[0]))];
}
