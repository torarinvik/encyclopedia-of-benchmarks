const MAX_NODES: usize = 64;
const Node = struct { value: i32, next: ?usize };

fn searchRecursion(nodes: []const Node, current: ?usize, key: i32) bool {
    const index = current orelse return false;
    return nodes[index].value == key or searchRecursion(nodes, nodes[index].next, key);
}

export fn search_singly_linked_list_recursion(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_NODES + 2) return -1;
    const values = input.?[0..length];
    const count_value = values[0];
    const key_value = values[1];
    if (count_value < 0 or count_value > MAX_NODES or length != @as(usize, @intCast(count_value)) + 2 or
        key_value < -2147483648 or key_value > 2147483647) return -1;
    const count: usize = @intCast(count_value);
    var nodes: [MAX_NODES]Node = undefined;
    for (0..count) |index| {
        const value = values[index + 2];
        if (value < -2147483648 or value > 2147483647) return -1;
        nodes[index] = .{ .value = @intCast(value), .next = if (index + 1 < count) index + 1 else null };
    }
    return if (searchRecursion(nodes[0..count], if (count == 0) null else 0, @intCast(key_value))) 1 else 0;
}
