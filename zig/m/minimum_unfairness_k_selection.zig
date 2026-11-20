const std = @import("std");

const MAX_N: usize = 64;
const MIN_VALUE: i64 = -1_000_000_000;
const MAX_VALUE: i64 = 1_000_000_000;

fn sift_down(values: *[MAX_N]i64, root_start: usize, ending: usize) void {
    var root = root_start;
    while (root < ending / 2) {
        var child = root * 2 + 1;
        if (child + 1 < ending and values[child] < values[child + 1]) child += 1;
        if (values[root] >= values[child]) break;
        std.mem.swap(i64, &values[root], &values[child]);
        root = child;
    }
}

fn heap_sort(values: *[MAX_N]i64, length: usize) void {
    var start = length / 2;
    while (start > 0) {
        start -= 1;
        sift_down(values, start, length);
    }
    var ending = length;
    while (ending > 1) {
        ending -= 1;
        std.mem.swap(i64, &values[0], &values[ending]);
        sift_down(values, 0, ending);
    }
}

export fn minimum_unfairness_k_selection(packed: ?[*]const i64, length: usize) i64 {
    if (packed == null or length < 4 or length > MAX_N + 2) return -1;
    const input = packed.?[0..length];
    const n_value = input[0];
    const k_value = input[1];
    if (n_value < 2 or n_value > @as(i64, @intCast(MAX_N)) or k_value < 2 or k_value > n_value
        or length != @as(usize, @intCast(n_value)) + 2) return -1;

    const n: usize = @intCast(n_value);
    const k: usize = @intCast(k_value);
    var sorted: [MAX_N]i64 = undefined;
    for (0..n) |index| {
        const value = input[index + 2];
        if (value < MIN_VALUE or value > MAX_VALUE) return -1;
        sorted[index] = value;
    }
    heap_sort(&sorted, n);

    var best: i64 = 2_000_000_001;
    for (0..n - k + 1) |first| {
        const width = sorted[first + k - 1] - sorted[first];
        if (width < best) best = width;
    }
    return best;
}
