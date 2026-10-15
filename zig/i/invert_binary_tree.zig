/// Recursively swap each node's children in a copied indexed binary tree.
const MAX_NODE_COUNT: usize = 1023;
const MAX_TREE_HEIGHT: usize = 512;

fn validate_subtree(values: [*c]const i64, node_count: usize, index: i64, depth: usize,
                    visited: []bool) bool {
    if (index == -1) return true;
    if (index < 0 or @as(u64, @intCast(index)) >= node_count or depth > MAX_TREE_HEIGHT) return false;
    const node: usize = @intCast(index);
    if (visited[node]) return false;
    visited[node] = true;
    const offset = 1 + 3 * node;
    const value = values[offset];
    const left = values[offset + 1];
    const right = values[offset + 2];
    if (value < -2147483648 or value > 2147483647 or left < -1 or right < -1 or
        (left >= 0 and @as(u64, @intCast(left)) >= node_count) or
        (right >= 0 and @as(u64, @intCast(right)) >= node_count)) return false;
    return validate_subtree(values, node_count, left, depth + 1, visited) and
        validate_subtree(values, node_count, right, depth + 1, visited);
}

fn store_i64_little_endian(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(8 * byte)));
}

fn emit_mirrored_subtree(values: [*c]const i64, index: i64, output: [*c]u8) void {
    if (index == -1) return;
    const input_offset = 1 + 3 * @as(usize, @intCast(index));
    const output_offset = 24 * @as(usize, @intCast(index));
    const left = values[input_offset + 1];
    const right = values[input_offset + 2];
    store_i64_little_endian(output, output_offset, values[input_offset]);
    store_i64_little_endian(output, output_offset + 8, right);
    store_i64_little_endian(output, output_offset + 16, left);
    emit_mirrored_subtree(values, right, output);
    emit_mirrored_subtree(values, left, output);
}

export fn invert_binary_tree(values: [*c]const i64, length: usize,
                             output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 1 or (length - 1) % 3 != 0 or
        length > 1 + 3 * MAX_NODE_COUNT) return -1;
    const node_count = (length - 1) / 3;
    const root = values[0];
    if (node_count == 0) return if (root == -1) 0 else -1;
    if (root < 0 or @as(u64, @intCast(root)) >= node_count) return -1;
    var visited = [_]bool{false} ** MAX_NODE_COUNT;
    if (!validate_subtree(values, node_count, root, 1, visited[0..node_count])) return -1;
    for (visited[0..node_count]) |seen| if (!seen) return -1;
    const required = 24 * node_count;
    if (output == null or output_capacity < required) return -2;
    emit_mirrored_subtree(values, root, output);
    return @intCast(node_count);
}
