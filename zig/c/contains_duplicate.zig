/// Sort a private copy, then scan neighbors for duplicates.
const MAX_VALUES: usize = 1024;

fn siftDown(values: *[MAX_VALUES]i64, root_start: usize, length: usize) void {
    var root = root_start;
    while (root < length / 2) {
        var child = root * 2 + 1;
        if (child + 1 < length and values[child] < values[child + 1]) child += 1;
        if (values[root] >= values[child]) break;
        const temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

/// Accepts signed 32-bit values; returns 1 if any repeat, 0 otherwise, -1 if invalid.
export fn contains_duplicate(input: [*]const i64, length: usize) i64 {
    if (length > MAX_VALUES) return -1;
    var values: [MAX_VALUES]i64 = @splat(0);
    for (0..length) |index| {
        const value = input[index];
        if (value < std.math.minInt(i32) or value > std.math.maxInt(i32)) return -1;
        values[index] = value;
    }
    var start = length / 2;
    while (start > 0) {
        start -= 1;
        siftDown(&values, start, length);
    }
    var end = length;
    while (end > 1) {
        end -= 1;
        const temporary = values[0];
        values[0] = values[end];
        values[end] = temporary;
        siftDown(&values, 0, end);
    }
    var index: usize = 1;
    while (index < length) : (index += 1) {
        if (values[index - 1] == values[index]) return 1;
    }
    return 0;
}

const std = @import("std");
