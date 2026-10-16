const MAX_ARRAYS: usize = 16;
const MAX_TOTAL_VALUES: usize = 128;
const MAX_PARSEABLE_LENGTH: usize = 146;
const MIN_VALUE: i64 = -1_000_000;
const MAX_VALUE: i64 = 1_000_000;
const CHECKSUM_OFFSET: i64 = 1_000_001;

const HeapNode = struct {
    value: i64,
    array_index: usize,
    element_index: usize,
};

fn nodeLess(left: HeapNode, right: HeapNode) bool {
    if (left.value != right.value) return left.value < right.value;
    if (left.array_index != right.array_index) return left.array_index < right.array_index;
    return left.element_index < right.element_index;
}

fn heapPush(heap: *[MAX_ARRAYS]HeapNode, size: *usize, node: HeapNode) void {
    var index = size.*;
    size.* += 1;
    while (index > 0) {
        const parent = (index - 1) / 2;
        if (!nodeLess(node, heap.*[parent])) break;
        heap.*[index] = heap.*[parent];
        index = parent;
    }
    heap.*[index] = node;
}

fn heapPop(heap: *[MAX_ARRAYS]HeapNode, size: *usize) HeapNode {
    const result = heap.*[0];
    size.* -= 1;
    const last = heap.*[size.*];
    if (size.* > 0) {
        var index: usize = 0;
        while (index < size.* / 2) {
            var child = 2 * index + 1;
            if (child + 1 < size.* and nodeLess(heap.*[child + 1], heap.*[child])) child += 1;
            if (!nodeLess(heap.*[child], last)) break;
            heap.*[index] = heap.*[child];
            index = child;
        }
        heap.*[index] = last;
    }
    return result;
}

export fn merge_ksorted_arrays(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    if (values[0] < 1 or values[0] > @as(i64, @intCast(MAX_ARRAYS))) return -1;
    const array_count: usize = @intCast(values[0]);
    var starts: [MAX_ARRAYS]usize = undefined;
    var lengths: [MAX_ARRAYS]usize = undefined;
    var position: usize = 1;
    var total_values: usize = 0;
    for (0..array_count) |array_index| {
        if (position >= length) return -1;
        const declared = values[position];
        position += 1;
        if (declared < 0 or @as(usize, @intCast(declared)) > MAX_TOTAL_VALUES - total_values) return -1;
        const array_length: usize = @intCast(declared);
        if (array_length > length - position) return -1;
        starts[array_index] = position;
        lengths[array_index] = array_length;
        for (0..array_length) |index| {
            const value = values[position + index];
            if (value < MIN_VALUE or value > MAX_VALUE or
                (index > 0 and values[position + index - 1] > value)) return -1;
        }
        position += array_length;
        total_values += array_length;
    }
    if (position != length) return -1;

    var heap: [MAX_ARRAYS]HeapNode = undefined;
    var heap_size: usize = 0;
    for (0..array_count) |array_index| {
        if (lengths[array_index] > 0) {
            heapPush(&heap, &heap_size, .{
                .value = values[starts[array_index]],
                .array_index = array_index,
                .element_index = 0,
            });
        }
    }
    var checksum: i64 = 0;
    var merged_index: i64 = 0;
    while (heap_size > 0) {
        const node = heapPop(&heap, &heap_size);
        checksum += (merged_index + 1) * (node.value + CHECKSUM_OFFSET);
        merged_index += 1;
        const next_index = node.element_index + 1;
        if (next_index < lengths[node.array_index]) {
            heapPush(&heap, &heap_size, .{
                .value = values[starts[node.array_index] + next_index],
                .array_index = node.array_index,
                .element_index = next_index,
            });
        }
    }
    return checksum;
}
