const INVALID_RESULT: i64 = -9223372036854775807 - 1;
const MAX_VALUES: usize = 1024;

/// Select the kth largest value by max-heap insertion and repeated removal.
export fn find_kth_number(values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > MAX_VALUES + 1) return INVALID_RESULT;
    const k = values[0];
    const count = length - 1;
    if (k < 1 or k > @as(i64, @intCast(count))) return INVALID_RESULT;
    var heap = [_]i32{0} ** MAX_VALUES;
    for (0..count) |i| {
        const input = values[i + 1];
        if (input < -2147483648 or input > 2147483647) return INVALID_RESULT;
        var index = i;
        heap[index] = @intCast(input);
        while (index > 0) {
            const parent = (index - 1) / 2;
            if (heap[parent] >= heap[index]) break;
            const temp = heap[parent]; heap[parent] = heap[index]; heap[index] = temp;
            index = parent;
        }
    }
    var heap_size = count;
    var removed: i64 = 1;
    while (removed < k) : (removed += 1) {
        heap_size -= 1;
        heap[0] = heap[heap_size];
        var index: usize = 0;
        while (index * 2 + 1 < heap_size) {
            var child = index * 2 + 1;
            if (child + 1 < heap_size and heap[child + 1] > heap[child]) child += 1;
            if (heap[index] >= heap[child]) break;
            const temp = heap[index]; heap[index] = heap[child]; heap[child] = temp;
            index = child;
        }
    }
    return heap[0];
}
