const MAX_LIST_LENGTH: usize = 32;
const MAX_TOTAL_NODES: usize = 2 * MAX_LIST_LENGTH;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 2 + MAX_TOTAL_NODES + 1;

const Node = struct { value: i32, next: i32 };

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn merge_linked_lists(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const raw_first = values[0];
    const raw_second = values[1];
    if (raw_first < 0 or raw_first > @as(i64, @intCast(MAX_LIST_LENGTH)) or
        raw_second < 0 or raw_second > @as(i64, @intCast(MAX_LIST_LENGTH))) return -1;
    const first_length: usize = @intCast(raw_first);
    const second_length: usize = @intCast(raw_second);
    const total = first_length + second_length;
    if (total > MAX_TOTAL_NODES or length != 2 + total) return -1;

    var nodes: [MAX_TOTAL_NODES]Node = undefined;
    for (0..first_length) |index| {
        const value = values[2 + index];
        if (value < -2147483648 or value > 2147483647) return -1;
        nodes[index] = .{ .value = @intCast(value), .next = if (index + 1 < first_length) @intCast(index + 1) else -1 };
    }
    const second_start = first_length;
    for (0..second_length) |index| {
        const value = values[2 + first_length + index];
        if (value < -2147483648 or value > 2147483647) return -1;
        const node = second_start + index;
        nodes[node] = .{ .value = @intCast(value), .next = if (index + 1 < second_length) @intCast(node + 1) else -1 };
    }

    const head1: i32 = if (first_length == 0) -1 else 0;
    const head2: i32 = if (second_length == 0) -1 else @intCast(second_start);
    var temp1 = head1;
    var temp2 = head2;
    var holder2: i32 = -1;
    while (temp1 != -1 and temp2 != -1) {
        const holder1 = nodes[@intCast(temp1)].next;
        nodes[@intCast(temp1)].next = temp2;
        if (holder1 != -1) {
            holder2 = nodes[@intCast(temp2)].next;
            nodes[@intCast(temp2)].next = holder1;
        }
        temp1 = holder1;
        temp2 = holder2;
    }

    var output_count: usize = 0;
    var node = head1;
    while (node != -1) {
        if (node < 0 or @as(usize, @intCast(node)) >= total or output_count >= total) return -1;
        output_count += 1;
        node = nodes[@intCast(node)].next;
    }
    const required = output_count * 8;
    if (output == null or output_capacity < required) return -2;

    node = head1;
    for (0..output_count) |index| {
        storeI64Le(output, 8 * index, @as(i64, nodes[@intCast(node)].value));
        node = nodes[@intCast(node)].next;
    }
    return @intCast(required);
}
