export fn schorr_waite_graph_marking(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 4 or length > 66) return -1;
    const input = input_opt.?;
    const node_count_value = input[0];
    const root = input[1];
    if (node_count_value < 1 or node_count_value > 32) return -1;
    const node_count: usize = @intCast(node_count_value);
    if (length != 2 + 2 * node_count or root < 0 or root >= node_count_value) return -1;

    var left = [_]i64{0} ** 32;
    var right = [_]i64{0} ** 32;
    var marked = [_]bool{false} ** 32;
    var phase = [_]bool{false} ** 32;
    for (0..node_count) |node| {
        const left_child = input[2 + 2 * node];
        const right_child = input[3 + 2 * node];
        if (left_child < -1 or left_child >= node_count_value
            or right_child < -1 or right_child >= node_count_value) return -1;
        left[node] = left_child;
        right[node] = right_child;
    }

    var parent: i64 = -1;
    var current = root;
    var temporary: i64 = 0;
    while (parent != -1 or (current != -1 and !marked[@intCast(current)])) {
        if (current == -1 or marked[@intCast(current)]) {
            const frame: usize = @intCast(parent);
            if (phase[frame]) {
                temporary = current;
                current = parent;
                parent = right[frame];
                right[frame] = temporary;
            } else {
                temporary = current;
                current = right[frame];
                right[frame] = left[frame];
                left[frame] = temporary;
                phase[frame] = true;
            }
        } else {
            temporary = parent;
            parent = current;
            current = left[@intCast(parent)];
            left[@intCast(parent)] = temporary;
            marked[@intCast(parent)] = true;
            phase[@intCast(parent)] = false;
        }
    }

    var reachable: i64 = 0;
    for (0..node_count) |node| {
        if (marked[node]) reachable |= @as(i64, 1) << @intCast(node);
    }
    return reachable;
}
