fn siftDown(heap: *[256]i64, count: usize, start: usize) void {
    var index = start;
    while (true) {
        var largest = index;
        const left = index * 2 + 1;
        const right = left + 1;
        if (left < count and heap[left] > heap[largest]) largest = left;
        if (right < count and heap[right] > heap[largest]) largest = right;
        if (largest == index) return;
        const temporary = heap[index]; heap[index] = heap[largest]; heap[largest] = temporary;
        index = largest;
    }
}
fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @intCast((bits >> @intCast(byte * 8)) & 0xff);
}
export fn heap_max_push_peek_pop(values: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (values == null or length < 2 or length > 257) return -1;
    const input = values.?[0..length];
    const raw_count = input[0];
    if (raw_count < 1 or raw_count > 256 or length != @as(usize, @intCast(raw_count)) + 1) return -1;
    const count: usize = @intCast(raw_count);
    var heap: [256]i64 = @splat(0);
    for (0..count) |index| {
        const value = input[index + 1];
        if (value < 1 or value > 1_000_000_000) return -1;
        var position = index;
        heap[position] = value;
        while (position > 0) {
            const parent = (position - 1) / 2;
            if (heap[parent] >= heap[position]) break;
            const temporary = heap[parent]; heap[parent] = heap[position]; heap[position] = temporary;
            position = parent;
        }
    }
    const output_bytes = 8 * count;
    if (output == null or output_capacity < output_bytes) return -2;
    const result = output.?[0..output_capacity];
    var remaining = count;
    for (0..count) |index| {
        storeI64Le(result.ptr, 8 * index, heap[0]);
        remaining -= 1;
        if (remaining > 0) { heap[0] = heap[remaining]; siftDown(&heap, remaining, 0); }
    }
    return @intCast(output_bytes);
}
