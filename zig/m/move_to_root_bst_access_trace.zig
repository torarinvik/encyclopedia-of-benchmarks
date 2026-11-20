pub export fn move_to_root_bst_access_trace(values: ?[*]const i64, length: usize) callconv(.c) i64 {
    const input = values orelse return -1;
    if (length < 2 or length > 51) return -1;

    const initial_count_raw = input[0];
    if (initial_count_raw < 0 or initial_count_raw > 16) return -1;
    const initial_count: usize = @intCast(initial_count_raw);
    const query_count_index = 1 + initial_count;
    if (length < query_count_index + 1) return -1;

    const access_count_raw = input[query_count_index];
    if (access_count_raw < 0 or access_count_raw > 32) return -1;
    const access_count: usize = @intCast(access_count_raw);
    if (length != query_count_index + 1 + access_count) return -1;

    var keys = [_]i64{0} ** 16;
    var left = [_]i32{-1} ** 16;
    var right = [_]i32{-1} ** 16;
    var parent = [_]i32{-1} ** 16;

    for (0..initial_count) |index| {
        const key = input[1 + index];
        if (key < -100 or key > 100) return -1;
        for (0..index) |earlier| {
            if (input[1 + earlier] == key) return -1;
        }
        keys[index] = key;
    }
    for (0..access_count) |query| {
        const key = input[query_count_index + 1 + query];
        if (key < -100 or key > 100) return -1;
    }

    var root: i32 = -1;
    for (0..initial_count) |node_index| {
        const node: i32 = @intCast(node_index);
        if (root == -1) {
            root = node;
            continue;
        }
        var current = root;
        while (true) {
            const current_index: usize = @intCast(current);
            if (keys[node_index] < keys[current_index]) {
                if (left[current_index] == -1) {
                    left[current_index] = node;
                    parent[node_index] = current;
                    break;
                }
                current = left[current_index];
            } else {
                if (right[current_index] == -1) {
                    right[current_index] = node;
                    parent[node_index] = current;
                    break;
                }
                current = right[current_index];
            }
        }
    }

    var score: i64 = 0;
    for (1..(access_count + 1)) |query_number| {
        const key = input[query_count_index + query_number];
        var node = root;
        var comparisons: i64 = 0;
        while (node != -1) {
            const node_index: usize = @intCast(node);
            comparisons += 1;
            if (key == keys[node_index]) break;
            node = if (key < keys[node_index]) left[node_index] else right[node_index];
        }

        while (node != -1 and parent[@intCast(node)] != -1) {
            const node_index: usize = @intCast(node);
            const old_parent = parent[node_index];
            const parent_index: usize = @intCast(old_parent);
            const grandparent = parent[parent_index];
            if (left[parent_index] == node) {
                const middle = right[node_index];
                right[node_index] = old_parent;
                left[parent_index] = middle;
                if (middle != -1) parent[@intCast(middle)] = old_parent;
            } else {
                const middle = left[node_index];
                left[node_index] = old_parent;
                right[parent_index] = middle;
                if (middle != -1) parent[@intCast(middle)] = old_parent;
            }
            parent[parent_index] = node;
            parent[node_index] = grandparent;
            if (grandparent == -1) {
                root = node;
            } else {
                const grandparent_index: usize = @intCast(grandparent);
                if (left[grandparent_index] == old_parent) {
                    left[grandparent_index] = node;
                } else {
                    right[grandparent_index] = node;
                }
            }
        }
        score += @as(i64, @intCast(query_number)) * comparisons;
    }
    return score;
}
