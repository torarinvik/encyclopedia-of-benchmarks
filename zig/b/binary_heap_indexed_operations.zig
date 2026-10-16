/// Bounded operation stream for the source MinHeap API.
export fn binary_heap_indexed_operations(values: [*c]const i64, length: usize, output: [*c]u8, output_capacity: usize) i64 {
    if (length < 2 or values[0] < 1 or values[0] > 256 or values[1] < 0 or values[1] > 512 or length != 2 + @as(usize, @intCast(values[1])) * 3) return -1;
    var heap: [256]i64 = undefined;
    var size: usize = 0;
    var outputs: usize = 0;
    for (0..@intCast(values[1])) |index| {
        const op = values[2 + 3 * index];
        const a = values[3 + 3 * index];
        const b = values[4 + 3 * index];
        if (op == 0) {
            if (a < -2147483648 or a > 2147483647 or b != 0) return -1;
            if (size < @as(usize, @intCast(values[0]))) {
                heap[size] = a;
                var i = size;
                while (i > 0) { const parent = (i - 1) / 2; if (heap[parent] <= heap[i]) break; const t = heap[parent]; heap[parent] = heap[i]; heap[i] = t; i = parent; }
                size += 1;
            }
        } else if (op == 1 or op == 2) {
            if (a != 0 or b != 0 or (op == 1 and size == 0)) return -1;
            if (output == null or (outputs + 1) * 8 > output_capacity) return -2;
            const result: i64 = if (size == 0) 2147483647 else heap[0];
            if (op == 2 and size > 0) { size -= 1; heap[0] = heap[size]; if (size > 0) sift_down(&heap, size, 0); }
            put_i64_le(output, outputs, result);
            outputs += 1;
        } else if (op == 3) {
            if (a < 0 or a >= @as(i64, @intCast(size)) or b < -2147483648 or b > 2147483647 or b > heap[@intCast(a)]) return -1;
            heap[@intCast(a)] = b;
            var i: usize = @intCast(a);
            while (i > 0) { const parent = (i - 1) / 2; if (heap[parent] <= heap[i]) break; const t = heap[parent]; heap[parent] = heap[i]; heap[i] = t; i = parent; }
        } else if (op == 4) {
            if (a < 0 or a >= @as(i64, @intCast(size)) or b != 0) return -1;
            heap[@intCast(a)] = -2147483648;
            var i: usize = @intCast(a);
            while (i > 0) { const parent = (i - 1) / 2; if (heap[parent] <= heap[i]) break; const t = heap[parent]; heap[parent] = heap[i]; heap[i] = t; i = parent; }
            size -= 1;
            heap[0] = heap[size];
            if (size > 0) sift_down(&heap, size, 0);
        } else return -1;
    }
    return @intCast(outputs * 8);
}

fn sift_down(heap: *[256]i64, size: usize, start: usize) void {
    var i = start;
    while (true) {
        const left = 2 * i + 1;
        const right = left + 1;
        var smallest = i;
        if (left < size and heap[left] < heap[smallest]) smallest = left;
        if (right < size and heap[right] < heap[smallest]) smallest = right;
        if (smallest == i) return;
        const t = heap[i]; heap[i] = heap[smallest]; heap[smallest] = t;
        i = smallest;
    }
}
fn put_i64_le(output: [*c]u8, slot: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| output[slot * 8 + b] = @truncate(bits >> @intCast(8 * b));
}
