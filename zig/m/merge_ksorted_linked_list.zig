const MAX_LISTS: usize = 16;
const MAX_TOTAL_NODES: usize = 128;
const MAX_INPUT_LENGTH: usize = 1 + MAX_LISTS + MAX_TOTAL_NODES;
const MAX_OUTPUT_BYTES: usize = 4 * MAX_TOTAL_NODES;

const HeapNode = struct {
    value: i64,
    list_index: usize,
    node_index: usize,
};

fn nodeLess(left: HeapNode, right: HeapNode) bool {
    if (left.value != right.value) return left.value < right.value;
    if (left.list_index != right.list_index) return left.list_index < right.list_index;
    return left.node_index < right.node_index;
}

fn heapPush(heap: *[MAX_LISTS]HeapNode, size: *usize, node: HeapNode) void {
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

fn heapPop(heap: *[MAX_LISTS]HeapNode, size: *usize) HeapNode {
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

fn putI32Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u32 = @bitCast(@as(i32, @intCast(value)));
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn merge_ksorted_linked_list(
    input: ?[*]const i64,
    length: usize,
    output: ?[*]u8,
    capacity: usize,
) i64 {
    if (input == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..length];
    if (values[0] < 0 or values[0] > 16) return -1;
    const list_count: usize = @intCast(values[0]);
    var starts: [MAX_LISTS]usize = @splat(0);
    var lengths: [MAX_LISTS]usize = @splat(0);
    var position: usize = 1;
    var total_nodes: usize = 0;
    for (0..list_count) |list| {
        if (position >= length) return -1;
        const declared = values[position];
        position += 1;
        if (declared < 0 or @as(usize, @intCast(declared)) > MAX_TOTAL_NODES - total_nodes) return -1;
        const list_length: usize = @intCast(declared);
        if (list_length > length - position) return -1;
        starts[list] = position;
        lengths[list] = list_length;
        for (0..list_length) |node| {
            const value = values[position + node];
            if (value < -2147483648 or value > 2147483647 or
                (node > 0 and values[position + node - 1] > value)) return -1;
        }
        position += list_length;
        total_nodes += list_length;
    }
    if (position != length) return -1;

    const output_bytes = 4 * total_nodes;
    if (output == null or capacity < output_bytes) return -2;

    var heap: [MAX_LISTS]HeapNode = undefined;
    var heap_size: usize = 0;
    for (0..list_count) |list| {
        if (lengths[list] > 0) {
            heapPush(&heap, &heap_size, .{
                .value = values[starts[list]],
                .list_index = list,
                .node_index = 0,
            });
        }
    }

    var buffer: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    var written: usize = 0;
    while (heap_size > 0) {
        const node = heapPop(&heap, &heap_size);
        putI32Le(&buffer[0], written, node.value);
        written += 4;
        const next_index = node.node_index + 1;
        if (next_index < lengths[node.list_index]) {
            heapPush(&heap, &heap_size, .{
                .value = values[starts[node.list_index] + next_index],
                .list_index = node.list_index,
                .node_index = next_index,
            });
        }
    }

    const result = output.?;
    for (0..output_bytes) |index| result[index] = buffer[index];
    return @intCast(output_bytes);
}
