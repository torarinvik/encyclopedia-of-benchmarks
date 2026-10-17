/// Sort signed i32 values by inserting into and draining a bounded min-heap.
const MAX_COUNT: usize = 128;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 130;

fn heapPush(heap: *[MAX_COUNT]i32, size: *usize, value: i32) void {
    var child = size.*;
    size.* += 1;
    heap[child] = value;
    while (child > 0) {
        const parent = (child - 1) / 2;
        if (heap[parent] <= heap[child]) break;
        const temporary = heap[parent];
        heap[parent] = heap[child];
        heap[child] = temporary;
        child = parent;
    }
}

fn heapPop(heap: *[MAX_COUNT]i32, size: *usize) i32 {
    const minimum = heap[0];
    size.* -= 1;
    if (size.* == 0) return minimum;
    heap[0] = heap[size.*];
    var parent: usize = 0;
    while (true) {
        const left = 2 * parent + 1;
        if (left >= size.*) break;
        const right = left + 1;
        const smaller = if (right < size.* and heap[right] < heap[left]) right else left;
        if (heap[parent] <= heap[smaller]) break;
        const temporary = heap[parent];
        heap[parent] = heap[smaller];
        heap[smaller] = temporary;
        parent = smaller;
    }
    return minimum;
}

fn writeI32Le(output: [*]u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn priority_queue_sort(input: ?[*]const i64, length: usize,
                              output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const values = input.?;
    const raw_count = values[0];
    if (raw_count < 0 or raw_count > 128 or length != 1 + @as(usize, @intCast(raw_count))) return -1;
    const count: usize = @intCast(raw_count);
    for (0..count) |index| {
        if (values[index + 1] < -2147483648 or values[index + 1] > 2147483647) return -1;
    }
    const byte_count = 4 * count;
    if (output == null or output_capacity < byte_count) return -2;

    var heap: [MAX_COUNT]i32 = @splat(0);
    var heap_size: usize = 0;
    for (0..count) |index| heapPush(&heap, &heap_size, @intCast(values[index + 1]));
    const output_bytes = output.?;
    for (0..count) |index| writeI32Le(output_bytes, 4 * index, heapPop(&heap, &heap_size));
    return @intCast(byte_count);
}
