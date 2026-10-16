const std = @import("std");
const INVALID_RESULT = std.math.minInt(i64);

fn siftDown(heap: []i64, root0: usize, min_heap: bool) void {
    var root = root0;
    while (true) {
        var best = root;
        const left = root * 2 + 1;
        const right = left + 1;
        if (left < heap.len and (if (min_heap) heap[left] < heap[best] else heap[left] > heap[best])) best = left;
        if (right < heap.len and (if (min_heap) heap[right] < heap[best] else heap[right] > heap[best])) best = right;
        if (best == root) return;
        std.mem.swap(i64, &heap[root], &heap[best]);
        root = best;
    }
}

export fn kth_element_finder(input: [*]const i64, length: usize) i64 {
    if (length < 4 or length > 259) return INVALID_RESULT;
    const mode = input[0];
    const n_value = input[1];
    const k_value = input[2];
    if ((mode != 0 and mode != 1) or n_value < 1 or n_value > 256 or
        k_value < 1 or k_value > n_value or length != @as(usize, @intCast(n_value)) + 3) {
        return INVALID_RESULT;
    }
    const n: usize = @intCast(n_value);
    const k: usize = @intCast(k_value);
    for (0..n) |i| {
        if (input[i + 3] < -1_000_000 or input[i + 3] > 1_000_000) return INVALID_RESULT;
    }

    const min_heap = mode == 0;
    var heap: [256]i64 = @splat(0);
    for (0..k) |i| heap[i] = input[i + 3];
    var start = k / 2;
    while (start > 0) {
        start -= 1;
        siftDown(heap[0..k], start, min_heap);
    }
    for (k..n) |i| {
        const value = input[i + 3];
        if ((min_heap and value > heap[0]) or (!min_heap and value < heap[0])) {
            heap[0] = value;
            siftDown(heap[0..k], 0, min_heap);
        }
    }
    return heap[0];
}
