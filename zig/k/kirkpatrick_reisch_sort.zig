const MAX_ELEMENTS: usize = 256;
const MAX_BLOCKS: usize = 17;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 258;
const MAX_OUTPUT_BYTES: usize = 2048;

const HeapNode = struct {
    value: i64,
    block: usize,
    offset: usize,
};

fn heapLess(left: HeapNode, right: HeapNode) bool {
    if (left.value != right.value) return left.value < right.value;
    if (left.block != right.block) return left.block < right.block;
    return left.offset < right.offset;
}

fn heapPush(heap: *[MAX_BLOCKS]HeapNode, length: *usize, value: HeapNode) void {
    var position = length.*;
    length.* += 1;
    while (position > 0) {
        const parent = (position - 1) / 2;
        if (!heapLess(value, heap[parent])) break;
        heap[position] = heap[parent];
        position = parent;
    }
    heap[position] = value;
}

fn heapPop(heap: *[MAX_BLOCKS]HeapNode, length: *usize) HeapNode {
    const minimum = heap[0];
    length.* -= 1;
    const last = heap[length.*];
    if (length.* == 0) return minimum;
    var position: usize = 0;
    while (position * 2 + 1 < length.*) {
        var child = position * 2 + 1;
        if (child + 1 < length.* and heapLess(heap[child + 1], heap[child])) child += 1;
        if (!heapLess(heap[child], last)) break;
        heap[position] = heap[child];
        position = child;
    }
    heap[position] = last;
    return minimum;
}

fn writeI64Le(output: *[MAX_OUTPUT_BYTES]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte_index| {
        const shift: u6 = @intCast(byte_index * 8);
        output[offset + byte_index] = @truncate(bits >> shift);
    }
}

export fn kirkpatrick_reisch_sort(input: [*c]const i64, input_length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or input_length < 1 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 or input[0] > MAX_ELEMENTS) return -1;
    const count: usize = @intCast(input[0]);
    if (input_length != count + 1) return -1;

    var blocks = [_]i64{0} ** MAX_ELEMENTS;
    for (0..count) |index| blocks[index] = input[index + 1];
    var starts = [_]usize{0} ** MAX_BLOCKS;
    var lengths = [_]usize{0} ** MAX_BLOCKS;
    var block_count: usize = 0;
    var block_size: usize = 1;
    if (count > 1) {
        while ((block_size + 1) * (block_size + 1) <= count) block_size += 1;
        var start: usize = 0;
        while (start < count) : (start += block_size) {
            const length = @min(count - start, block_size);
            starts[block_count] = start;
            lengths[block_count] = length;
            block_count += 1;
            for (1..length) |index| {
                const value = blocks[start + index];
                var position = index;
                while (position > 0 and blocks[start + position - 1] > value) {
                    blocks[start + position] = blocks[start + position - 1];
                    position -= 1;
                }
                blocks[start + position] = value;
            }
        }
    } else if (count == 1) {
        starts[0] = 0;
        lengths[0] = 1;
        block_count = 1;
    }

    var sorted = [_]i64{0} ** MAX_ELEMENTS;
    var sorted_count: usize = 0;
    var heap = [_]HeapNode{.{ .value = 0, .block = 0, .offset = 0 }} ** MAX_BLOCKS;
    var heap_length: usize = 0;
    for (0..block_count) |block| {
        heapPush(&heap, &heap_length, .{ .value = blocks[starts[block]], .block = block, .offset = 0 });
    }
    while (heap_length > 0) {
        const current = heapPop(&heap, &heap_length);
        sorted[sorted_count] = current.value;
        sorted_count += 1;
        const next = current.offset + 1;
        if (next < lengths[current.block]) {
            heapPush(&heap, &heap_length, .{
                .value = blocks[starts[current.block] + next],
                .block = current.block,
                .offset = next,
            });
        }
    }

    const output_bytes = sorted_count * 8;
    if (output_bytes > MAX_OUTPUT_BYTES) return -1;
    if (output == null or capacity < output_bytes) return -2;
    var staged = [_]u8{0} ** MAX_OUTPUT_BYTES;
    for (0..sorted_count) |index| writeI64Le(&staged, index * 8, sorted[index]);
    if (output_bytes > 0) @memcpy(output[0..output_bytes], staged[0..output_bytes]);
    return @intCast(output_bytes);
}
