fn lessHead(values: [16][16]i64, positions: [16]usize, a: usize, b: usize) bool {
    const left = values[a][positions[a]];
    const right = values[b][positions[b]];
    return left < right or (left == right and a < b);
}

fn siftDown(heap: *[16]usize, size: usize, initial_root: usize, values: [16][16]i64, positions: [16]usize) void {
    var root = initial_root;
    while (true) {
        var child = root * 2 + 1;
        if (child >= size) return;
        if (child + 1 < size and lessHead(values, positions, heap[child + 1], heap[child])) child += 1;
        if (!lessHead(values, positions, heap[child], heap[root])) return;
        const swap = heap[root]; heap[root] = heap[child]; heap[child] = swap;
        root = child;
    }
}

export fn smallest_range(packed: ?[*]const i64, length: usize) i64 {
    if (length < 2 or length > 273) return -1;
    const input = packed orelse return -1;
    if (input[0] < 1 or input[0] > 16) return -1;
    const count: usize = @intCast(input[0]);
    var values: [16][16]i64 = @splat(@splat(0));
    var lengths: [16]usize = @splat(0);
    var positions: [16]usize = @splat(0);
    var heap: [16]usize = @splat(0);
    var offset: usize = 1;
    var total: usize = 0;
    var current_max: i64 = -1_000_000_001;
    for (0..count) |i| {
        if (offset >= length or input[offset] < 1 or input[offset] > 16) return -1;
        lengths[i] = @intCast(input[offset]); offset += 1;
        if (lengths[i] > 256 - total or offset + lengths[i] > length) return -1;
        total += lengths[i];
        for (0..lengths[i]) |j| {
            const value = input[offset]; offset += 1;
            if (value < -1_000_000_000 or value > 1_000_000_000 or (j > 0 and value < values[i][j - 1])) return -1;
            values[i][j] = value;
        }
        heap[i] = i;
        current_max = @max(current_max, values[i][0]);
    }
    if (offset != length) return -1;
    const heap_size = count;
    var start = heap_size / 2;
    while (start > 0) { start -= 1; siftDown(&heap, heap_size, start, values, positions); }
    var best_lo: i64 = 0;
    var best_hi: i64 = 0;
    var best_width: i64 = std.math.maxInt(i64);
    while (true) {
        const list = heap[0];
        const lo = values[list][positions[list]];
        const width = current_max - lo;
        if (width < best_width) { best_width = width; best_lo = lo; best_hi = current_max; }
        positions[list] += 1;
        if (positions[list] == lengths[list]) break;
        current_max = @max(current_max, values[list][positions[list]]);
        siftDown(&heap, heap_size, 0, values, positions);
    }
    return (best_lo + 1_000_000_000) * 2_000_000_001 + best_hi + 1_000_000_000;
}

const std = @import("std");
