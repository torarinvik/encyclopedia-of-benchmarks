const MAX_NODES: usize = 63;
const MAX_OUTPUT: usize = 6 * MAX_NODES + 1;

export fn create_binary_tree_from_inorder_preorder(values: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (values == null or length < 1) return -1;
    const input = values.?;
    if (input[0] < 0 or input[0] > MAX_NODES) return -1;
    const count: usize = @intCast(input[0]);
    if (length != 1 + 2 * count) return -1;
    for (0..count) |i| {
        const pre = input[1 + i];
        const inorder = input[1 + count + i];
        if (pre < -2147483648 or pre > 2147483647 or inorder < -2147483648 or inorder > 2147483647) return -1;
        for (0..i) |j| if (pre == input[1 + j] or inorder == input[1 + count + j]) return -1;
        var matches: usize = 0;
        for (0..count) |j| if (pre == input[1 + count + j]) { matches += 1; };
        if (matches != 1) return -1;
    }
    var left_child = [_]i32{-1} ** MAX_NODES;
    var right_child = [_]i32{-1} ** MAX_NODES;
    var task_pre: [MAX_NODES]usize = undefined;
    var task_in: [MAX_NODES]usize = undefined;
    var task_size: [MAX_NODES]usize = undefined;
    var task_count: usize = 0;
    if (count > 0) { task_pre[0] = 0; task_in[0] = 0; task_size[0] = count; task_count = 1; }
    while (task_count > 0) {
        task_count -= 1;
        const pre_start = task_pre[task_count];
        const in_start = task_in[task_count];
        const size = task_size[task_count];
        if (size == 0 or pre_start + size > count or in_start + size > count) return -1;
        var root_position: ?usize = null;
        for (in_start..in_start + size) |i| if (input[1 + i] == input[1 + count + pre_start]) { root_position = i; break; };
        if (root_position == null) return -1;
        const root_pos = root_position.?;
        const left_size = root_pos - in_start;
        const right_size = size - left_size - 1;
        if (left_size > 0) left_child[pre_start] = @intCast(pre_start + 1);
        if (right_size > 0) right_child[pre_start] = @intCast(pre_start + left_size + 1);
        if (right_size > 0) { task_pre[task_count] = pre_start + left_size + 1; task_in[task_count] = root_pos + 1; task_size[task_count] = right_size; task_count += 1; }
        if (left_size > 0) { task_pre[task_count] = pre_start + 1; task_in[task_count] = in_start; task_size[task_count] = left_size; task_count += 1; }
    }
    const required = 6 * count + 1;
    if (output == null or output_capacity < required) return -2;
    var encoded: [MAX_OUTPUT]u8 = undefined;
    var pending: [2 * MAX_NODES + 1]i32 = undefined;
    var top: usize = 1;
    pending[0] = if (count == 0) -1 else 0;
    var written: usize = 0;
    while (top > 0) {
        top -= 1;
        const node = pending[top];
        if (node < 0) { encoded[written] = 0; written += 1; }
        else {
            const index: usize = @intCast(node);
            const value: u32 = @bitCast(@as(i32, @intCast(input[1 + index])));
            encoded[written] = 1; written += 1;
            for (0..4) |byte| { encoded[written] = @truncate(value >> @intCast(8 * byte)); written += 1; }
            pending[top] = right_child[index]; top += 1;
            pending[top] = left_child[index]; top += 1;
        }
    }
    @memcpy(output.?[0..written], encoded[0..written]);
    return @intCast(count);
}
