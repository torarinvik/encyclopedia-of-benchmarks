/// Remove a node by one-based distance from the tail in an index-based list.
const MAX_LIST_LENGTH: usize = 1024;
const NONE: usize = MAX_LIST_LENGTH;

export fn remove_nth_node_from_end_of_list(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_LIST_LENGTH + 1) return -1;
    const list_length = length - 1;
    for (0..list_length) |index| {
        if (input[index + 1] < -2147483648 or input[index + 1] > 2147483647) return -1;
    }
    const position = input[0];
    if (position < 1 or @as(u64, @intCast(position)) > list_length) return -1;

    var next_node: [MAX_LIST_LENGTH]usize = undefined;
    for (0..list_length) |index| {
        next_node[index] = if (index + 1 < list_length) index + 1 else NONE;
    }
    var node: usize = 0;
    var counted: usize = 0;
    while (node != NONE) {
        node = next_node[node];
        counted += 1;
    }
    if (counted != list_length) return -1;

    const steps_to_target = counted - @as(usize, @intCast(position));
    var before: usize = NONE;
    node = 0;
    for (0..steps_to_target) |_| {
        before = node;
        node = next_node[node];
    }
    const head = if (before == NONE) next_node[node] else 0;
    if (before != NONE) next_node[before] = next_node[node];

    const output_count = counted - 1;
    const output_bytes = output_count * 4;
    if (output_capacity < output_bytes or (output_bytes != 0 and output == null)) return -2;
    node = head;
    var written: usize = 0;
    while (node != NONE) {
        const signed_value: i32 = @intCast(input[node + 1]);
        const bits: u32 = @bitCast(signed_value);
        for (0..4) |byte| {
            output[written * 4 + byte] = @truncate(bits >> @as(u5, @intCast(byte * 8)));
        }
        node = next_node[node];
        written += 1;
    }
    if (written != output_count) return -1;
    return @intCast(written);
}
